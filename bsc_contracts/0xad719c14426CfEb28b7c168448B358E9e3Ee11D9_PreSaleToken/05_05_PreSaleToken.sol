// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PreSaleToken is ERC20 {
    mapping(address => string) public _wallets;
    address[] public investors;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function setWallet(string calldata walletAddress_) external {
        _wallets[msg.sender] = walletAddress_;
        investors.push(msg.sender);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}