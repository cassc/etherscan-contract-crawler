// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketLiquidityRewards {
    struct RewardAllocation {
        address allocator;
        address rewardTokenAddress;
        uint256 rewardTokenAmount;
        uint256 marketId;
        //requirements for loan
        address requiredPrincipalTokenAddress; //0 for any
        address requiredCollateralTokenAddress; //0 for any  -- could be an enumerable set?
        uint256 minimumCollateralPerPrincipalAmount;
        uint256 rewardPerLoanPrincipalAmount;
        uint32 bidStartTimeMin;
        uint32 bidStartTimeMax;
        AllocationStrategy allocationStrategy;
    }

    enum AllocationStrategy {
        BORROWER,
        LENDER
    }

    function allocateRewards(RewardAllocation calldata _allocation)
        external
        returns (uint256 allocationId_);

    function increaseAllocationAmount(
        uint256 _allocationId,
        uint256 _tokenAmount
    ) external;

    function deallocateRewards(uint256 _allocationId, uint256 _amount) external;

    function claimRewards(uint256 _allocationId, uint256 _bidId) external;

    function rewardClaimedForBid(uint256 _bidId, uint256 _allocationId)
        external
        view
        returns (bool);

    function initialize() external;
}