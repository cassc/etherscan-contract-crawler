// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeputyDawgsToken is ERC20, Ownable {
    uint256 private constant TOTAL_SUPPLY = 313 * 10**9 * 10**18; //Total supply of 313 billion tokens
    string private constant TOKEN_NAME = "Deputy Dawgs";
    string private constant TOKEN_SYMBOL = "DDawgs";

    address[] private teamWallets;
    uint256[] private teamWalletsPercentages;

    constructor() ERC20(TOKEN_NAME, TOKEN_SYMBOL) {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal override {
        require(totalSupply() + amount <= TOTAL_SUPPLY, "Exceeds total supply");
        super._mint(account, amount);
    }

    function setTeamWallets(address[] memory wallets, uint256[] memory percentages) external onlyOwner {
        require(wallets.length == percentages.length, "Invalid input");
        teamWallets = wallets;
        teamWalletsPercentages = percentages;
    }

    function distributeTokensToTeamWallets() external onlyOwner {
        require(teamWallets.length > 0, "Team wallets not set");

        uint256 totalTokens = balanceOf(msg.sender);
        require(totalTokens > 0, "Insufficient balance");

        for (uint256 i = 0; i < teamWallets.length; i ++) {
            address wallet = teamWallets[i];
            uint256 percentage = teamWalletsPercentages[i];
            uint256 tokensToTransfer = (totalTokens * percentage) / 100;
            _transfer(msg.sender, wallet, tokensToTransfer);
        }
    }
}