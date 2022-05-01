pragma solidity ^0.8.0;
import {console} from "forge-std/console.sol";
import "../../src/GIGADRIP20.sol";

contract MockGIGADRIP20 is GIGADRIP20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _emissionRatePerBlock
    ) GIGADRIP20(_name, _symbol, _decimals, _emissionRatePerBlock) {}

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function startDripping(address addr, uint256 multiplier) external virtual {
        _startDripping(addr, multiplier);
    }

    function stopDripping(address addr, uint256 multiplier) external virtual {
        _stopDripping(addr, multiplier);
    }

    function burn(address from, uint256 value) external virtual {
        _burn(from, value);
    }
}
