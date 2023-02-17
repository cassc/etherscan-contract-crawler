// contracts/TerareumV2.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract TerareumV2 is Context, Ownable, ERC20 {
    uint8 private immutable DECIMALS;
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address mintTo_,
        uint256 supply_
    ) ERC20(name_, symbol_) {
        require(bytes(name_).length > 0, "TerareumV2: name is required");
        require(bytes(symbol_).length > 0, "TerareumV2: symbol is required");
        require(decimals_ > 0, "TerareumV2: decimals is required");
        DECIMALS = decimals_;
        require(mintTo_ != address(0), "TerareumV2: mintTo is required");
        require(supply_ > 0, "TerareumV2: supply is required");
        _mint(mintTo_, supply_);
    }
    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }
}