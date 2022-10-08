// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MathUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/utils/math/MathUpgradeable.sol";
import {PausableUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {SafeERC20Upgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from
    "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import {BaseAvatar} from "../lib/BaseAvatar.sol";
import {
    MAX_BPS,
    PRECISION,
    PID_80BADGER_20WBTC,
    PID_40WBTC_40DIGG_20GRAVIAURA,
    BPT_80BADGER_20WBTC,
    BPT_40WBTC_40DIGG_20GRAVIAURA,
    BASE_REWARD_POOL_80BADGER_20WBTC,
    BASE_REWARD_POOL_40WBTC_40DIGG_20GRAVIAURA
} from "../BaseConstants.sol";
import {BpsConfig, TokenAmount} from "../BaseStructs.sol";
import {AuraAvatarUtils} from "./AuraAvatarUtils.sol";
import {IBaseRewardPool} from "../interfaces/aura/IBaseRewardPool.sol";
import {IAsset} from "../interfaces/balancer/IAsset.sol";
import {IBalancerVault, JoinKind} from "../interfaces/balancer/IBalancerVault.sol";
import {KeeperCompatibleInterface} from "../interfaces/chainlink/KeeperCompatibleInterface.sol";

/// @title AuraAvatarTwoToken
/// @notice This contract handles two Balancer Pool Token (BPT) positions on behalf of an owner. It stakes the BPTs on
///         Aura and has the resulting BAL and AURA rewards periodically harvested by a keeper. Only the owner can
///         deposit and withdraw funds through this contract.
///         The owner also has admin rights and can make arbitrary calls through this contract.
/// @dev The avatar is never supposed to hold funds and only acts as an intermediary to facilitate staking and ease
///      accounting.
contract AuraAvatarTwoToken is BaseAvatar, PausableUpgradeable, AuraAvatarUtils, KeeperCompatibleInterface {
    ////////////////////////////////////////////////////////////////////////////
    // LIBRARIES
    ////////////////////////////////////////////////////////////////////////////

    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    ////////////////////////////////////////////////////////////////////////////
    // CONSTANTS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Pool ID (in AURA Booster) of the first token.
    uint256 public constant pid1 = PID_80BADGER_20WBTC;
    /// @notice Pool ID (in AURA Booster) of the second token.
    uint256 public constant pid2 = PID_40WBTC_40DIGG_20GRAVIAURA;

    /// @notice Address of the first BPT.
    IERC20MetadataUpgradeable public constant asset1 = IERC20MetadataUpgradeable(BPT_80BADGER_20WBTC);
    /// @notice Address of the second BPT.
    IERC20MetadataUpgradeable public constant asset2 = IERC20MetadataUpgradeable(BPT_40WBTC_40DIGG_20GRAVIAURA);

    /// @notice Address of the staking rewards contract for the first token.
    IBaseRewardPool public constant baseRewardPool1 = IBaseRewardPool(BASE_REWARD_POOL_80BADGER_20WBTC);
    /// @notice Address of the staking rewards contract for the second token.
    IBaseRewardPool public constant baseRewardPool2 = IBaseRewardPool(BASE_REWARD_POOL_40WBTC_40DIGG_20GRAVIAURA);

    ////////////////////////////////////////////////////////////////////////////
    // STORAGE
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Address of the manager of the avatar. Manager has limited permissions and can harvest rewards or
    ///         fine-tune operational settings.
    address public manager;
    /// @notice Address of the keeper of the avatar. Keeper can only harvest rewards at a predefined frequency.
    address public keeper;

    /// @notice The frequency (in seconds) at which the keeper should harvest rewards.
    uint256 public claimFrequency;
    /// @notice The duration for which AURA and BAL/ETH BPT TWAPs should be calculated. The TWAPs are used to set
    ///         slippage constraints during swaps.
    uint256 public twapPeriod;

    /// @notice The proportion of BAL that is sold for USDC.
    uint256 public sellBpsBalToUsdc;
    /// @notice The proportion of AURA that is sold for USDC.
    uint256 public sellBpsAuraToUsdc;

    /// @notice The current and minimum value (in bps) controlling the minimum executable price (as proprtion of oracle
    ///         price) for a BAL to USDC swap.
    BpsConfig public minOutBpsBalToUsdc;
    /// @notice The current and minimum value (in bps) controlling the minimum executable price (as proprtion of oracle
    ///         price) for an AURA to USDC swap.
    BpsConfig public minOutBpsAuraToUsdc;

    /// @notice The current and minimum value (in bps) controlling the minimum executable price (as proprtion of oracle
    ///         price) for a BAL to BAL/ETH BPT swap.
    BpsConfig public minOutBpsBalToBpt;

    /// @notice The timestamp at which rewards were last claimed and harvested.
    uint256 public lastClaimTimestamp;

    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error NotOwnerOrManager(address caller);
    error NotKeeper(address caller);

    error InvalidBps(uint256 bps);
    error LessThanBpsMin(uint256 bpsVal, uint256 bpsMin);
    error MoreThanBpsVal(uint256 bpsMin, uint256 bpsVal);
    error ZeroTwapPeriod();

    error NothingToDeposit();
    error NothingToWithdraw();
    error NoRewards();

    error TooSoon(uint256 currentTime, uint256 updateTime, uint256 minDuration);

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event ManagerUpdated(address indexed newManager, address indexed oldManager);
    event KeeperUpdated(address indexed newKeeper, address indexed oldKeeper);

    event TwapPeriodUpdated(uint256 newTwapPeriod, uint256 oldTwapPeriod);
    event ClaimFrequencyUpdated(uint256 newClaimFrequency, uint256 oldClaimFrequency);

    event SellBpsBalToUsdcUpdated(uint256 newValue, uint256 oldValue);
    event SellBpsAuraToUsdcUpdated(uint256 newValue, uint256 oldValue);

    event MinOutBpsBalToUsdcMinUpdated(uint256 newValue, uint256 oldValue);
    event MinOutBpsAuraToUsdcMinUpdated(uint256 newValue, uint256 oldValue);
    event MinOutBpsBalToBptMinUpdated(uint256 newValue, uint256 oldValue);

    event MinOutBpsBalToUsdcValUpdated(uint256 newValue, uint256 oldValue);
    event MinOutBpsAuraToUsdcValUpdated(uint256 newValue, uint256 oldValue);
    event MinOutBpsBalToBptValUpdated(uint256 newValue, uint256 oldValue);

    event Deposit(address indexed token, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed token, uint256 amount, uint256 timestamp);

    event RewardClaimed(address indexed token, uint256 amount, uint256 timestamp);
    event RewardsToStable(address indexed token, uint256 amount, uint256 timestamp);

    ////////////////////////////////////////////////////////////////////////////
    // INITIALIZATION
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Initializes the avatar. Calls parent intializers, sets default variable values and does token approvals.
    ///         Can only be called once.
    /// @param _owner Address of the initial owner.
    /// @param _manager Address of the initial manager.
    /// @param _keeper Address of the initial keeper.
    function initialize(address _owner, address _manager, address _keeper) public initializer {
        __BaseAvatar_init(_owner);
        __Pausable_init();

        manager = _manager;
        keeper = _keeper;

        claimFrequency = 1 weeks;
        twapPeriod = 1 hours;

        sellBpsBalToUsdc = 7000; // 70%
        sellBpsAuraToUsdc = 3000; // 30%

        minOutBpsBalToUsdc = BpsConfig({
            val: 9750, // 97.5%
            min: 9000 // 90%
        });
        minOutBpsAuraToUsdc = BpsConfig({
            val: 9750, // 97.5%
            min: 9000 // 90%
        });
        minOutBpsBalToBpt = BpsConfig({
            val: 9950, // 99.5%
            min: 9000 // 90%
        });

        // Booster approval for both bpt
        asset1.safeApprove(address(AURA_BOOSTER), type(uint256).max);
        asset2.safeApprove(address(AURA_BOOSTER), type(uint256).max);

        // Balancer vault approvals
        BAL.safeApprove(address(BALANCER_VAULT), type(uint256).max);
        AURA.safeApprove(address(BALANCER_VAULT), type(uint256).max);
        BPT_80BAL_20WETH.safeApprove(address(BALANCER_VAULT), type(uint256).max);

        AURA.safeApprove(address(AURA_LOCKER), type(uint256).max);

        BPT_80BAL_20WETH.safeApprove(address(AURABAL_DEPOSITOR), type(uint256).max);
        AURABAL.safeApprove(address(BAURABAL), type(uint256).max);
    }

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Checks whether a call is from the owner or manager.
    modifier onlyOwnerOrManager() {
        if (msg.sender != owner() && msg.sender != manager) {
            revert NotOwnerOrManager(msg.sender);
        }
        _;
    }

    /// @notice Checks whether a call is from the keeper.
    modifier onlyKeeper() {
        if (msg.sender != keeper) {
            revert NotKeeper(msg.sender);
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Owner - Pausing
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Pauses harvests. Can only be called by the owner or the manager.
    function pause() external onlyOwnerOrManager {
        _pause();
    }

    /// @notice Unpauses harvests. Can only be called by the owner.
    function unpause() external onlyOwner {
        _unpause();
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Owner - Config
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Updates the manager address. Can only be called by owner.
    /// @param _manager Address of the new manager.
    function setManager(address _manager) external onlyOwner {
        address oldManager = manager;

        manager = _manager;
        emit ManagerUpdated(_manager, oldManager);
    }

    /// @notice Updates the keeper address. Can only be called by owner.
    /// @param _keeper Address of the new keeper.
    function setKeeper(address _keeper) external onlyOwner {
        address oldKeeper = keeper;

        keeper = _keeper;
        emit KeeperUpdated(_keeper, oldKeeper);
    }

    /// @notice Updates the duration for which Balancer TWAPs are calculated. Can only be called by owner.
    /// @param _twapPeriod The new TWAP period in seconds.
    function setTwapPeriod(uint256 _twapPeriod) external onlyOwner {
        if (_twapPeriod == 0) {
            revert ZeroTwapPeriod();
        }

        uint256 oldTwapPeriod = twapPeriod;

        twapPeriod = _twapPeriod;
        emit TwapPeriodUpdated(_twapPeriod, oldTwapPeriod);
    }

    /// @notice Updates the frequency at which rewards are processed by the keeper. Can only be called by owner.
    /// @param _claimFrequency The new claim frequency in seconds.
    function setClaimFrequency(uint256 _claimFrequency) external onlyOwner {
        uint256 oldClaimFrequency = claimFrequency;

        claimFrequency = _claimFrequency;
        emit ClaimFrequencyUpdated(_claimFrequency, oldClaimFrequency);
    }

    /// @notice Updates the proportion of BAL that is sold for USDC. Can only be called by owner.
    /// @param _sellBpsBalToUsdc The new proportion in bps.
    function setSellBpsBalToUsdc(uint256 _sellBpsBalToUsdc) external onlyOwner {
        if (_sellBpsBalToUsdc > MAX_BPS) {
            revert InvalidBps(_sellBpsBalToUsdc);
        }

        uint256 oldSellBpsBalToUsdc = sellBpsBalToUsdc;
        sellBpsBalToUsdc = _sellBpsBalToUsdc;

        emit SellBpsBalToUsdcUpdated(_sellBpsBalToUsdc, oldSellBpsBalToUsdc);
    }

    /// @notice Updates the proportion of AURA that is sold for USDC. Can only be called by owner.
    /// @param _sellBpsAuraToUsdc The new proportion in bps.
    function setSellBpsAuraToUsdc(uint256 _sellBpsAuraToUsdc) external onlyOwner {
        if (_sellBpsAuraToUsdc > MAX_BPS) {
            revert InvalidBps(_sellBpsAuraToUsdc);
        }

        uint256 oldSellBpsAuraToUsdc = sellBpsAuraToUsdc;
        sellBpsAuraToUsdc = _sellBpsAuraToUsdc;

        emit SellBpsAuraToUsdcUpdated(_sellBpsAuraToUsdc, oldSellBpsAuraToUsdc);
    }

    /// @notice Updates the minimum possible value for the minimum executable price (in bps as proportion of an oracle
    ///         price) for a BAL to USDC swap. Can only be called by owner.
    /// @param _minOutBpsBalToUsdcMin The new minimum value in bps.
    function setMinOutBpsBalToUsdcMin(uint256 _minOutBpsBalToUsdcMin) external onlyOwner {
        if (_minOutBpsBalToUsdcMin > MAX_BPS) {
            revert InvalidBps(_minOutBpsBalToUsdcMin);
        }

        uint256 minOutBpsBalToUsdcVal = minOutBpsBalToUsdc.val;
        if (_minOutBpsBalToUsdcMin > minOutBpsBalToUsdcVal) {
            revert MoreThanBpsVal(_minOutBpsBalToUsdcMin, minOutBpsBalToUsdcVal);
        }

        uint256 oldMinOutBpsBalToUsdcMin = minOutBpsBalToUsdc.min;
        minOutBpsBalToUsdc.min = _minOutBpsBalToUsdcMin;

        emit MinOutBpsBalToUsdcMinUpdated(_minOutBpsBalToUsdcMin, oldMinOutBpsBalToUsdcMin);
    }

    /// @notice Updates the minimum possible value for the minimum executable price (in bps as proportion of an oracle
    ///         price) for an AURA to USDC swap. Can only be called by owner.
    /// @param _minOutBpsAuraToUsdcMin The new minimum value in bps.
    function setMinOutBpsAuraToUsdcMin(uint256 _minOutBpsAuraToUsdcMin) external onlyOwner {
        if (_minOutBpsAuraToUsdcMin > MAX_BPS) {
            revert InvalidBps(_minOutBpsAuraToUsdcMin);
        }

        uint256 minOutBpsAuraToUsdcVal = minOutBpsAuraToUsdc.val;
        if (_minOutBpsAuraToUsdcMin > minOutBpsAuraToUsdcVal) {
            revert MoreThanBpsVal(_minOutBpsAuraToUsdcMin, minOutBpsAuraToUsdcVal);
        }

        uint256 oldMinOutBpsAuraToUsdcMin = minOutBpsAuraToUsdc.min;
        minOutBpsAuraToUsdc.min = _minOutBpsAuraToUsdcMin;

        emit MinOutBpsAuraToUsdcMinUpdated(_minOutBpsAuraToUsdcMin, oldMinOutBpsAuraToUsdcMin);
    }

    /// @notice Updates the minimum possible value for the minimum executable price (in bps as proportion of an oracle
    ///         price) for a BAL to 80BAL-20WETH BPT swap. Can only be called by owner.
    /// @param _minOutBpsBalToBptMin The new minimum value in bps.
    function setMinOutBpsBalToBptMin(uint256 _minOutBpsBalToBptMin) external onlyOwner {
        if (_minOutBpsBalToBptMin > MAX_BPS) {
            revert InvalidBps(_minOutBpsBalToBptMin);
        }

        uint256 minOutBpsBalToBptVal = minOutBpsBalToBpt.val;
        if (_minOutBpsBalToBptMin > minOutBpsBalToBptVal) {
            revert MoreThanBpsVal(_minOutBpsBalToBptMin, minOutBpsBalToBptVal);
        }

        uint256 oldMinOutBpsBalToBptMin = minOutBpsBalToBpt.min;
        minOutBpsBalToBpt.min = _minOutBpsBalToBptMin;

        emit MinOutBpsBalToBptMinUpdated(_minOutBpsBalToBptMin, oldMinOutBpsBalToBptMin);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Manager - Config
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Updates the current value for the minimum executable price (in bps as proportion of an oracle price)
    ///         for a BAL to USDC swap. The value should be more than the minimum value. Can be called by the owner or
    ///         the manager.
    /// @param _minOutBpsBalToUsdcVal The new value in bps.
    function setMinOutBpsBalToUsdcVal(uint256 _minOutBpsBalToUsdcVal) external onlyOwnerOrManager {
        if (_minOutBpsBalToUsdcVal > MAX_BPS) {
            revert InvalidBps(_minOutBpsBalToUsdcVal);
        }

        uint256 minOutBpsBalToUsdcMin = minOutBpsBalToUsdc.min;
        if (_minOutBpsBalToUsdcVal < minOutBpsBalToUsdcMin) {
            revert LessThanBpsMin(_minOutBpsBalToUsdcVal, minOutBpsBalToUsdcMin);
        }

        uint256 oldMinOutBpsBalToUsdcVal = minOutBpsBalToUsdc.val;
        minOutBpsBalToUsdc.val = _minOutBpsBalToUsdcVal;

        emit MinOutBpsBalToUsdcValUpdated(_minOutBpsBalToUsdcVal, oldMinOutBpsBalToUsdcVal);
    }

    /// @notice Updates the current value for the minimum executable price (in bps as proportion of an oracle price)
    ///         for an AURA to USDC swap. The value should be more than the minimum value. Can be called by the owner or
    ///         the manager.
    /// @param _minOutBpsAuraToUsdcVal The new value in bps.
    function setMinOutBpsAuraToUsdcVal(uint256 _minOutBpsAuraToUsdcVal) external onlyOwnerOrManager {
        if (_minOutBpsAuraToUsdcVal > MAX_BPS) {
            revert InvalidBps(_minOutBpsAuraToUsdcVal);
        }

        uint256 minOutBpsAuraToUsdcMin = minOutBpsAuraToUsdc.min;
        if (_minOutBpsAuraToUsdcVal < minOutBpsAuraToUsdcMin) {
            revert LessThanBpsMin(_minOutBpsAuraToUsdcVal, minOutBpsAuraToUsdcMin);
        }

        uint256 oldMinOutBpsAuraToUsdcVal = minOutBpsAuraToUsdc.val;
        minOutBpsAuraToUsdc.val = _minOutBpsAuraToUsdcVal;

        emit MinOutBpsAuraToUsdcValUpdated(_minOutBpsAuraToUsdcVal, oldMinOutBpsAuraToUsdcVal);
    }

    /// @notice Updates the current value for the minimum executable price (in bps as proportion of an oracle price)
    ///         for a BAL to 80BAL-20WETH BPT swap. The value should be more than the minimum value. Can be called by
    ///         the owner or the manager.
    /// @param _minOutBpsBalToBptVal The new value in bps.
    function setMinOutBpsBalToBptVal(uint256 _minOutBpsBalToBptVal) external onlyOwnerOrManager {
        if (_minOutBpsBalToBptVal > MAX_BPS) {
            revert InvalidBps(_minOutBpsBalToBptVal);
        }

        uint256 minOutBpsBalToBptMin = minOutBpsBalToBpt.min;
        if (_minOutBpsBalToBptVal < minOutBpsBalToBptMin) {
            revert LessThanBpsMin(_minOutBpsBalToBptVal, minOutBpsBalToBptMin);
        }

        uint256 oldMinOutBpsBalToBptVal = minOutBpsBalToBpt.val;
        minOutBpsBalToBpt.val = _minOutBpsBalToBptVal;

        emit MinOutBpsBalToBptValUpdated(_minOutBpsBalToBptVal, oldMinOutBpsBalToBptVal);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Owner
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Takes a given amount of assets from the owner and stakes them on the AURA Booster. Can only be called by owner.
    /// @dev This also initializes the lastClaimTimestamp variable if there are no other deposits.
    /// @param _amountAsset1 Amount of asset1 to be staked.
    /// @param _amountAsset2 Amount of asset2 to be staked.
    function deposit(uint256 _amountAsset1, uint256 _amountAsset2) external onlyOwner {
        if (_amountAsset1 == 0 && _amountAsset2 == 0) {
            revert NothingToDeposit();
        }

        uint256 bptDeposited1 = baseRewardPool1.balanceOf(address(this));
        uint256 bptDeposited2 = baseRewardPool2.balanceOf(address(this));
        if (bptDeposited1 == 0 && bptDeposited2 == 0) {
            // Initialize at first deposit
            lastClaimTimestamp = block.timestamp;
        }

        if (_amountAsset1 > 0) {
            asset1.safeTransferFrom(msg.sender, address(this), _amountAsset1);
            AURA_BOOSTER.deposit(pid1, _amountAsset1, true);

            emit Deposit(address(asset1), _amountAsset1, block.timestamp);
        }
        if (_amountAsset2 > 0) {
            asset2.safeTransferFrom(msg.sender, address(this), _amountAsset2);
            AURA_BOOSTER.deposit(pid2, _amountAsset2, true);

            emit Deposit(address(asset2), _amountAsset2, block.timestamp);
        }
    }

    /// @notice Unstakes all staked assets and transfers them back to owner. Can only be called by owner.
    /// @dev This function doesn't claim any rewards.
    function withdrawAll() external onlyOwner {
        uint256 bptDeposited1 = baseRewardPool1.balanceOf(address(this));
        uint256 bptDeposited2 = baseRewardPool2.balanceOf(address(this));

        _withdraw(bptDeposited1, bptDeposited2);
    }

    /// @notice Unstakes the given amount of assets and transfers them back to owner. Can only be called by owner.
    /// @dev This function doesn't claim any rewards.
    /// @param _amountAsset1 Amount of asset1 to be unstaked.
    /// @param _amountAsset2 Amount of asset2 to be unstaked.
    function withdraw(uint256 _amountAsset1, uint256 _amountAsset2) external onlyOwner {
        _withdraw(_amountAsset1, _amountAsset2);
    }

    /// @notice Claims any pending BAL and AURA rewards and sends them to owner. Can only be called by owner.
    /// @dev This is a failsafe to handle rewards manually in case anything goes wrong (eg. rewards need to be sold
    ///      through other pools)
    function claimRewardsAndSendToOwner() external onlyOwner {
        // 1. Claim BAL and AURA rewards
        (uint256 totalBal, uint256 totalAura) = claimAndRegisterRewards();

        // 2. Send to owner
        address ownerCached = owner();
        BAL.safeTransfer(ownerCached, totalBal);
        AURA.safeTransfer(ownerCached, totalAura);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Owner/Manager
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Claim and process BAL and AURA rewards, selling some of it to USDC and depositing the rest to bauraBAL
    ///         and vlAURA. Can be called by the owner or manager.
    /// @dev This can be called by the owner or manager to opportunistically harvest in good market conditions.
    /// @param _auraPriceInUsd A reference price for AURA in USD (in 8 decimal precision) to compare with TWAP price. Leave as 0 to use only TWAP.
    /// @return processed_ An array containing addresses and amounts of harvested tokens (i.e. tokens that have finally
    ///                    been swapped into).
    function processRewards(uint256 _auraPriceInUsd)
        external
        onlyOwnerOrManager
        returns (TokenAmount[] memory processed_)
    {
        processed_ = processRewardsInternal(_auraPriceInUsd);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC: Keeper
    ////////////////////////////////////////////////////////////////////////////

    /// @notice A function to process pending BAL and AURA rewards at regular intervals. Can only be called by the
    ///         keeper when the contract is not paused.
    function performUpkeep(bytes calldata _performData) external override onlyKeeper whenNotPaused {
        uint256 lastClaimTimestampCached = lastClaimTimestamp;
        uint256 claimFrequencyCached = claimFrequency;
        if ((block.timestamp - lastClaimTimestampCached) < claimFrequencyCached) {
            revert TooSoon(block.timestamp, lastClaimTimestampCached, claimFrequencyCached);
        }

        uint256 auraPriceInUsd = abi.decode(_performData, (uint256));
        processRewardsInternal(auraPriceInUsd);
    }

    ////////////////////////////////////////////////////////////////////////////
    // PUBLIC VIEW
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The total amounts of both BPT tokens that the avatar is handling.
    function totalAssets() external view returns (uint256 asset1Amounts_, uint256 asset2Amounts_) {
        asset1Amounts_ = baseRewardPool1.balanceOf(address(this));
        asset2Amounts_ = baseRewardPool2.balanceOf(address(this));
    }

    /// @notice The pending BAL and AURA rewards that are yet to be processed.
    /// @dev Includes any BAL and AURA tokens in the contract.
    /// @return totalBal_ Pending BAL rewards.
    /// @return totalAura_ Pending AURA rewards.
    function pendingRewards() public view returns (uint256 totalBal_, uint256 totalAura_) {
        uint256 balEarned = baseRewardPool1.earned(address(this));
        balEarned += baseRewardPool2.earned(address(this));

        totalBal_ = balEarned + BAL.balanceOf(address(this));
        totalAura_ = getMintableAuraForBalAmount(balEarned) + AURA.balanceOf(address(this));
    }

    /// @notice Checks whether an upkeep is to be performed.
    /// @return upkeepNeeded_ A boolean indicating whether an upkeep is to be performed.
    function checkUpkeep(bytes calldata) external override returns (bool upkeepNeeded_, bytes memory performData_) {
        uint256 balPending1 = baseRewardPool1.earned(address(this));
        uint256 balPending2 = baseRewardPool2.earned(address(this));

        uint256 balBalance = BAL.balanceOf(address(this));

        if ((block.timestamp - lastClaimTimestamp) >= claimFrequency) {
            if (balPending1 > 0 || balPending2 > 0 || balBalance > 0) {
                upkeepNeeded_ = true;

                (, uint256 totalAura) = pendingRewards();
                performData_ = abi.encode(getAuraPriceInUsdSpot(totalAura));
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Unstakes the given amount of assets and transfers them back to owner.
    /// @dev This function doesn't claim any rewards. Caller can only be owner.
    /// @param _amountAsset1 Amount of asset1 to be unstaked.
    /// @param _amountAsset2 Amount of asset2 to be unstaked.
    function _withdraw(uint256 _amountAsset1, uint256 _amountAsset2) internal {
        if (_amountAsset1 == 0 && _amountAsset2 == 0) {
            revert NothingToWithdraw();
        }

        if (_amountAsset1 > 0) {
            baseRewardPool1.withdrawAndUnwrap(_amountAsset1, false);
            asset1.safeTransfer(msg.sender, _amountAsset1);

            emit Withdraw(address(asset1), _amountAsset1, block.timestamp);
        }
        if (_amountAsset2 > 0) {
            baseRewardPool2.withdrawAndUnwrap(_amountAsset2, false);
            asset2.safeTransfer(msg.sender, _amountAsset2);

            emit Withdraw(address(asset2), _amountAsset2, block.timestamp);
        }
    }

    /// @notice Claim and process BAL and AURA rewards, selling some of it to USDC and depositing the rest to bauraBAL
    ///         and vlAURA.
    /// @param _auraPriceInUsd A reference price for AURA in USD (in 8 decimal precision) to compare with TWAP price. Leave as 0 to use only TWAP.
    /// @return processed_ An array containing addresses and amounts of harvested tokens (i.e. tokens that have finally
    ///                    been swapped into).
    function processRewardsInternal(uint256 _auraPriceInUsd) internal returns (TokenAmount[] memory processed_) {
        // 1. Claim BAL and AURA rewards
        (uint256 totalBal, uint256 totalAura) = claimAndRegisterRewards();

        // 2. Swap some for USDC and send to owner
        uint256 balForUsdc = (totalBal * sellBpsBalToUsdc) / MAX_BPS;
        uint256 auraForUsdc = (totalAura * sellBpsAuraToUsdc) / MAX_BPS;

        uint256 usdcEarnedFromBal = swapBalForUsdc(balForUsdc);
        uint256 usdcEarnedFromAura = swapAuraForUsdc(auraForUsdc, _auraPriceInUsd);

        uint256 totalUsdcEarned = usdcEarnedFromBal + usdcEarnedFromAura;

        address ownerCached = owner();
        USDC.safeTransfer(ownerCached, totalUsdcEarned);

        // 3. Deposit remaining BAL to 80BAL-20ETH BPT
        depositBalToBpt(totalBal - balForUsdc);

        // 4. Swap BPT for auraBAL or lock
        swapBptForAuraBal(BPT_80BAL_20WETH.balanceOf(address(this)));

        // 5. Dogfood auraBAL in Badger vault on behalf of owner
        uint256 bauraBalBefore = BAURABAL.balanceOf(ownerCached);
        BAURABAL.depositFor(ownerCached, AURABAL.balanceOf(address(this)));
        uint256 bauraBalAfter = BAURABAL.balanceOf(ownerCached);

        // 6. Lock remaining AURA on behalf of Badger voter msig
        uint256 auraToLock = totalAura - auraForUsdc;
        AURA_LOCKER.lock(BADGER_VOTER, auraToLock);

        // Return processed amounts
        processed_ = new TokenAmount[](3);
        processed_[0] = TokenAmount(address(USDC), totalUsdcEarned);
        processed_[1] = TokenAmount(address(AURA), auraToLock);
        processed_[2] = TokenAmount(address(BAURABAL), bauraBalAfter - bauraBalBefore);

        // Emit events for analysis
        emit RewardsToStable(address(USDC), totalUsdcEarned, block.timestamp);
    }

    /// @notice Claims pending BAL and AURA rewards from both staking contracts and sets the lastClaimTimestamp value.
    /// @return totalBal_ The total BAL in contract after claiming.
    /// @return totalAura_ The total AURA in contract after claiming.
    function claimAndRegisterRewards() internal returns (uint256 totalBal_, uint256 totalAura_) {
        // Update last claimed time
        lastClaimTimestamp = block.timestamp;

        if (baseRewardPool1.earned(address(this)) > 0) {
            baseRewardPool1.getReward();
        }

        if (baseRewardPool2.earned(address(this)) > 0) {
            baseRewardPool2.getReward();
        }

        totalBal_ = BAL.balanceOf(address(this));
        totalAura_ = AURA.balanceOf(address(this));

        if (totalBal_ == 0) {
            revert NoRewards();
        }

        // Emit events for analysis
        emit RewardClaimed(address(BAL), totalBal_, block.timestamp);
        emit RewardClaimed(address(AURA), totalAura_, block.timestamp);
    }

    /// @notice Swaps the given amount of BAL for USDC.
    /// @dev The swap is only carried out if the execution price is within a predefined threshold (given by
    ///      minOutBpsBalToUsdc.val) of the oracle price.
    ///      A BAL-USD Chainlink price feed is used as the oracle.
    /// @param _balAmount The amount of BAL to sell.
    /// @return usdcEarned_ The amount of USDC earned.
    function swapBalForUsdc(uint256 _balAmount) internal returns (uint256 usdcEarned_) {
        IAsset[] memory assetArray = new IAsset[](3);
        assetArray[0] = IAsset(address(BAL));
        assetArray[1] = IAsset(address(WETH));
        assetArray[2] = IAsset(address(USDC));

        int256[] memory limits = new int256[](3);
        limits[0] = int256(_balAmount);
        limits[2] = -int256((getBalAmountInUsdc(_balAmount) * minOutBpsBalToUsdc.val) / MAX_BPS);
        IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](2);
        // BAL --> WETH
        swaps[0] = IBalancerVault.BatchSwapStep({
            poolId: BAL_WETH_POOL_ID,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: _balAmount,
            userData: new bytes(0)
        });
        // WETH --> USDC
        swaps[1] = IBalancerVault.BatchSwapStep({
            poolId: USDC_WETH_POOL_ID,
            assetInIndex: 1,
            assetOutIndex: 2,
            amount: 0, // 0 means all from last step
            userData: new bytes(0)
        });

        IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        int256[] memory assetBalances = BALANCER_VAULT.batchSwap(
            IBalancerVault.SwapKind.GIVEN_IN, swaps, assetArray, fundManagement, limits, type(uint256).max
        );

        usdcEarned_ = uint256(-assetBalances[assetBalances.length - 1]);
    }

    /// @notice Swaps the given amount of AURA for USDC.
    /// @dev The swap is only carried out if the execution price is within a predefined threshold (given by
    ///      minOutBpsAuraToUsdc.val) of the oracle price.
    ///      A combination of the Balancer TWAP for the 80AURA-20WETH pool and a ETH-USD Chainlink price feed is used
    ///      as the oracle.
    /// @param _auraAmount The amount of AURA to sell.
    /// @param _auraPriceInUsd A reference price for AURA in USD (in 8 decimal precision) to compare with TWAP price. Leave as 0 to use only TWAP.
    /// @return usdcEarned_ The amount of USDC earned.
    function swapAuraForUsdc(uint256 _auraAmount, uint256 _auraPriceInUsd) internal returns (uint256 usdcEarned_) {
        IAsset[] memory assetArray = new IAsset[](3);
        assetArray[0] = IAsset(address(AURA));
        assetArray[1] = IAsset(address(WETH));
        assetArray[2] = IAsset(address(USDC));

        int256[] memory limits = new int256[](3);
        limits[0] = int256(_auraAmount);
        // Use max(TWAP price, reference price) as oracle price for AURA.
        // If reference price is the spot price then swap will only process if:
        //  1. TWAP price is less than spot price.
        //  2. TWAP price is within the slippage threshold of spot price.
        uint256 expectedUsdcOut = MathUpgradeable.max(
            _auraAmount * _auraPriceInUsd / AURA_USD_SPOT_FACTOR, getAuraAmountInUsdc(_auraAmount, twapPeriod)
        );
        // Assumes USDC is pegged. We should sell for other stableecoins if not
        limits[2] = -int256((expectedUsdcOut * minOutBpsAuraToUsdc.val) / MAX_BPS);

        IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](2);
        // AURA --> WETH
        swaps[0] = IBalancerVault.BatchSwapStep({
            poolId: AURA_WETH_POOL_ID,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: _auraAmount,
            userData: new bytes(0)
        });
        // WETH --> USDC
        swaps[1] = IBalancerVault.BatchSwapStep({
            poolId: USDC_WETH_POOL_ID,
            assetInIndex: 1,
            assetOutIndex: 2,
            amount: 0, // 0 means all from last step
            userData: new bytes(0)
        });

        IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        int256[] memory assetBalances = BALANCER_VAULT.batchSwap(
            IBalancerVault.SwapKind.GIVEN_IN, swaps, assetArray, fundManagement, limits, type(uint256).max
        );

        usdcEarned_ = uint256(-assetBalances[assetBalances.length - 1]);
    }

    /// @notice Deposits the given amount of BAL into the 80BAL-20WETH pool.
    /// @dev The deposit is only carried out if the exchange rate is within a predefined threshold (given by
    ///      minOutBpsBalToBpt.val) of the Balancer TWAP.
    /// @param _balAmount The amount of BAL to deposit.
    function depositBalToBpt(uint256 _balAmount) internal {
        IAsset[] memory assetArray = new IAsset[](2);
        assetArray[0] = IAsset(address(BAL));
        assetArray[1] = IAsset(address(WETH));

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = _balAmount;
        maxAmountsIn[1] = 0;

        BALANCER_VAULT.joinPool(
            BAL_WETH_POOL_ID,
            address(this),
            address(this),
            IBalancerVault.JoinPoolRequest({
                assets: assetArray,
                maxAmountsIn: maxAmountsIn,
                userData: abi.encode(
                    JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
                    maxAmountsIn,
                    (getBalAmountInBpt(_balAmount) * minOutBpsBalToBpt.val) / MAX_BPS
                    ),
                fromInternalBalance: false
            })
        );
    }

    /// @notice Either swaps or deposits the given amount of 80BAL-20WETH BPT for auraBAL.
    /// @dev A swap is carried out if the execution price is better than 1:1, otherwise falls back to a deposit.
    /// @param _bptAmount The amount of 80BAL-20WETH BPT to swap or deposit.
    function swapBptForAuraBal(uint256 _bptAmount) internal {
        IBalancerVault.SingleSwap memory swapParam = IBalancerVault.SingleSwap({
            poolId: AURABAL_BAL_WETH_POOL_ID,
            kind: IBalancerVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(address(BPT_80BAL_20WETH)),
            assetOut: IAsset(address(AURABAL)),
            amount: _bptAmount,
            userData: new bytes(0)
        });

        IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        // Take the trade if we get more than 1: 1 auraBal out
        try BALANCER_VAULT.swap(
            swapParam,
            fundManagement,
            _bptAmount, // minOut
            type(uint256).max
        ) returns (uint256) {} catch {
            // Otherwise deposit
            AURABAL_DEPOSITOR.deposit(_bptAmount, true, address(0));
        }
    }
}