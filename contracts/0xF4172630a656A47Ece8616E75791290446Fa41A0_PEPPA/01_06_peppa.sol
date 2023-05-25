// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract PEPPA is Context, Ownable, ERC20 {
    uint8 private immutable DECIMALS;
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address mintTo_,
        uint256 supply_
    ) ERC20(name_, symbol_) {
        require(bytes(name_).length > 0, "PEPPA: name is required");
        require(bytes(symbol_).length > 0, "PEPPA: symbol is required");
        require(decimals_ > 0, "PEPPA: decimals is required");
        DECIMALS = decimals_;
        require(mintTo_ != address(0), "PEPPA: mintTo is required");
        require(supply_ > 0, "PEPPA: supply is required");
        _mint(mintTo_, supply_ * 10 ** decimals_);
    }
    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }
}