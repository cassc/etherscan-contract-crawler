// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./interfaces/IMembershipStaking.sol";

contract MembershipStaking is IMembershipStaking, OwnableUpgradeable {
    using SafeCastUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Burn address
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// @notice RBN token contract
    IERC20Upgradeable public rbn;

    /// @notice PoolFactory contract
    address public factory;

    /// @notice A checkpoint for marking stake size from a given block
    struct Checkpoint {
        uint256 fromBlock;
        uint256 stake;
    }

    /// @notice A record of stake checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice Mapping of addresses to their locked stake amounts
    mapping(address => uint256) public locked;

    /// @notice Amount of staked RBN required for active managers
    uint256 public managerMinimalStake;

    // EVENTS

    /// @notice Event emitted when somebody stakes RBN
    /// @param account Account who stakes
    /// @param amount Staked amount
    event Staked(address indexed account, uint256 amount);

    /// @notice Event emitted when somebody unstaked RBN
    /// @param account Account who unstakes
    /// @param amount Unstaked amount
    event Unstaked(address indexed account, uint256 amount);

    /// @notice Event emitted when somebody's stake is burned
    /// @param account Account who's stake is burned
    /// @param amount Burned amount
    event Burned(address indexed account, uint256 amount);

    /// @notice Event emitted when new value for manager minimal stake is set
    /// @param stake New value for manager's minimal stake
    event ManagerMinimalStakeSet(uint256 stake);

    /// @notice Event emitted when some account stake is locked
    /// @param account Account who's stake is locked
    /// @param amount Locked amount
    event StakeLocked(address indexed account, uint256 amount);

    /// @notice Event emitted when some account stake is unlocked
    /// @param account Account who's stake is unlocked
    /// @param amount Unlocked amount
    event StakeUnlocked(address indexed account, uint256 amount);

    // CONSTRUCTOR

    /// @notice Upgradeable contract constructor
    /// @param rbn_ Address of the RBN contract
    /// @param factory_ Address of the PoolFactory contract
    /// @param managerMinimalStake_ Value of manager minimal stake
    function initialize(
        IERC20Upgradeable rbn_,
        address factory_,
        uint256 managerMinimalStake_
    ) external initializer {
        require(address(rbn_) != address(0), "AIZ");
        require(factory_ != address(0), "AIZ");

        __Ownable_init();
        rbn = rbn_;
        factory = factory_;
        managerMinimalStake = managerMinimalStake_;
    }

    // PUBLIC FUNCTIONS

    /// @notice Function is called to stake RBN
    /// @dev Approval for given amount should be made in prior
    /// @param amount Amount to stake
    function stake(uint256 amount) external {
        _stake(msg.sender, amount);
    }

    /// @notice Function is called to unstake RBN
    /// @dev Only possible to unstake unlocked part of RBN
    /// @param amount Amount to unstake
    function unstake(uint256 amount) external {
        _unstake(msg.sender, msg.sender, amount);
    }

    // RESTRICTED FUNCTIONS

    /// @notice Function is called only by owner to set manager minimal stake
    /// @param managerMinimalStake_ Minimal stake required to be a pool manager
    function setManagerMinimalStake(uint256 managerMinimalStake_)
        external
        onlyOwner
    {
        managerMinimalStake = managerMinimalStake_;
        emit ManagerMinimalStakeSet(managerMinimalStake_);
    }

    /// @notice Function is called only by Factory to lock required manager's stake amount
    /// @param account Address whose stake should be locked
    /// @return Staked amount
    function lockStake(address account) external onlyFactory returns (uint256) {
        uint256 availableStake = getAvailableStake(account);
        if (managerMinimalStake > availableStake) {
            _stake(account, managerMinimalStake - availableStake);
        }
        locked[account] += managerMinimalStake;
        emit StakeLocked(account, managerMinimalStake);
        return managerMinimalStake;
    }

    /// @notice Function is called only by Factory to unlock part of some stake
    /// @param staker Address whose stake should be unlocked
    /// @param receiver Address where stake should be transferred
    /// @param amount Amount to unlock
    function unlockAndWithdrawStake(
        address staker,
        address receiver,
        uint256 amount
    ) external onlyFactory {
        locked[staker] -= amount;
        emit StakeUnlocked(staker, amount);
        _unstake(staker, receiver, amount);
    }

    /// @notice Function is called only by Factory to burn manager's stake in case of default
    /// @param account Address whose stake should be burned
    /// @param amount Amount to burn
    function burnStake(address account, uint256 amount) external onlyFactory {
        locked[account] -= amount;
        uint256 currentStake = getCurrentStake(account);
        _writeCheckpoint(account, currentStake - amount);
        rbn.safeTransfer(BURN_ADDRESS, amount);
        emit Burned(account, amount);
    }

    // VIEW FUNCTIONS

    /// @notice Gets available for unlocking part of the stake
    /// @param account The address to get available stake size
    /// @return The available stake size for `account`
    function getAvailableStake(address account) public view returns (uint256) {
        return getCurrentStake(account) - locked[account];
    }

    /// @notice Gets the current stake size for `account`
    /// @param account The address to get stake size
    /// @return The current stake size for `account`
    function getCurrentStake(address account) public view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].stake : 0;
    }

    /// @notice Determine the prior stake size for an account as of a block number
    /// @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    /// @param account The address of the account to check
    /// @param blockNumber The block number to get the stake size at
    /// @return The stake size the account had as of the given block
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "NYD");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].stake;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.stake;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].stake;
    }

    // PRIVATE FUNCTIONS

    /// @notice Internal function that writes new stake checkpoint for some account
    /// @param account The address to write checkpoint for
    /// @param newStake New stake size
    function _writeCheckpoint(address account, uint256 newStake) private {
        uint32 nCheckpoints = numCheckpoints[account];
        if (
            nCheckpoints > 0 &&
            checkpoints[account][nCheckpoints - 1].fromBlock == block.number
        ) {
            checkpoints[account][nCheckpoints - 1].stake = newStake;
        } else {
            checkpoints[account][nCheckpoints] = Checkpoint(
                block.number,
                newStake
            );
            numCheckpoints[account] = nCheckpoints + 1;
        }
    }

    /// @notice Internal function to stake RBN for some account
    /// @param account The address to stake for
    /// @param amount Amount to stake
    function _stake(address account, uint256 amount) private {
        rbn.safeTransferFrom(account, address(this), amount);
        _writeCheckpoint(account, getCurrentStake(account) + amount);
        emit Staked(account, amount);
    }

    /// @notice Internal function to unstake RBN from some account
    /// @param staker The address to unstake from
    /// @param receiver The address where to transfer stake
    /// @param amount Amount to unstake
    function _unstake(
        address staker,
        address receiver,
        uint256 amount
    ) private {
        uint256 currentStake = getCurrentStake(staker);
        require(locked[staker] + amount <= currentStake, "NES");
        _writeCheckpoint(staker, currentStake - amount);
        rbn.safeTransfer(receiver, amount);
        emit Unstaked(staker, amount);
    }

    // MODIFIERS

    /// @notice Modifier for the functions restricted to factory
    modifier onlyFactory() {
        require(msg.sender == factory, "OF");
        _;
    }
}