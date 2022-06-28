// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@author 0xBeans
///@notice This is a beefed up ERC20 implementation of DRIP20 that supports emission multipliers.
///@notice Multipliers are useful when certain users should accrue larger emissions. For example,
///@notice if an NFT drips 10 tokens per block to a user, and the user has 3 NFTs, then the user
///@notice should accrue 3 times as many tokens per block. This user would have a multiplier of 3.
///@notice shout out to solmate (@t11s) for the slim and efficient ERC20 implementation!
///@notice shout out to superfluid and UBI for the dripping inspiration!
abstract contract GIGADRIP20 {
    /*==============================================================
    ==                            ERRORS                          ==
    ==============================================================*/

    error UserNotAccruing();
    error ERC20_TransferToZeroAddress();

    /*==============================================================
    ==                            EVENTS                          ==
    ==============================================================*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*==============================================================
    ==                      METADATA STORAGE                      ==
    ==============================================================*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*==============================================================
    ==                       ERC20 STORAGE                        ==
    ==============================================================*/

    mapping(address => mapping(address => uint256)) public allowance;

    /*==============================================================
    ==                        DRIP STORAGE                        ==
    ==============================================================*/

    struct Accruer {
        uint256 balance;
        uint128 accrualStartBlock;
        uint128 multiplier;
    }

    // immutable token emission rate per block
    uint256 public immutable emissionRatePerBlock;

    // wallets currently getting dripped tokens
    mapping(address => Accruer) private _accruers;

    // these are all for calculating totalSupply()
    uint256 private _currAccrued;
    uint128 private _currEmissionBlockNum;
    uint128 private _currEmissionMultiple;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _emissionRatePerBlock
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        emissionRatePerBlock = _emissionRatePerBlock;
    }

    /*==============================================================
    ==                        ERC20 IMPL                          ==
    ==============================================================*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender];

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        _transfer(from, to, amount);

        return true;
    }

    function balanceOf(address addr) public view returns (uint256) {
        Accruer memory accruer = _accruers[addr];

        if (accruer.accrualStartBlock == 0) {
            return accruer.balance;
        }

        return
            ((block.number - accruer.accrualStartBlock) *
                emissionRatePerBlock) *
            accruer.multiplier +
            accruer.balance;
    }

    function totalSupply() public view returns (uint256) {
        return
            _currAccrued +
            (block.number - _currEmissionBlockNum) *
            emissionRatePerBlock *
            _currEmissionMultiple;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (to == address(0)) revert ERC20_TransferToZeroAddress();

        Accruer storage fromAccruer = _accruers[from];
        Accruer storage toAccruer = _accruers[to];

        fromAccruer.balance = balanceOf(from) - amount;

        unchecked {
            toAccruer.balance += amount;
        }

        if (fromAccruer.accrualStartBlock != 0) {
            fromAccruer.accrualStartBlock = uint128(block.number);
        }

        emit Transfer(from, to, amount);
    }

    /*==============================================================
    ==                        DRIP LOGIC                          ==
    ==============================================================*/

    /**
     * @dev Add an address to start dripping tokens to.
     * @dev We need to update _currAccrued whenever we add a new dripper or INCREASE a dripper multiplier to properly update totalSupply()
     * @dev IMPORTANT: Everytime you call this with an addr already getting dripped to, it will INCREASE the multiplier
     * @param addr address to drip to
     * @param multiplier used to increase token drip. ie if 1 NFT drips 10 tokens per block and this address has 3 NFTs,
     * the user would need to get dripped 30 tokens per block - multipler would multiply emissions by 3
     */
    function _startDripping(address addr, uint128 multiplier) internal virtual {
        Accruer storage accruer = _accruers[addr];

        // need to update the balance if wallet was already accruing
        if (accruer.accrualStartBlock != 0) {
            accruer.balance = balanceOf(addr);
        } else {
            // emit Transfer event when new address starts dripping
            emit Transfer(address(0), addr, 0);
        }

        _currAccrued = totalSupply();
        _currEmissionBlockNum = uint128(block.number);
        accruer.accrualStartBlock = uint128(block.number);

        // should not overflow unless you have >2**256-1 items...
        unchecked {
            _currEmissionMultiple += multiplier;
            accruer.multiplier += multiplier;
        }
    }

    /**
     * @dev Add an address to stop dripping tokens to.
     * @dev We need to update _currAccrued whenever we remove a dripper or DECREASE a dripper multiplier to properly update totalSupply()
     * @dev IMPORTANT: Everytime you call this with an addr already getting dripped to, it will DECREASE the multiplier
     * @dev IMPORTANT: Decrease the multiplier to 0 to completely stop the address from getting dripped to
     * @param addr address to stop dripping to
     * @param multiplier used to decrease token drip. ie if addr has a multiplier of 3 already, passing in a value of 1 would decrease
     * the multiplier to 2
     */
    function _stopDripping(address addr, uint128 multiplier) internal virtual {
        Accruer storage accruer = _accruers[addr];

        // should I check for 0 multiplier too
        if (accruer.accrualStartBlock == 0) revert UserNotAccruing();

        accruer.balance = balanceOf(addr);
        _currAccrued = totalSupply();
        _currEmissionBlockNum = uint128(block.number);

        // will revert if underflow occurs
        _currEmissionMultiple -= multiplier;
        accruer.multiplier -= multiplier;

        if (accruer.multiplier == 0) {
            accruer.accrualStartBlock = 0;
        } else {
            accruer.accrualStartBlock = uint128(block.number);
        }
    }

    /*==============================================================
    ==                         MINT/BURN                          ==
    ==============================================================*/

    function _mint(address to, uint256 amount) internal virtual {
        Accruer storage accruer = _accruers[to];

        unchecked {
            _currAccrued += amount;
            accruer.balance += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        Accruer storage accruer = _accruers[from];

        // have to update supply before burning
        _currAccrued = totalSupply();
        _currEmissionBlockNum = uint128(block.number);

        accruer.balance = balanceOf(from) - amount;

        // Cannot underflow because amount can
        // never be greater than the totalSupply()
        unchecked {
            _currAccrued -= amount;
        }

        // update accruers block number if user was accruing
        if (accruer.accrualStartBlock != 0) {
            accruer.accrualStartBlock = uint128(block.number);
        }

        emit Transfer(from, address(0), amount);
    }
}
