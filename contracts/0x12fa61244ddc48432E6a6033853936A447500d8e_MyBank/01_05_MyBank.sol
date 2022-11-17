//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MyBank {
    event Payout(address payee, uint256 amount);

    address private owner;
    IERC20 token;

    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
    }

    function payout(address to, uint256 amount) external payable {
        require(owner == msg.sender, "Only allowed for owner");

        uint256 usdtBalance = this.tokenBalance();
        require(usdtBalance >= amount, "Not enough tokens for payout");

        token.transfer(to, amount);

        emit Payout(to, amount);
    }

    // Allow you to show how many tokens owns this smart contract
    function tokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}