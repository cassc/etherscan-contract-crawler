// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPrismaVault {
    struct InitialAllowance {
        address receiver;
        uint256 amount;
    }

    event BoostCalculatorSet(address boostCalculator);
    event BoostDelegationSet(address indexed boostDelegate, bool isEnabled, uint256 feePct, address callback);
    event EmissionScheduleSet(address emissionScheduler);
    event IncreasedAllocation(address indexed receiver, uint256 increasedAmount);
    event NewReceiverRegistered(address receiver, uint256 id);
    event ReceiverIsActiveStatusModified(uint256 indexed id, bool isActive);
    event UnallocatedSupplyIncreased(uint256 increasedAmount, uint256 unallocatedTotal);
    event UnallocatedSupplyReduced(uint256 reducedAmount, uint256 unallocatedTotal);

    function allocateNewEmissions(uint256 id) external returns (uint256);

    function batchClaimRewards(
        address receiver,
        address boostDelegate,
        address[] calldata rewardContracts,
        uint256 maxFeePct
    ) external returns (bool);

    function increaseUnallocatedSupply(uint256 amount) external returns (bool);

    function registerReceiver(address receiver, uint256 count) external returns (bool);

    function setBoostCalculator(address _boostCalculator) external returns (bool);

    function setBoostDelegationParams(bool isEnabled, uint256 feePct, address callback) external returns (bool);

    function setEmissionSchedule(address _emissionSchedule) external returns (bool);

    function setInitialParameters(
        address _emissionSchedule,
        address _boostCalculator,
        uint256 totalSupply,
        uint64 initialLockWeeks,
        uint128[] calldata _fixedInitialAmounts,
        InitialAllowance[] calldata initialAllowances
    ) external;

    function setReceiverIsActive(uint256 id, bool isActive) external returns (bool);

    function transferAllocatedTokens(address claimant, address receiver, uint256 amount) external returns (bool);

    function transferTokens(address token, address receiver, uint256 amount) external returns (bool);

    function PRISMA_CORE() external view returns (address);

    function allocated(address) external view returns (uint256);

    function boostCalculator() external view returns (address);

    function boostDelegation(address) external view returns (bool isEnabled, uint16 feePct, address callback);

    function claimableRewardAfterBoost(
        address account,
        address receiver,
        address boostDelegate,
        address rewardContract
    ) external view returns (uint256 adjustedAmount, uint256 feeToDelegate);

    function emissionSchedule() external view returns (address);

    function getClaimableWithBoost(address claimant) external view returns (uint256 maxBoosted, uint256 boosted);

    function getWeek() external view returns (uint256 week);

    function guardian() external view returns (address);

    function idToReceiver(uint256) external view returns (address account, bool isActive);

    function lockWeeks() external view returns (uint64);

    function locker() external view returns (address);

    function owner() external view returns (address);

    function claimableBoostDelegationFees(address claimant) external view returns (uint256 amount);

    function prismaToken() external view returns (address);

    function receiverUpdatedWeek(uint256) external view returns (uint16);

    function totalUpdateWeek() external view returns (uint64);

    function unallocatedTotal() external view returns (uint128);

    function voter() external view returns (address);

    function weeklyEmissions(uint256) external view returns (uint128);
}