pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/frax-gauge/tranche/BaseTranche.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../../interfaces/investments/frax-gauge/tranche/ITranche.sol";
import "../../../interfaces/investments/frax-gauge/tranche/ITrancheRegistry.sol";
import "../../../interfaces/external/frax/IFraxGauge.sol";

import "../../../common/CommonEventsAndErrors.sol";
import "../../../common/Executable.sol";

/**
  * @notice The abstract base contract for all tranche implementations
  * 
  * Owner of each tranche: LiquidityOps
  */
abstract contract BaseTranche is ITranche, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Whether this tranche has been initialized yet or not.
    /// @dev A tranche can only be initialized once
    /// factory template deployments are pushed manually, and should then be disabled
    /// (such that they can't be initialized)
    bool public initialized;
    
    /// @notice The registry used to create/initialize this instance.
    /// @dev Tranche implementations have access to call some methods of the registry
    ///      which created it.
    ITrancheRegistry public registry;

    /// @notice If this tranche is disabled, it cannot be used for new tranche instances
    ///         and new desposits can not be taken.
    ///         Withdrawals of expired locks can still take place.
    bool public override disabled;

    /// @notice The underlying frax gauge that this tranche is staking into.
    IFraxGauge public underlyingGauge;

    /// @notice The token which is being staked.
    IERC20 public stakingToken;

    /// @notice The total amount of stakingToken locked in this tranche.
    ///         This includes not yet withdrawn tokens in expired locks
    ///         Withdrawn tokens decrement this total.
    uint256 public totalLocked;

    /// @notice The implementation used to clone this instance
    uint256 public fromImplId;

    error OnlyOwnerOrRegistry(address caller);

    /// @notice Initialize the newly cloned instance.
    /// @dev When deploying new template implementations, setDisabled() should be called on
    ///      them such that they can't be initialized by others.
    function initialize(address _registry, uint256 _fromImplId, address _newOwner) external override returns (address, address) {
        if (initialized) revert AlreadyInitialized();
        if (disabled) revert InactiveTranche(address(this));

        registry = ITrancheRegistry(_registry);                
        fromImplId = _fromImplId;
        _transferOwnership(_newOwner);

        initialized = true;

        _initialize();

        return (address(underlyingGauge), address(stakingToken));
    }

    /// @notice Derived classes to implement any custom initialization
    function _initialize() internal virtual;

    /// @dev The old registry or the owner can re-point to a new registry, in case of registry upgrade.
    function setRegistry(address _registry) external override onlyOwnerOrRegistry {
        registry = ITrancheRegistry(_registry);
        emit RegistrySet(_registry);
    }

    /// @notice The registry or the owner can disable this tranche instance
    function setDisabled(bool isDisabled) external override onlyOwnerOrRegistry {
        disabled = isDisabled;
        emit SetDisabled(isDisabled);
    }

    function lockedStakes() external view override returns (IFraxGauge.LockedStake[] memory) {
        return _lockedStakes();
    }

    function _lockedStakes() internal virtual view returns (IFraxGauge.LockedStake[] memory);

    /// @notice Stake LP in the underlying gauge/vault, for a given duration
    /// @dev If there is already an active gauge lock for this tranche, and that lock
    ///      has not yet expired, then the LP will be added to the existing lock
    ///      So only one active lock will exist.
    function stake(uint256 liquidity, uint256 secs) external override onlyOwner isOpenForStaking(liquidity) returns (bytes32 kekId) {
        totalLocked += liquidity;

        // If first time lock or the latest lock has expired - then create a new lock.
        // otherwise add to the existing active lock
        IFraxGauge.LockedStake[] memory existingLockedStakes = _lockedStakes();
        uint256 lockedStakesLength = existingLockedStakes.length;
        
        if (lockedStakesLength == 0 || block.timestamp >= existingLockedStakes[lockedStakesLength - 1].ending_timestamp) {
            kekId = _stakeLocked(liquidity, secs);
        } else {
            kekId = existingLockedStakes[lockedStakesLength - 1].kek_id;
            _lockAdditional(kekId, liquidity);
        }
    }

    function _stakeLocked(uint256 liquidity, uint256 secs) internal virtual returns (bytes32);

    function _lockAdditional(bytes32 kek_id, uint256 addl_liq) internal virtual;

    /// @notice Withdraw LP from expired locks
    function withdraw(bytes32 kek_id, address destination_address) external override onlyOwner returns (uint256 withdrawnAmount) {      
        withdrawnAmount = _withdrawLocked(kek_id, destination_address);
        totalLocked -= withdrawnAmount;
    }

    function _withdrawLocked(bytes32 kek_id, address destination_address) internal virtual returns (uint256 withdrawnAmount);

    /// @notice Owner can recoer tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }

    /// @notice Execute is provided for the owner (LiquidityOps), in case there are future operations on the underlying gauge/vault
    /// which need to be called.
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bytes memory) {
        return Executable.execute(_to, _value, _data);
    }

    /// @notice Is this tranche active and the total locked is less than maxTrancheSize
    function willAcceptLock(uint256 maxTrancheSize) external view override returns (bool) {
        return (
            !disabled &&
            totalLocked < maxTrancheSize
        );
    }

    /// @notice Does this tranche have sufficient LP in it, and it's active/open for staking
    modifier isOpenForStaking(uint256 _liquidity) {
        if (disabled || !initialized) revert InactiveTranche(address(this));

        // Check this tranche has enough liquidity
        uint256 balance = stakingToken.balanceOf(address(this));
        if (balance < _liquidity) revert CommonEventsAndErrors.InsufficientBalance(address(stakingToken), _liquidity, balance);

        // Also check that this tranche implementation is still open for staking
        // Worth the gas to have the kill switch on the implementation id.
        // Any automation (eg keeper) will simulate first, so gas shouldn't be wasted on revert.
        if (registry.implDetails(fromImplId).closedForStaking) revert ITrancheRegistry.InvalidTrancheImpl(fromImplId);

        _;
    }

    modifier onlyOwnerOrRegistry() {
        if (msg.sender != owner() && msg.sender != address(registry)) revert OnlyOwnerOrRegistry(msg.sender);
        _;
    }

}