// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DABotCommon.sol";

interface IDABotFundManagerModuleEvent {
    event Award(AwardingDetail[] pnl, uint[] totalStakes, uint[] certTokenValues);
    event AwardCompound(address indexed asset, uint amount, uint mode);
    event AwardBenefitciary(address indexed benefitciary, address indexed portfolioAsset, address indexed awardedAsset, uint amount, uint share, uint totalShare);
    event AddBenefitciary(address indexed benefitciary);
}

interface IDABotFundManagerModule is IDABotFundManagerModuleEvent {
    
    /**
    @dev Gets detailed information about benefitciaries of staking rewards.
     */
    function benefitciaries() external view returns(BenefitciaryInfo[] memory result);

    /**
    @dev Replaces the current bot's benefitciaries with its bot template's
    @notice Only bot owner can call.
     */
    function resetBenefitciaries() external; 

    /**
    @dev Add new benefitciary
    @param benefitciary - the benefitciary address. Should not be added before.
     */
    function addBenefitciary(address benefitciary) external;

    /**
     @dev Add profit/loss for each asset in the portfolio.
     @param pnl - list of AwardingDetail data.
     */
    function award(AwardingDetail[] calldata pnl) external;

    /**
    @dev Checks the pending stake rewarod of a given account for specified assets.
    @param account - the account to check.
    @param assets - the list of assets to check for reward. 
        If empty list is passed, all assets in the portfolio are checked.
    @param subVaults - the list of sub-vaults to check. 
        If empty list is passed, all sub vaults (i.e., [0, 1, 2]) are checked.
     */
    function pendingStakeReward(address account, address[] calldata assets, 
        bytes calldata subVaults) external view returns(StakingReward[] memory);

    /**
    @dev Checks the pending governance rewardsof a given account.
    @param account - the account to check.
    @param subVaults - the lst oof sub-vaults to check. 
        if empty list is passed, all sub vaults (i.e., [0, 1]) are checked.
     */
    function pendingGovernReward(address account, bytes calldata subVaults) external view returns(uint);

    /**
    @dev Withdraws tokens that have been transfered to the bot contract by mistake.
    All balance of the specified token in the bot will be transfered to `to` address.
    @param asset - the IERC20 token contract.
    @param to - the recipient address
     */
    function withdrawToken(address asset, address to) external;
}