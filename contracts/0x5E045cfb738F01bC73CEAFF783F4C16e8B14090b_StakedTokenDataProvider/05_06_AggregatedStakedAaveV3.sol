// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

interface AggregatedStakedAaveV3 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event AssetConfigUpdated(address indexed asset, uint256 emission);
    event AssetIndexUpdated(address indexed asset, uint256 index);
    event Cooldown(address indexed user, uint256 amount);
    event CooldownSecondsChanged(uint256 cooldownSeconds);
    event DelegateChanged(address indexed delegator, address indexed delegatee, uint8 delegationType);
    event DelegatedPowerChanged(address indexed user, uint256 amount, uint8 delegationType);
    event ExchangeRateChanged(uint216 exchangeRate);
    event FundsReturned(uint256 amount);
    event GHODebtTokenChanged(address indexed newDebtToken);
    event MaxSlashablePercentageChanged(uint256 newPercentage);
    event PendingAdminChanged(address indexed newPendingAdmin, uint256 role);
    event Redeem(address indexed from, address indexed to, uint256 assets, uint256 shares);
    event RewardsAccrued(address user, uint256 amount);
    event RewardsClaimed(address indexed from, address indexed to, uint256 amount);
    event RoleClaimed(address indexed newAdmin, uint256 role);
    event Slashed(address indexed destination, uint256 amount);
    event SlashingExitWindowDurationChanged(uint256 windowSeconds);
    event SlashingSettled();
    event Staked(address indexed from, address indexed to, uint256 assets, uint256 shares);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);

    struct AssetConfigInput {
        uint128 emissionPerSecond;
        uint256 totalStaked;
        address underlyingAsset;
    }

    struct ExchangeRateSnapshot {
        uint40 blockNumber;
        uint216 value;
    }

    function CLAIM_HELPER_ROLE() external view returns (uint256);
    function COOLDOWN_ADMIN_ROLE() external view returns (uint256);
    function COOLDOWN_SECONDS() external view returns (uint256);
    function DELEGATE_BY_TYPE_TYPEHASH() external view returns (bytes32);
    function DELEGATE_TYPEHASH() external view returns (bytes32);
    function DISTRIBUTION_END() external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function EIP712_REVISION() external view returns (bytes memory);
    function EMISSION_MANAGER() external view returns (address);
    function EXCHANGE_RATE_UNIT() external view returns (uint256);
    function INITIAL_EXCHANGE_RATE() external view returns (uint216);
    function LOWER_BOUND() external view returns (uint256);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function PRECISION() external view returns (uint8);
    function REVISION() external pure returns (uint256);
    function REWARDS_VAULT() external view returns (address);
    function REWARD_TOKEN() external view returns (address);
    function SLASH_ADMIN_ROLE() external view returns (uint256);
    function STAKED_TOKEN() external view returns (address);
    function UNSTAKE_WINDOW() external view returns (uint256);
    function _aaveGovernance() external view returns (address);
    function _nonces(address) external view returns (uint256);
    function _votingSnapshots(address, uint256) external view returns (uint128 blockNumber, uint128 value);
    function _votingSnapshotsCounts(address) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    struct AssetData {
      uint128 emissionPerSecond;
      uint128 lastUpdateTimestamp;
      uint256 index;
    }
    function assets(address) external view returns (AssetData memory);
    function balanceOf(address account) external view returns (uint256);
    function claimRewards(address to, uint256 amount) external;
    function claimRewardsAndRedeem(address to, uint256 claimAmount, uint256 redeemAmount) external;
    function claimRewardsAndRedeemOnBehalf(address from, address to, uint256 claimAmount, uint256 redeemAmount)
        external;
    function claimRewardsAndStake(address to, uint256 amount) external returns (uint256);
    function claimRewardsAndStakeOnBehalf(address from, address to, uint256 amount) external returns (uint256);
    function claimRewardsOnBehalf(address from, address to, uint256 amount) external returns (uint256);
    function claimRoleAdmin(uint256 role) external;
    function configureAssets(AssetConfigInput[] memory assetsConfigInput) external;
    function cooldown() external;
    function cooldownOnBehalfOf(address from) external;
    function decimals() external view returns (uint8);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function delegate(address delegatee) external;
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
    function delegateByType(address delegatee, uint8 delegationType) external;
    function delegateByTypeBySig(
        address delegatee,
        uint8 delegationType,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function getAdmin(uint256 role) external view returns (address);
    function getCooldownSeconds() external view returns (uint256);
    function getDelegateeByType(address delegator, uint8 delegationType) external view returns (address);
    function getExchangeRate() external view returns (uint216);
    function getExchangeRateSnapshot(uint32 index) external view returns (ExchangeRateSnapshot memory);
    function getExchangeRateSnapshotsCount() external view returns (uint32);
    function getMaxSlashablePercentage() external view returns (uint256);
    function getPendingAdmin(uint256 role) external view returns (address);
    function getPowerAtBlock(address user, uint256 blockNumber, uint8 delegationType) external view returns (uint256);
    function getPowerCurrent(address user, uint8 delegationType) external view returns (uint256);
    function getTotalRewardsBalance(address staker) external view returns (uint256);
    function getUserAssetData(address user, address asset) external view returns (uint256);
    function ghoDebtToken() external view returns (address);
    function inPostSlashingPeriod() external view returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function initialize(
        address slashingAdmin,
        address cooldownPauseAdmin,
        address claimHelper,
        uint256 maxSlashablePercentage,
        uint256 cooldownSeconds
    ) external;
    function name() external view returns (string memory);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
    function previewRedeem(uint256 shares) external view returns (uint256);
    function previewStake(uint256 assets) external view returns (uint256);
    function redeem(address to, uint256 amount) external;
    function redeemOnBehalf(address from, address to, uint256 amount) external;
    function returnFunds(uint256 amount) external;
    function setCooldownSeconds(uint256 cooldownSeconds) external;
    function setGHODebtToken(address newGHODebtToken) external;
    function setMaxSlashablePercentage(uint256 percentage) external;
    function setPendingAdmin(uint256 role, address newPendingAdmin) external;
    function settleSlashing() external;
    function slash(address destination, uint256 amount) external returns (uint256);
    function stake(address to, uint256 amount) external;
    function stakeWithPermit(address from, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function stakerRewardsToClaim(address) external view returns (uint256);
    function stakersCooldowns(address) external view returns (uint40 timestamp, uint216 amount);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function totalSupplyAt(uint256) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}