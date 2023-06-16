// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ISale.sol';

interface IReferralSale is ISale {
    struct RefState {
        // One decimal, so 2.5% = 25
        uint16 percent;
        uint256 totalCommission;
        uint256 totalWithdrawn;
        uint16 totalAffiliatesN;
        uint16 totalWithdrawnN;
        mapping(address => uint16) affiliatePurchasesN;
        mapping(address => uint256) affiliateCommission;
        mapping(address => uint256) affiliateWithdrawn;
        // Can set different affiliate percent per account
        mapping(address => uint16) affiliatePercent;
    }

    struct RefStateView {
        uint256 percent;
        uint256 totalCommission;
        uint256 totalWithdrawn;
        uint256 totalAffiliatesN;
        uint256 totalWithdrawnN;
        uint256 affiliateReferralsN;
        uint256 affiliateCommission;
        uint256 affiliateWithdrawn;
    }
    
    event RefCommissionPercentChanged(uint16 percent);
    event RefCommissionWithdrawn(address indexed account, uint256 amount);
    event AffiliatePercentChanged(address indexed account, uint16 percent);

    function getReferralState(address account) external view returns (uint16, uint256, uint256, uint16, uint16, uint16, uint256, uint256);

    function withdrawReferralCommission() external;
    
    function setAffiliatePercent(address account, uint16 percent) external;
}