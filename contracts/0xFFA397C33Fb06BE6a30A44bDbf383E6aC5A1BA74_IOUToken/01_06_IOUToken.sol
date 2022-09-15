// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IOUToken is ERC20, Ownable {
    uint8 private _decimal;
    uint256 public immutable supplyCap;

    constructor(string memory name_, string memory symbol_, uint8 decimal_, address owner_, uint256 supplyCap_) ERC20(name_, symbol_) {
        _decimal = decimal_;
        _transferOwnership(owner_);
        supplyCap = supplyCap_ * (10 ** decimal_);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
        require(totalSupply() <= supplyCap, "Excess Supply Cap");
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}