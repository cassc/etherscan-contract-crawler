// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "EnumerableSet.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";
import "IERC20.sol";
import "KeeperCompatible.sol";

import "IGnosisSafe.sol";
import "ILockAura.sol";
import "IGravi.sol";

/// @title   VoterModule
/// @author  Petrovska @ BadgerDAO
/// @dev  Allows whitelisted executors to trigger `performUpkeep` with limited scoped
/// in our case to carry voter weekly chores
/// Inspired from: https://github.com/gnosis/zodiac-guard-scope
contract VoterModule is KeeperCompatibleInterface, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* ========== CONSTANTS VARIABLES ========== */
    address public constant GOVERNANCE =
        0xA9ed98B5Fb8428d68664f3C5027c62A10d45826b;
    IGnosisSafe public constant SAFE = IGnosisSafe(GOVERNANCE);
    IERC20 public constant AURA =
        IERC20(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    IERC20 public constant AURABAL =
        IERC20(0x616e8BfA43F920657B3497DBf40D6b1A02D4608d);
    ILockAura public constant LOCKER =
        ILockAura(0x3Fa73f1E5d8A792C80F426fc8F84FBF7Ce9bBCAC);
    IGravi constant GRAVI = IGravi(0xBA485b556399123261a5F9c95d413B4f93107407);
    address constant TROPS = 0x042B32Ac6b453485e357938bdC38e0340d4b9276;
    address constant GRAVI_STRAT = 0x3c0989eF27e3e3fAb87a2d7C38B35880C90E63b5;

    /* ========== STATE VARIABLES ========== */
    address public guardian;
    uint256 public lastRewardClaimTimestamp;
    uint256 public claimingInterval;

    EnumerableSet.AddressSet internal _executors;

    /* ========== EVENT ========== */
    event RewardPaid(
        address indexed _user,
        address indexed _rewardToken,
        uint256 _amount,
        uint256 _timestamp
    );
    event ExecutorAdded(address indexed _user, uint256 _timestamp);
    event ExecutorRemoved(address indexed _user, uint256 _timestamp);
    event GuardianUpdated(
        address indexed newGuardian,
        address indexed oldGuardian,
        uint256 timestamp
    );

    constructor(
        address _guardian,
        uint64 _startTimestamp,
        uint256 _claimingIntervalSeconds
    ) {
        guardian = _guardian;
        lastRewardClaimTimestamp = _startTimestamp;
        claimingInterval = _claimingIntervalSeconds;
    }

    /***************************************
                    MODIFIERS
    ****************************************/
    modifier onlyGovernance() {
        require(msg.sender == GOVERNANCE, "not-governance!");
        _;
    }

    modifier onlyExecutors() {
        require(_executors.contains(msg.sender), "not-executor!");
        _;
    }

    modifier onlyGovernanceOrGuardian() {
        require(
            msg.sender == GOVERNANCE || msg.sender == guardian,
            "not-gov-or-guardian"
        );
        _;
    }

    /***************************************
               ADMIN - GOVERNANCE
    ****************************************/
    /// @dev Adds an executor to the Set of allowed addresses.
    /// @notice Only callable by governance.
    /// @param _executor Address which will have rights to call `checkTransactionAndExecute`.
    function addExecutor(address _executor) external onlyGovernance {
        require(_executor != address(0), "zero-address!");
        require(_executors.add(_executor), "not-add-in-set!");
        emit ExecutorAdded(_executor, block.timestamp);
    }

    /// @dev Removes an executor to the Set of allowed addresses.
    /// @notice Only callable by governance.
    /// @param _executor Address which will not have rights to call `checkTransactionAndExecute`.
    function removeExecutor(address _executor) external onlyGovernance {
        require(_executor != address(0), "zero-address!");
        require(_executors.remove(_executor), "not-remove-in-set!");
        emit ExecutorRemoved(_executor, block.timestamp);
    }

    /// @dev Updates the guardian address
    /// @notice Only callable by governance.
    /// @param _guardian Address which will beccome guardian
    function setGuardian(address _guardian) external onlyGovernance {
        require(_guardian != address(0), "zero-address!");
        address oldGuardian = _guardian;
        guardian = _guardian;
        emit GuardianUpdated(_guardian, oldGuardian, block.timestamp);
    }

    /// @dev Pauses the contract, which prevents executing performUpkeep.
    function pause() external onlyGovernanceOrGuardian {
        _pause();
    }

    /// @dev Unpauses the contract.
    function unpause() external onlyGovernance {
        _unpause();
    }

    /***************************************
                KEEPERS - EXECUTORS
    ****************************************/
    /// @dev Runs off-chain at every block to determine if the `performUpkeep`
    /// function should be called on-chain.
    function checkUpkeep(bytes calldata)
        external
        view
        override
        whenNotPaused
        returns (bool upkeepNeeded, bytes memory checkData)
    {
        (
            uint256 unlockable,
            uint256 rewards,
            uint256 aurabalSafeBal,
            bool isGraviWithdrawable
        ) = checkUpKeepConditions();

        if (unlockable > 0) {
            // prio expired locks
            upkeepNeeded = true;
        } else if (isRewardClaimable(rewards, aurabalSafeBal)) {
            upkeepNeeded = true;
        } else if (isGraviWithdrawable) {
            upkeepNeeded = true;
        }
    }

    /// @dev Contains the logic that should be executed on-chain when
    /// `checkUpkeep` returns true.
    function performUpkeep(bytes calldata performData)
        external
        override
        onlyExecutors
        whenNotPaused
        nonReentrant
    {
        /// @dev safety check, ensuring onchain module is config
        require(SAFE.isModuleEnabled(address(this)), "no-module-enabled!");
        // 1. process unlocks
        _processExpiredLocks();
        // 2. claim vlaura rewards and transfer aurabal to trops
        _claimRewardsAndSweep();
        // 3. wd gravi and lock aura in voter
        _withdrawGraviAndLockAura();
    }

    /// @dev method will process expired locks if available
    function _processExpiredLocks() internal {
        (, uint256 unlockable, , ) = LOCKER.lockedBalances(address(SAFE));
        if (unlockable > 0) {
            _checkTransactionAndExecute(
                address(LOCKER),
                abi.encodeCall(ILockAura.processExpiredLocks, true)
            );
        }
    }

    /// @dev method will claim auraBAL & transfer balance to trops
    function _claimRewardsAndSweep() internal {
        ILockAura.EarnedData[] memory earnData = LOCKER.claimableRewards(
            address(SAFE)
        );
        uint256 aurabalSafeBal = AURABAL.balanceOf(address(SAFE));
        if (isRewardClaimable(earnData[0].amount, aurabalSafeBal)) {
            /// @dev will be used as condition, so rewards are not claim that often, leave time for accum
            lastRewardClaimTimestamp = block.timestamp;
            if (earnData[0].amount > 0) {
                _checkTransactionAndExecute(
                    address(LOCKER),
                    abi.encodeCall(ILockAura.getReward, address(SAFE))
                );
                aurabalSafeBal = AURABAL.balanceOf(address(SAFE));
            }
            _checkTransactionAndExecute(
                address(AURABAL),
                abi.encodeCall(IERC20.transfer, (TROPS, aurabalSafeBal))
            );
            emit RewardPaid(
                address(SAFE),
                address(AURABAL),
                aurabalSafeBal,
                lastRewardClaimTimestamp
            );
        }
    }

    /// @dev method will wd from graviaura and lock aura in voter msig
    function _withdrawGraviAndLockAura() internal {
        uint256 graviSafeBal = GRAVI.balanceOf(address(SAFE));
        if (graviSafeBal > 0) {
            uint256 totalWdAura = totalAuraWithdrawable();
            /// @dev covers corner case when nothing might be withdrawable
            if (totalWdAura > 0) {
                uint256 graviBalance = GRAVI.balance();
                uint256 graviTotalSupply = GRAVI.totalSupply();
                /// @dev depends on condition we will do a full wd or partial
                if (
                    totalWdAura <
                    (graviSafeBal * graviBalance) / graviTotalSupply
                ) {
                    _checkTransactionAndExecute(
                        address(GRAVI),
                        abi.encodeCall(
                            IGravi.withdraw,
                            (totalWdAura * graviTotalSupply) / graviBalance
                        )
                    );
                } else {
                    _checkTransactionAndExecute(
                        address(GRAVI),
                        abi.encodeWithSelector(IGravi.withdrawAll.selector)
                    );
                }
            }

            uint256 auraSafeBal = AURA.balanceOf(address(SAFE));
            if (auraSafeBal > 0) {
                /// @dev approves aura to process in locker
                _checkTransactionAndExecute(
                    address(AURA),
                    abi.encodeCall(
                        IERC20.approve,
                        (address(LOCKER), auraSafeBal)
                    )
                );
                /// @dev lock aura in locker
                _checkTransactionAndExecute(
                    address(LOCKER),
                    abi.encodeCall(ILockAura.lock, (address(SAFE), auraSafeBal))
                );
            }
        }
    }

    /// @dev Allows executing specific calldata into an address thru a gnosis-safe, which have enable this contract as module.
    /// @notice Only callable by executors.
    /// @param to Contract address where we will execute the calldata.
    /// @param data Calldata to be executed within the boundaries of the `allowedFunctions`.
    function _checkTransactionAndExecute(address to, bytes memory data)
        internal
    {
        if (data.length >= 4) {
            require(
                SAFE.execTransactionFromModule(
                    to,
                    0,
                    data,
                    IGnosisSafe.Operation.Call
                ),
                "exec-error!"
            );
        }
    }

    /***************************************
               PUBLIC FUNCTION
    ****************************************/

    /// @dev Returns all addresses which have executor role
    function getExecutors() public view returns (address[] memory) {
        return _executors.values();
    }

    /// @dev uint256 value-conditions to trigger `performUpKeep`
    /// @return Values for `unlockable` locks expired, `rewards` auraBAL accumulated & `graviAURA` balance in voter
    function checkUpKeepConditions()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        /// @dev multi-conditional upkeep checks
        (, uint256 unlockable, , ) = LOCKER.lockedBalances(address(SAFE));
        ILockAura.EarnedData[] memory earnData = LOCKER.claimableRewards(
            address(SAFE)
        );
        uint256 aurabalSafeBal = AURABAL.balanceOf(address(SAFE));
        uint256 graviBal = GRAVI.balanceOf(address(SAFE));

        return (
            unlockable,
            earnData[0].amount,
            aurabalSafeBal,
            graviBal > 0 && totalAuraWithdrawable() > 0
        );
    }

    /// @dev reusable view method for checking if auraBAL rewards are claimable
    /// @param claimableRewards available auraBAL rewards amount
    /// @param safeRewardsBal current value of auraBAL in the voter safe
    /// @return boolean conditional to determine if we should trigger `_claimRewardsAndSweep` section
    function isRewardClaimable(uint256 claimableRewards, uint256 safeRewardsBal)
        public
        view
        returns (bool)
    {
        return
            (claimableRewards > 0 || safeRewardsBal > 0) &&
            (block.timestamp - lastRewardClaimTimestamp) > claimingInterval;
    }

    /// @dev returns the total amount withdrawable at current moment
    /// @return totalWdAura Total amount of AURA withdrawable, summation of available in vault, strat and unlockable
    function totalAuraWithdrawable() public view returns (uint256 totalWdAura) {
        /// @dev check avail aura to avoid wd reverts
        uint256 auraInVault = AURA.balanceOf(address(GRAVI));
        uint256 auraInStrat = AURA.balanceOf(address(GRAVI_STRAT));
        (, uint256 unlockableStrat, , ) = LOCKER.lockedBalances(GRAVI_STRAT);
        totalWdAura = auraInVault + auraInStrat + unlockableStrat;
    }
}