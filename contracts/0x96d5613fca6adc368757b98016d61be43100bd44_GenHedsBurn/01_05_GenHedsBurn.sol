// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "solmate/utils/ReentrancyGuard.sol";
import "./test/lib/CrowdfundWithPodiumEditionsLogic.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

error ZeroFunds();
error InsufficientContractBalance();
error InsufficientUserBalance();
error FailedTransfer();

contract GenHedsBurn is ReentrancyGuard, Ownable {
    CrowdfundWithPodiumEditionsLogic public immutable genHeds;
    uint256 public immutable totalSupply = 26666666666666666666666; // 26666.666..., totalSupply of GenHeds

    /// @notice MUST PASS 0x38dA10D8a9Fa9C98b27bc03A6f6999bb35d17375 as _genHeds param
    /// @param _genHeds address of the GenHeds contract
    constructor(address _genHeds) {
        genHeds = CrowdfundWithPodiumEditionsLogic(_genHeds);
    }

    /// @notice Calculates amount of ETH to redeem given amount of tokens
    /// @param numTokens number of tokens to check for ETH redemption
    function amountRedeemable(uint256 numTokens) public pure returns (uint256) {
        return numTokens * 20 ether / totalSupply; 
    }

    /// @notice Redeem tokens for ETH
    /// @param numTokens number of tokens to redeem
    function redeem(uint256 numTokens) external nonReentrant {
        uint256 amount = amountRedeemable(numTokens);
        uint256 balance = address(this).balance;

        if (balance == 0) revert ZeroFunds();
        if (genHeds.balanceOf(msg.sender) < numTokens) revert InsufficientUserBalance();
        if (balance < amount) revert InsufficientContractBalance();

        genHeds.transferFrom(msg.sender, address(0), numTokens);
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert FailedTransfer();
    }

    /// @notice Withdraw contract balance - must be contract owner
    /// NOTE: This will disable redeem functionality
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) revert FailedTransfer();
    }

    fallback() external payable {}
    receive() external payable {}
}