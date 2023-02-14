// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./IStakePool.sol";

interface IStake {
    struct PoolModel{
        bool isHidden;
        uint256 fixedFee;
        uint16 percentFee;
    }
    struct Fee{
        uint256 fixedFee;
        uint16 percentFee;
    }
    function pools(uint256) external view returns (address);
    function poolIndex(address) external view returns (uint256);
    function poolModel(address) external view returns (
        bool isHidden,
        uint256 fixedFee,
        uint16 percentFee
    );
    function fee() external view returns (
        uint256 fixedFee,
        uint16 percentFee
    );
    function poolTemplate() external view returns (address);
    function createPool(
        string memory name_,
        string memory symbol_,
        IStakePool.StakeModel memory _stakeModel,
        address _rewardToken,
        address _stakeToken,
        uint256 hardCap
    ) external payable;
    function totalPools() external view returns (uint256);
    function updateFee(Fee memory _fee) external;
    function updateTemplate(address _template) external;
    function cancelPool(address _pool) external;
    function cancel() external;
    function updateExtraData(string memory newExtraData, string memory oldExtraData) external;
    // function updatePeriod(uint256 newStartDateTime,
    //     uint256 newEndDateTime, uint256 oldStartDateTime, uint256 oldEndDateTime) external;
    function updateAmountLimit(uint256 newMinAmountToStake, uint256 oldMinAmountToStake) external;
    function updateTransferrable(bool newTransferrable,
        uint256 newMinPeriodToStake,
        bool oldTransferrable,
        uint256 oldMinPeriodToStake) external;
    // function updateClaimTime(
    //     bool newCanClaimAnyTime,
    //     uint256 neClaimDateTime,
    //     bool oldCanClaimAnyTime,
    //     uint256 oldClaimDateTime) external;
    function stake(address account, uint256 amount, uint256 totalStaked, uint8 decimals, uint256 stakers) external;
    function unstake(address account, uint256 amount, uint256 totalStaked, uint8 decimals, uint256 stakers) external;
    function claim(address account, uint256 amount) external;
    function depositRewards(uint256 amount, uint256 depositAmount) external;
    function distributeRewards(uint256 amount, uint256 totalRewardsDistributed) external;
    function updateVisible(address pool, bool isHide) external;
    event PoolCreated(       
        address pool
    );
    event FeeUpdated(Fee newFee, Fee oldFee);
    event TemplateUpdated(address newTemplate, address oldTemplate);
    event Cancelled(address pool);
    event ExtraDataUpdated(address pool, string newExtraData, string oldExtraData);
    // event PeriodUpdated(address pool, uint256 newStartDateTime,
    //     uint256 newEndDateTime, uint256 oldStartDateTime, uint256 oldEndDateTime);
    event AmountLimitUpdated(address pool, uint256 newMinAmountToStake, uint256 oldMinAmountToStake);
    event TransferrableUpdated(address pool, bool newTransferrable,
        uint256 newMinPeriodToStake,
        bool oldTransferrable,
        uint256 oldMinPeriodToStake);
    // event ClaimTimeUpdated(address pool, bool newCanClaimAnyTime, uint256 newClaimDateTime, bool oldCanClaimAnyTime, uint256 oldClaimDateTime);
    event Staked(address pool, address account, uint256 amount, uint256 totalStaked, uint8 decimals, uint256 stakers);
    event Unstaked(address pool, address account, uint256 amount, uint256 totalStaked, uint8 decimals, uint256 stakers);
    event Claimed(address pool, address account, uint256 amount, uint256 timestamp);
    event RewardsDeposit(address pool, uint256 amount, uint256 depositAmount);
    event RewardsDistributed(address pool, uint256 amount, uint256 totalRewardsDistributed);
    event VisibleUpdated(address pool, bool isHide);
}