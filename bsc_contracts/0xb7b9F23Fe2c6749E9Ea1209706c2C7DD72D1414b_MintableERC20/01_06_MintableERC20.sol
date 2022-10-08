//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MintableERC20 is ERC20, Ownable {
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 mintAmount
    ) ERC20(name_, symbol_) {
        _mint(msg.sender, mintAmount);
        _decimals = decimals_;
    }

    function mint(address account, uint256 mintAmount) external onlyOwner {
        _mint(account, mintAmount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}