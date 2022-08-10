// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GovernanceToken.sol";
import "../BustadToken.sol";

contract ReleaseFund {
    uint256 public govTokenSnapshopId;
    uint256 public releasedAmount;
    uint256 public refundAllowedAt;
    uint256 public withdrawAllowedAt;
    address public parentTreasury;

    bool public isInitialized = false;

    GovernanceToken public govToken;
    BustadToken public bustadToken;

    mapping(address => bool) public hasWithdrawnFunds;

    event FundWithdrawn(address receiver, uint256 amount);
    event RefundRemaining(uint256 remainingAmount);
    event ReleaseFundInitialised(
        uint256 amount,
        uint256 snapshotId,
        uint256 refundAllowedAt,
        uint256 withdrawAllowedAt
    );

    function init(
        uint256 _govTokenSnapshopId,
        GovernanceToken _govToken,
        BustadToken _bustadToken,
        uint256 _refundAllowedAt,
        uint256 _withdrawAllowedAt
    ) external {
        require(isInitialized == false, "Has already been initialized.");

        isInitialized = true;

        releasedAmount = _bustadToken.balanceOf(address(this));
        govTokenSnapshopId = _govTokenSnapshopId;
        govToken = _govToken;
        bustadToken = _bustadToken;
        refundAllowedAt = _refundAllowedAt;
        withdrawAllowedAt = _withdrawAllowedAt;
        parentTreasury = msg.sender;

        emit ReleaseFundInitialised(
            releasedAmount,
            govTokenSnapshopId,
            refundAllowedAt,
            withdrawAllowedAt
        );
    }

    function withdraw() external {
        address receiver = msg.sender;

        require(withdrawAllowedAt < block.number, "Withdraw not allowed yet");
        require(
            govToken.balanceOfAt(receiver, govTokenSnapshopId) > 0,
            "User cannot withdraw any funds"
        );
        require(
            hasWithdrawnFunds[receiver] == false,
            "Has already withdrawn funds"
        );
        require(bustadToken.balanceOf(address(this)) > 0, "Fund balance is 0");

        uint256 shareAmount = shareAmountFor(receiver);

        require(
            bustadToken.balanceOf(address(this)) > shareAmount,
            "amount surpasses fund balance"
        );

        hasWithdrawnFunds[receiver] = true;

        bustadToken.transfer(receiver, shareAmount);
        emit FundWithdrawn(receiver, shareAmount);
    }

    function refundRemaining() external {
        require(block.number > refundAllowedAt, "Refund time not reached");
        require(bustadToken.balanceOf(address(this)) > 0, "Nothing to refund");

        uint256 remainingBalance = bustadToken.balanceOf(address(this));
        bustadToken.transfer(parentTreasury, remainingBalance);

        emit RefundRemaining(remainingBalance);
    }

    function checkHasWithdrawnFund(address account)
        external
        view
        returns (bool)
    {
        return hasWithdrawnFunds[account];
    }

    function remainingAmount() external view returns (uint256) {
        return govToken.balanceOf(address(this));
    }

    function shareAmountFor(address account) public view returns (uint256) {
        uint256 receiverGovBalance = govToken.balanceOfAt(
            account,
            govTokenSnapshopId
        );
        uint256 totalGovSupply = govToken.totalSupplyAt(govTokenSnapshopId);

        return _calculateReleaseShareAmount(receiverGovBalance, totalGovSupply);
    }

    function _calculateReleaseShareAmount(uint256 balance, uint256 totalSupply)
        private
        view
        returns (uint256)
    {
        uint256 share = (balance * 1e18) / totalSupply;
        return (share * releasedAmount) / 1e18;
    }
}