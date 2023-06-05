// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import './interfaces/HMTokenInterface.sol';
import './interfaces/IEscrow.sol';
import './interfaces/IRewardPool.sol';
import './interfaces/IStaking.sol';
import './libs/Stakes.sol';
import './utils/Math.sol';

/**
 * @title Staking contract
 * @dev The Staking contract allows Operator, Exchange Oracle, Recording Oracle and Reputation Oracle to stake to Escrow.
 */
contract Staking is IStaking, OwnableUpgradeable, UUPSUpgradeable {
    using SafeMath for uint256;
    using Stakes for Stakes.Staker;

    // Token address
    address public token;

    // Reward pool address
    address public override rewardPool;

    // Minimum amount of tokens an staker needs to stake
    uint256 public minimumStake;

    // Time in blocks to unstake
    uint32 public lockPeriod;

    // Staker stakes: staker => Stake
    mapping(address => Stakes.Staker) public stakes;

    // List of stakers
    address[] public stakers;

    // Allocations : escrowAddress => Allocation
    mapping(address => IStaking.Allocation) public allocations;

    /**
     * @dev Emitted when `staker` stake `tokens` amount.
     */
    event StakeDeposited(address indexed staker, uint256 tokens);

    /**
     * @dev Emitted when `staker` unstaked and locked `tokens` amount `until` block.
     */
    event StakeLocked(address indexed staker, uint256 tokens, uint256 until);

    /**
     * @dev Emitted when `staker` withdraws `tokens` staked.
     */
    event StakeWithdrawn(address indexed staker, uint256 tokens);

    /**
     * @dev Emitted when `staker` was slashed for a total of `tokens` amount.
     */
    event StakeSlashed(
        address indexed staker,
        uint256 tokens,
        address indexed escrowAddress,
        address slasher
    );

    /**
     * @dev Emitted when `staker` allocated `tokens` amount to `escrowAddress`.
     */
    event StakeAllocated(
        address indexed staker,
        uint256 tokens,
        address indexed escrowAddress,
        uint256 createdAt
    );

    /**
     * @dev Emitted when `staker` close an allocation `escrowAddress`.
     */
    event AllocationClosed(
        address indexed staker,
        uint256 tokens,
        address indexed escrowAddress,
        uint256 closedAt
    );

    /**
     * @dev Emitted when `owner` set new value for `minimumStake`.
     */
    event SetMinumumStake(uint256 indexed minimumStake);

    /**
     * @dev Emitted when `owner` set new value for `lockPeriod`.
     */
    event SetLockPeriod(uint32 indexed lockPeriod);

    /**
     * @dev Emitted when `owner` set new value for `rewardPool`.
     */
    event SetRewardPool(address indexed rewardPool);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _token,
        uint256 _minimumStake,
        uint32 _lockPeriod
    ) external payable virtual initializer {
        __Ownable_init_unchained();

        __Staking_init_unchained(_token, _minimumStake, _lockPeriod);
    }

    function __Staking_init_unchained(
        address _token,
        uint256 _minimumStake,
        uint32 _lockPeriod
    ) internal onlyInitializing {
        token = _token;
        _setMinimumStake(_minimumStake);
        _setLockPeriod(_lockPeriod);
    }

    /**
     * @dev Set the minimum stake amount.
     * @param _minimumStake Minimum stake
     */
    function setMinimumStake(
        uint256 _minimumStake
    ) external override onlyOwner {
        _setMinimumStake(_minimumStake);
    }

    /**
     * @dev Set the minimum stake amount.
     * @param _minimumStake Minimum stake
     */
    function _setMinimumStake(uint256 _minimumStake) private {
        require(_minimumStake > 0, 'Must be a positive number');
        minimumStake = _minimumStake;
        emit SetMinumumStake(minimumStake);
    }

    /**
     * @dev Set the lock period for unstaking.
     * @param _lockPeriod Period in blocks to wait for token withdrawals after unstaking
     */
    function setLockPeriod(uint32 _lockPeriod) external override onlyOwner {
        _setLockPeriod(_lockPeriod);
    }

    /**
     * @dev Set the lock period for unstaking.
     * @param _lockPeriod Period in blocks to wait for token withdrawals after unstaking
     */
    function _setLockPeriod(uint32 _lockPeriod) private {
        require(_lockPeriod > 0, 'Must be a positive number');
        lockPeriod = _lockPeriod;
        emit SetLockPeriod(lockPeriod);
    }

    /**
     * @dev Set the destionations of the rewards.
     * @param _rewardPool Reward pool address
     */
    function setRewardPool(address _rewardPool) external override onlyOwner {
        _setRewardPool(_rewardPool);
    }

    /**
     * @dev Set the destionations of the rewards.
     * @param _rewardPool Reward pool address
     */
    function _setRewardPool(address _rewardPool) private {
        require(_rewardPool != address(0), 'Must be a valid address');
        rewardPool = _rewardPool;
        emit SetRewardPool(_rewardPool);
    }

    /**
     * @dev Return if escrowAddress is use for allocation.
     * @param _escrowAddress Address used as signer by the staker for an allocation
     * @return True if _escrowAddress already used
     */
    function isAllocation(
        address _escrowAddress
    ) external view override returns (bool) {
        return _getAllocationState(_escrowAddress) != AllocationState.Null;
    }

    /**
     * @dev Getter that returns if an staker has any stake.
     * @param _staker Address of the staker
     * @return True if staker has staked tokens
     */
    function hasStake(address _staker) external view override returns (bool) {
        return stakes[_staker].tokensStaked > 0;
    }

    /**
     * @dev Getter that returns if an staker has any available stake.
     * @param _staker Address of the staker
     * @return True if staker has available tokens staked
     */
    function hasAvailableStake(
        address _staker
    ) external view override returns (bool) {
        return stakes[_staker].tokensAvailable() > 0;
    }

    /**
     * @dev Return the allocation by escrow address.
     * @param _escrowAddress Address used as allocation identifier
     * @return Allocation data
     */
    function getAllocation(
        address _escrowAddress
    ) external view override returns (Allocation memory) {
        return _getAllocation(_escrowAddress);
    }

    /**
     * @dev Return the allocation by job ID.
     * @param _escrowAddress Address used as allocation identifier
     * @return Allocation data
     */
    function _getAllocation(
        address _escrowAddress
    ) private view returns (Allocation memory) {
        return allocations[_escrowAddress];
    }

    /**
     * @dev Return the current state of an allocation.
     * @param _escrowAddress Address used as the allocation identifier
     * @return AllocationState
     */
    function getAllocationState(
        address _escrowAddress
    ) external view override returns (AllocationState) {
        return _getAllocationState(_escrowAddress);
    }

    /**
     * @dev Return the current state of an allocation, partially depends on job status
     * @param _escrowAddress Job identifier (Escrow address)
     * @return AllocationState
     */
    function _getAllocationState(
        address _escrowAddress
    ) private view returns (AllocationState) {
        Allocation storage allocation = allocations[_escrowAddress];

        if (allocation.staker == address(0)) {
            return AllocationState.Null;
        }

        IEscrow escrow = IEscrow(_escrowAddress);
        IEscrow.EscrowStatuses escrowStatus = escrow.status();

        if (
            allocation.createdAt != 0 &&
            allocation.tokens > 0 &&
            escrowStatus == IEscrow.EscrowStatuses.Pending
        ) {
            return AllocationState.Pending;
        }

        if (
            allocation.closedAt == 0 &&
            escrowStatus == IEscrow.EscrowStatuses.Launched
        ) {
            return AllocationState.Active;
        }

        if (
            allocation.closedAt == 0 &&
            (escrowStatus == IEscrow.EscrowStatuses.Complete ||
                escrowStatus == IEscrow.EscrowStatuses.Cancelled)
        ) {
            return AllocationState.Completed;
        }

        return AllocationState.Closed;
    }

    /**
     * @dev Get the total amount of tokens staked by the staker.
     * @param _staker Address of the staker
     * @return Amount of tokens staked by the staker
     */
    function getStakedTokens(
        address _staker
    ) external view override returns (uint256) {
        return stakes[_staker].tokensStaked;
    }

    /**
     * @dev Get staker data by the staker address.
     * @param _staker Address of the staker
     * @return Staker's data
     */
    function getStaker(
        address _staker
    ) external view override returns (Stakes.Staker memory) {
        return stakes[_staker];
    }

    /**
     * @dev Get list of stakers
     * @return List of staker's addresses, and stake data
     */
    function getListOfStakers()
        external
        view
        override
        returns (address[] memory, Stakes.Staker[] memory)
    {
        address[] memory _stakerAddresses = stakers;
        uint256 _stakersCount = _stakerAddresses.length;

        if (_stakersCount == 0) {
            return (new address[](0), new Stakes.Staker[](0));
        }

        Stakes.Staker[] memory _stakers = new Stakes.Staker[](_stakersCount);

        for (uint256 _i = 0; _i < _stakersCount; _i++) {
            _stakers[_i] = stakes[_stakerAddresses[_i]];
        }

        return (_stakerAddresses, _stakers);
    }

    /**
     * @dev Deposit tokens on the staker stake.
     * @param _tokens Amount of tokens to stake
     */
    function stake(uint256 _tokens) external override {
        require(_tokens > 0, 'Must be a positive number');

        Stakes.Staker memory staker = stakes[msg.sender];
        require(
            staker.tokensSecureStake().add(_tokens) >= minimumStake,
            'Total stake is below the minimum threshold'
        );

        if (staker.tokensStaked == 0) {
            staker = Stakes.Staker(0, 0, 0, 0);
            stakes[msg.sender] = staker;
            stakers.push(msg.sender);
        }

        _safeTransferFrom(msg.sender, address(this), _tokens);

        stakes[msg.sender].deposit(_tokens);

        emit StakeDeposited(msg.sender, _tokens);
    }

    /**
     * @dev Unstake tokens from the staker stake, lock them until lock period expires.
     * @param _tokens Amount of tokens to unstake
     */
    function unstake(uint256 _tokens) external override {
        Stakes.Staker storage staker = stakes[msg.sender];

        require(_tokens > 0, 'Must be a positive number');
        require(
            staker.tokensAvailable() >= _tokens,
            'Insufficient amount to unstake'
        );

        uint256 newStake = staker.tokensSecureStake().sub(_tokens);
        require(
            newStake == 0 || newStake >= minimumStake,
            'Total stake is below the minimum threshold'
        );

        uint256 tokensToWithdraw = staker.tokensWithdrawable();
        if (tokensToWithdraw > 0) {
            _withdraw(msg.sender);
        }

        staker.lockTokens(_tokens, lockPeriod);

        emit StakeLocked(
            msg.sender,
            staker.tokensLocked,
            staker.tokensLockedUntil
        );
    }

    /**
     * @dev Withdraw staker tokens based on the locking period.
     */
    function withdraw() external override {
        _withdraw(msg.sender);
    }

    /**
     * @dev Withdraw staker tokens once the lock period has passed.
     * @param _staker Address of staker to withdraw funds from
     */
    function _withdraw(address _staker) private {
        uint256 tokensToWithdraw = stakes[_staker].withdrawTokens();
        require(
            tokensToWithdraw > 0,
            'Stake has no available tokens for withdrawal'
        );

        _safeTransfer(_staker, tokensToWithdraw);

        emit StakeWithdrawn(_staker, tokensToWithdraw);
    }

    /**
     * @dev Slash the staker stake allocated to the escrow.
     * @param _staker Address of staker to slash
     * @param _escrowAddress Escrow address
     * @param _tokens Amount of tokens to slash from the indexer stake
     */
    function slash(
        address _slasher,
        address _staker,
        address _escrowAddress,
        uint256 _tokens
    ) external override onlyOwner {
        require(_escrowAddress != address(0), 'Must be a valid address');

        Stakes.Staker storage staker = stakes[_staker];

        Allocation storage allocation = allocations[_escrowAddress];

        require(_tokens > 0, 'Must be a positive number');

        require(
            _tokens <= allocation.tokens,
            'Slash tokens exceed allocated ones'
        );

        staker.unallocate(_tokens);
        allocation.tokens = allocation.tokens.sub(_tokens);

        staker.release(_tokens);

        _safeTransfer(rewardPool, _tokens);

        // Keep record on Reward Pool
        IRewardPool(rewardPool).addReward(
            _escrowAddress,
            _staker,
            _slasher,
            _tokens
        );

        emit StakeSlashed(_staker, _tokens, _escrowAddress, _slasher);
    }

    /**
     * @dev Allocate available tokens to an escrow.
     * @param _escrowAddress The allocationID will work to identify collected funds related to this allocation
     * @param _tokens Amount of tokens to allocate
     */
    function allocate(
        address _escrowAddress,
        uint256 _tokens
    ) external override {
        _allocate(msg.sender, _escrowAddress, _tokens);
    }

    /**
     * @dev Allocate available tokens to an escrow.
     * @param _staker Staker address to allocate funds from.
     * @param _escrowAddress The escrow address which collected funds related to this allocation
     * @param _tokens Amount of tokens to allocate
     */
    function _allocate(
        address _staker,
        address _escrowAddress,
        uint256 _tokens
    ) private {
        require(_escrowAddress != address(0), 'Must be a valid address');
        require(
            stakes[msg.sender].tokensAvailable() >= _tokens,
            'Insufficient amount of tokens in the stake'
        );
        require(_tokens > 0, 'Must be a positive number');
        require(
            _getAllocationState(_escrowAddress) == AllocationState.Null,
            'Allocation already exists'
        );

        Allocation memory allocation = Allocation(
            _escrowAddress, // Escrow address
            _staker, // Staker address
            _tokens, // Tokens allocated
            block.number, // createdAt
            0 // closedAt
        );

        allocations[_escrowAddress] = allocation;
        stakes[_staker].allocate(allocation.tokens);

        emit StakeAllocated(
            _staker,
            allocation.tokens,
            _escrowAddress,
            allocation.createdAt
        );
    }

    /**
     * @dev Close an allocation and free the staked tokens.
     * @param _escrowAddress The allocation identifier
     */
    function closeAllocation(address _escrowAddress) external override {
        require(_escrowAddress != address(0), 'Must be a valid address');

        _closeAllocation(_escrowAddress);
    }

    /**
     * @dev Close an allocation and free the staked tokens.
     * @param _escrowAddress The allocation identifier
     */
    function _closeAllocation(address _escrowAddress) private {
        Allocation storage allocation = allocations[_escrowAddress];
        require(
            allocation.staker == msg.sender,
            'Only the allocator can close the allocation'
        );

        AllocationState allocationState = _getAllocationState(_escrowAddress);
        require(
            allocationState == AllocationState.Completed,
            'Allocation has no completed state'
        );

        allocation.closedAt = block.number;
        uint256 diffInBlocks = Math.diffOrZero(
            allocation.closedAt,
            allocation.createdAt
        );
        require(diffInBlocks > 0, 'Allocation cannot be closed so early');

        uint256 _tokens = allocation.tokens;

        stakes[allocation.staker].unallocate(_tokens);
        allocation.tokens = 0;

        emit AllocationClosed(
            allocation.staker,
            _tokens,
            _escrowAddress,
            allocation.closedAt
        );
    }

    function _safeTransfer(address to, uint256 value) internal {
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), to, value);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 value
    ) internal {
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(token),
            from,
            to,
            value
        );
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}