// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMintable {
    function mint(address _receiver, uint256 _amount) external;
    function mintDao(address _receiver, uint256 _amount, bool community) external;
}

pragma solidity 0.8.4;

/// @notice Vesting contract for Grwth labs - This vesting contract is responsible for
///     distributing assets assigned to Grwth labs by the GRO DAO. This contract can:
///         - Create vesting positions for individual Contributors
///         - Stop a contributors vesting positions, leaving what has already vested as available
///             to be claimed by the contributor, but removes and unvested assets from the position
///         - Claim excess tokens directly, excess tokens being defined as tokens that have been
///             vested globally, but hasnt beens assigned to an contributors vesting position.
contract GROTeamVesting is Ownable {
    using SafeERC20 for IERC20;

    struct TeamPosition {
        uint256 total;
        uint256 withdrawn;
        uint256 startTime;
        uint256 stopTime;
    }

    uint256 internal constant ONE_YEAR_SECONDS = 31556952; // average year (including leap years) in seconds
    uint256 internal constant START_TIME_LOWER_BOUND = 2630000 * 6; // 6 months
    uint256 internal constant VESTING_TIME = ONE_YEAR_SECONDS * 3; // 3 years period
    uint256 internal constant VESTING_CLIFF = ONE_YEAR_SECONDS; // 1 years period
    uint256 public constant PERCENTAGE_DECIMAL_FACTOR = 10000; // BP
    uint256 public immutable QUOTA;
    uint256 public immutable VESTING_START_TIME;

    uint256 public vestingAssets;

    IMintable public distributer;

    mapping(address => uint256) public numberOfContributorPositions;
    mapping(address => mapping(uint256 => TeamPosition)) public contributorPositions;

    event LogNewVest(address indexed contributor, uint256 indexed id, uint256 amount);
    event LogClaimed(address indexed contributor, uint256 indexed id, uint256 amount, uint256 withdrawn, uint256 available);
    event LogWithdrawal(address indexed account, uint256 amount);
    event LogStoppedVesting(address indexed contributor, uint256 indexed id, uint256 unlocked, uint256 available);
    event LogNewDistributer(address indexed distributer);

    constructor(uint256 startTime, uint256 quota) {
        VESTING_START_TIME = startTime;
        QUOTA = quota;
    }

    function setDistributer(address _distributer) external onlyOwner {
        distributer = IMintable(_distributer);
        emit LogNewDistributer(_distributer);
    }

    /// @notice How much of the quota is unlocked, vesting and available
    function globallyUnlocked() public view returns (uint256 unlocked, uint256 vesting, uint256 available) {
        if (block.timestamp > VESTING_START_TIME + VESTING_TIME) {
            unlocked = QUOTA;
        } else if (block.timestamp < VESTING_START_TIME + VESTING_CLIFF) {
            unlocked = vestingAssets;
        } else {
            unlocked = (QUOTA) * (block.timestamp - VESTING_START_TIME) / (VESTING_TIME);
        }
        vesting = vestingAssets;
        available = unlocked - vesting;
    }

    /// @notice Get current vested balance of all positions
    /// @param account Target account
    function vestedBalance(address account) external view returns (uint256 vested, uint256 available) {
        for (uint256 i; i < numberOfContributorPositions[account]; i ++) {
            (uint256 _vested, uint256 _available, , ) = unlockedBalance(account, i);
            vested += _vested;
            available += _available;
        }
    }

    /// @notice Get current vested balance of a positions
    /// @param account Target account
    /// @param id of position
    function positionVestedBalance(address account, uint256 id) external view returns (uint256 vested, uint256 available) {
        (vested, available, , ) = unlockedBalance(account, id);
    }

    /// @notice Creates a vesting position
    /// @param account Account which to add vesting position for
    /// @param startTime when the positon should start
    /// @param amount Amount to add to vesting position
    /// @dev The startstime paramter allows some leeway when creating
    ///     positions for new contributors
    function vest(address account, uint256 startTime, uint256 amount) external onlyOwner {
        require(account != address(0), "vest: !account");
        require(amount > 0, "vest: !amount");
        // 6 months moving windows to backset the vesting position
        if (startTime + START_TIME_LOWER_BOUND < block.timestamp) {
            startTime = block.timestamp - START_TIME_LOWER_BOUND;
        }

        uint256 userPositionId = numberOfContributorPositions[account];
        TeamPosition storage ep = contributorPositions[account][userPositionId];
        numberOfContributorPositions[account] += 1;

        ep.startTime = startTime;
        require((QUOTA - vestingAssets) >= amount, 'vest: not enough assets available');
        ep.total = amount;
        vestingAssets += amount;

        emit LogNewVest(account, userPositionId, amount);
    }

    /// @notice owner can withdraw excess tokens
    /// @param amount amount to be withdrawns
    function withdraw(uint256 amount) external onlyOwner {
        ( , , uint256 available ) = globallyUnlocked();
        require(amount <= available, 'withdraw: not enough assets available');
        
        // Need to accoount for the withdrawn assets, they are no longer available
        //  in the contributor pool
        vestingAssets += amount;
        distributer.mint(msg.sender, amount);
        emit LogWithdrawal(msg.sender, amount);
    }

    /// @notice claim an amount of tokens
    /// @param amount amount to be claimed
    /// @param id of position if applicable
    function claim(uint256 amount, uint256 id) external {

        require(amount > 0, "claim: No amount specified");
        (uint256 unlocked, uint256 available, , ) = unlockedBalance(msg.sender, id);
        require(available >= amount, "claim: Not enough user assets available");

        uint256 _withdrawn = unlocked - available + amount;
        TeamPosition storage ep = contributorPositions[msg.sender][id];
        ep.withdrawn = _withdrawn;
        distributer.mint(msg.sender, amount);
        emit LogClaimed(msg.sender, id, amount, _withdrawn, available - amount);
    }

    /// @notice stops an contributors vesting position
    /// @param contributor contributors account
    /// @param id of position if applicable
    function stopVesting(address contributor, uint256 id) external onlyOwner {
        (uint256 unlocked, uint256 available, uint256 startTime, ) = unlockedBalance(contributor, id);
        TeamPosition storage ep = contributorPositions[contributor][id];
        require(ep.stopTime == 0, "stopVesting: position already stopped");
        vestingAssets -= ep.total - unlocked;
        ep.stopTime = block.timestamp;
        ep.total = unlocked;
        emit LogStoppedVesting(contributor, id, unlocked, available);
    }

    /// @notice see the amount of vested assets the account has accumulated
    /// @param account Account to get vested amount for
    /// @param id of position if applicable
    function unlockedBalance(address account, uint256 id)
        internal
        view
        returns ( uint256, uint256, uint256, uint256 )
    {
        require(id < numberOfContributorPositions[account], "unlockedBalance: position does not exist");
        TeamPosition storage ep = contributorPositions[account][id];
        uint256 startTime = ep.startTime;
        if (block.timestamp < startTime + VESTING_CLIFF) {
            return (0, 0, startTime, startTime + VESTING_TIME);
        }
        uint256 unlocked;
        uint256 available;
        uint256 stopTime = ep.stopTime;
        uint256 _endTime = startTime + VESTING_TIME;
        uint256 total = ep.total;
        if (stopTime > 0) {
            unlocked = total;
            _endTime = stopTime;
        } else if (block.timestamp < _endTime) {
            unlocked = total * (block.timestamp - startTime) / (VESTING_TIME);
        } else {
            unlocked = total;
        }
        available = unlocked - ep.withdrawn;
        return (unlocked, available, startTime, _endTime);
    }

    /// @notice Get total size of all user positions, vested + vesting
    /// @param account target account
    function totalBalance(address account) external view returns (uint256 balance) {
        for (uint256 i; i < numberOfContributorPositions[account]; i ++) {
            balance += contributorPositions[account][i].total;
        }
    }

    /// @notice Get total size of a position, vested + vesting
    /// @param account target account
    /// @param id of position
    function positionBalance(address account, uint256 id) external view returns (uint256 balance) {
        TeamPosition storage ep = contributorPositions[account][id];
        balance = ep.total;
    }
}