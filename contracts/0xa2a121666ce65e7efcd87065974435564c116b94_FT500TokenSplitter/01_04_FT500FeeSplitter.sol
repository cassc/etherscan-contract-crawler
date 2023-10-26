// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FT500TokenSplitter is Ownable {
    address public teamWallet1;
    address public teamWallet2;
    address public teamWallet3;
    address public teamWallet4;
    IERC20 public token;

    constructor() {
        teamWallet1 = 0xB006fCDAe73736aEe3f14B9a3645cf24aFA781f0;
        teamWallet2 = 0xE4d03628F8697C1114eeDa05069e6B1CA34d6fdc;
        teamWallet3 = 0x2dF22069f3eaBA355bE785831140360AE5303fe4;
        teamWallet4 = 0x04f2Cbcb7cd992d2166C3597403D2B59CE7612B5;
    }
    receive() external payable {}

    function updateteamWallet1(address newWallet) external onlyOwner {
        teamWallet1 = newWallet;
    }

    function updateMarketingWallet(address newWallet) external onlyOwner {
        teamWallet2 = newWallet;
    }

    function updateOperationalWallet(address newWallet) external onlyOwner {
        teamWallet3 = newWallet;
    }

    function updateteamWallet4(address newWallet) external onlyOwner {
        teamWallet4 = newWallet;
    }

    function updateTokenAddress(address newTokenAddress) external onlyOwner {
        token = IERC20(newTokenAddress);
    }

    function splitTokens() external {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No balance to split");

        uint256 share = balance / 4;

        require(token.transfer(teamWallet1, share), "Transfer failed");
        require(token.transfer(teamWallet2, share), "Transfer failed");
        require(token.transfer(teamWallet3, share), "Transfer failed");
        require(token.transfer(teamWallet4, share), "Transfer failed");
    }

    function splitEth() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether balance to split");

        uint256 share = balance / 4;

        payable(teamWallet1).transfer(share);
        payable(teamWallet2).transfer(share);
        payable(teamWallet3).transfer(share);
        payable(teamWallet4).transfer(share);
    }

    function splitOtherTokens(address tokenAddress) external {
        IERC20 _token = IERC20(tokenAddress);
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "No balance to split");

        uint256 share = balance / 4;

        require(_token.transfer(teamWallet1, share), "Transfer failed");
        require(_token.transfer(teamWallet2, share), "Transfer failed");
        require(_token.transfer(teamWallet3, share), "Transfer failed");
        require(_token.transfer(teamWallet4, share), "Transfer failed");
    }
}