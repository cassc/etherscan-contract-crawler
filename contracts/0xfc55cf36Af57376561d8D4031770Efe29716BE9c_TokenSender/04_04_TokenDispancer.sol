// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
* @title Token sender
* @author R.Mamedov
*/

contract TokenSender is Ownable {
    IERC20 public token;

    constructor(IERC20 _token) {
        token = _token;
    }

    function send(address[] calldata accounts, uint[] calldata amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Invalid arrays length");
        for (uint i = 0; i < accounts.length; i++) {
            token.transfer(accounts[i], amounts[i]);
        }
    }

    function withdraw() external onlyOwner {
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}