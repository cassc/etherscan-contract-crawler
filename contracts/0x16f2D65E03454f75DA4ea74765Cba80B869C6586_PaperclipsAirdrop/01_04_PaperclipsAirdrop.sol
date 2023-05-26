// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaperclipsAirdrop is Ownable {
    mapping(address => uint256) public balances;
    IERC20 public token;

    constructor(IERC20 _token) {
        token = _token;
    }

    function assign(address[] calldata recipients, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(
            recipients.length == amounts.length,
            "Array lengths do not match"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            balances[recipients[i]] += amounts[i];
        }
    }

    function claim() external {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Nothing to claim");
        require(
            token.balanceOf(address(this)) >= amount,
            "Not enough tokens left"
        );

        balances[msg.sender] = 0;
        require(token.transfer(msg.sender, amount * 10**18), "Transfer failed");
    }
}