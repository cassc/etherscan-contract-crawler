// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces
import "./interfaces/IFurBetToken.sol";
import "./interfaces/ILPStakingV1.sol";
import "./interfaces/ISwapV2.sol";
import "./interfaces/ISwapFurbet.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title FurMax
 * @notice This is the contract that handles FurMax earnings.
 */

/// @custom:security-contact [email protected]
contract FurMax is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    /**
     * External contracts.
     */
    IToken private _fur;
    IFurBetToken private _furbet;
    ILPStakingV1 private _furpool;
    ISwapV2 private _swap;
    ISwapFurbet private _swapFurbet;
    IERC20 private _usdc;
    IVault private _vault;

    /**
     * Stats.
     */
    uint256 public totalParticipants;
    uint256 public totalFurbotPendingInvestment;
    uint256 public totalFurbotInvestment;
    uint256 public totalFurbotDividends;
    uint256 public totalFurpoolPendingInvestment;
    uint256 public totalFurpoolInvestment;
    uint256 public totalFurpoolDividends;

    /**
     * Mappings.
     */
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isDistributor;
    mapping(address => bool) public isFurmax;
    mapping(address => bool) public acceptedLoanTerms;
    mapping(address => uint256) public furbetPercent;
    mapping(address => uint256) public furbotPercent;
    mapping(address => uint256) public furpoolPercent;
    mapping(address => uint256) public furbotInvestment;
    mapping(address => uint256) public furbotDividendsClaimed;
    mapping(address => uint256) public furpoolInvestment;
    mapping(address => uint256) public furpoolDividendsClaimed;
    mapping(address => uint256) public walletId;

    uint256 private _walletIdTracker;

    mapping(address => bool) public refundClaimed;
    uint256 public totalRefunded;

    /**
     * Available refund.
     * @param participant_ Participant address.
     * @return uint256 Amount of USDC available for refund.
     */
    function availableRefund(address participant_) public view returns (uint256)
    {
        if(refundClaimed[participant_] == true) return 0;
        uint256 _contractBalance_ = _usdc.balanceOf(address(this));
        uint256 _totalInvestment_ = totalFurbotPendingInvestment + totalFurbotInvestment + totalFurpoolPendingInvestment + totalFurpoolInvestment;
        uint256 _participantInvestment_ = furbotInvestment[participant_] + furpoolInvestment[participant_];
        if(_participantInvestment_ == 0) return 0;
        return (_contractBalance_ + totalRefunded) / (_totalInvestment_ / _participantInvestment_);
    }

    /**
     * Claim refund.
     */
    function claimRefund() external
    {
        require(refundClaimed[msg.sender] == false, "FurMax: Refund already claimed.");
        uint256 _refund_ = availableRefund(msg.sender);
        require(_refund_ > 0, "FurMax: No refund available.");
        refundClaimed[msg.sender] = true;
        totalRefunded += _refund_;
        _usdc.transfer(msg.sender, _refund_);
    }

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    function unstake() external onlyOwner
    {
        _furpool.unstake();
    }

    /**
     * Withdraw all.
     */
    function withdrawAll() external onlyOwner
    {
        uint256 _amount_ = _usdc.balanceOf(address(this));
        _usdc.transfer(msg.sender, _amount_);
    }
}