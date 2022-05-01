// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DRIP20.sol";

contract Test20 is DRIP20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _emissionRatePerBlock
    ) DRIP20(_name, _symbol, _decimals, _emissionRatePerBlock) {}

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function startDripping(address addr) external virtual {
        _startDripping(addr);
    }

    function stopDripping(address addr) external virtual {
        _stopDripping(addr);
    }

    function burn(address from, uint256 value) external virtual {
        _burn(from, value);
    }
}
