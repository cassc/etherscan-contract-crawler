// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interface/ITokenVesting.sol";
import "./Token.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Vesting to manage tokens between addresses and destinations.
 */
contract Vesting is AccessControl, ITokenVesting, ReentrancyGuard {
    using SafeERC20 for Token;
    using Math for uint256;

    enum Direction {
        PUBLIC_ROUND,
        SEED_ROUND,
        PRIVATE_ROUND_ONE,
        PRIVATE_ROUND_TWO,
        MARKETING,
        TEAM,
        FOUNDATION
    }

    struct VestingSchedule {
        uint128 cliffAt; // The date while token locks.
        uint128 startAt; // The start date of vesting.
        uint128 durationInSeconds; // The duration of vesting in seconds.
        uint8 earlyUnlockPercent; // The unlock percent of tokens which available after cliff.
        uint256 totalAmount; // The amount of vesting token.
        uint256 released; // The amount of vesting token which was claimed.
        uint256 earlyUnlockAmount; // The unlock amount of tokens which available after cliff.
    }

    error TotalAmountExceeded();
    error DataLengthsNotMatch();
    error FoundersShouldBeThree();
    error TotalPercentNotHundred();
    error TeamMaxAmountGreaterThanFiftyPercent();
    error NotEnoughFunds();
    error ClaimAmountIsZero();
    error InsufficientTokens();
    error IncorrectAmount();
    error DurationIsZero();
    error ZeroAddress();
    error NotStarted();

    /**
     * @notice Multisig role allows account to call functions with multi-signature only.
     */
    bytes32 public constant MULTISIG_ROLE = keccak256("MULTISIG_ROLE");

    /**
     * @notice Starter role allows account to start vesting.
     */
    bytes32 public constant STARTER_ROLE = keccak256("STARTER_ROLE");

    /**
     * @notice The number of destinations that participate in the vesting.
     */
    uint8 public constant DIRECTION_COUNT = 7;

    /**
     * @notice The number of addresses to be added.
     */
    uint8 public constant MAIN_TEAM_REQUIRED_COUNT = 3;

    /**
     * @notice The max amount of tokens that can be distributed between accounts
     * in the direction of rounds: Public, Seed, Private One, Private Two.
     */
    uint256 public constant MAX_ROUNDS_AMOUNT = 240000000e18;

    /**
     * @notice The max amount of tokens that can be distributed between
     * accounts in the direction of Marketing.
     */
    uint256 public constant MAX_MARKETING_AMOUNT = 160000000e18;

    /**
     * @notice The max amount of tokens that can be distributed between
     * accounts in the direction of Team.
     */
    uint256 public constant MAX_TEAM_AMOUNT = 120000000e18;

    /**
     * @notice The max amount of tokens that can be distributed between
     * accounts in the direction of Foundation.
     */
    uint256 public constant MAX_FOUNDATION_AMOUNT = 80000000e18;

    /**
     * @notice Token for distribution.
     */
    Token public immutable token;

    /**
     * @notice Start date of vesting.
     */
    uint128 public startAt;

    /**
     * @notice The total amount of tokens which was distributed between accounts
     * in the direction of Marketing.
     */
    uint256 public marketingTotalAmount;

    /**
     * @notice The total amount of tokens which was distributed between accounts
     * in the direction of Team. Additional team are users which was added by main team.
     */
    uint256 public additionalTeamTotalAmount;

    /**
     * @notice The total amount of tokens which was distributed between accounts
     * in the direction of Team. Main team are 3 users which was added by admin.
     */
    uint256 public mainTeamTotalAmount;

    /**
     * @notice The total amount of tokens which was distributed between accounts
     * in the direction of Foundation.
     */
    uint256 public foundationTotalAmount;

    /**
     * @notice The total amount of tokens at the addresses that are in the vesting.
     */
    uint256 public vestingSchedulesTotalAmount;

    // Mapping of percentages for each address in main team.
    mapping(address => uint256) public mainTeamPercent;

    // Mapping by vesting schedule for a specific address and direction.
    mapping(address => mapping(uint8 => VestingSchedule))
        public vestingSchedules;

    // Array of 3 users which was added by admin. Only main team can add additional team.
    address[] public mainTeam;

    /**
     * @notice Emitted when user claimed tokens.
     * @param account The user address.
     * @param amount The amount of vesting token.
     */
    event Claimed(address indexed account, uint256 amount);

    /**
     * @notice Emitted when admin created vesting schedules for the user.
     * @param account The user address.
     * @param amount The amount of vesting token.
     * @param startAt The start date of vesting.
     */
    event VestingCreated(
        address indexed account,
        uint256 amount,
        uint128 startAt
    );

    /**
     * @notice Emitted when admin created vesting schedules for users.
     * @param accounts The array of users.
     * @param amounts The array of amounts.
     * @param startAt The start date of vesting.
     */
    event BatchVestingCreated(
        address[] indexed accounts,
        uint256[] amounts,
        uint128 startAt
    );

    constructor(
        address token_,
        address multisig_,
        address admin_
    ) {
        token = Token(token_);

        // Grants role to 'admin_'.
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        // Grants role to 'multisig_'.
        _grantRole(MULTISIG_ROLE, multisig_);
        // Grants role to 'token_'.
        _grantRole(STARTER_ROLE, token_);
    }

    /**
     * @inheritdoc ITokenVesting
     */
    function setStartAt() external onlyRole(STARTER_ROLE) {
        startAt = uint128(block.timestamp);
    }

    /**
     * @notice Sets public round vest for user.
     * @param _accounts The array of users.
     * @param _amounts The array of amounts.
     */
    function setPublicRoundVestFor(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint128 startDate = startAt;

        _batchVestFor(
            _accounts,
            _amounts,
            startDate,
            0,
            180 days,
            10,
            uint8(Direction.PUBLIC_ROUND)
        );
    }

    /**
     * @notice Sets seed round vest for user.
     * @param _accounts The array of users.
     * @param _amounts The array of amounts.
     */
    function setSeedRoundVestFor(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint128 startDate = startAt;

        _batchVestFor(
            _accounts,
            _amounts,
            startDate,
            360 days,
            960 days,
            0,
            uint8(Direction.SEED_ROUND)
        );
    }

    /**
     * @notice Sets private round one vest for user.
     * @param _accounts The array of users.
     * @param _amounts The array of amounts.
     */
    function setPrivateRoundOneVestFor(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint128 startDate = startAt;

        _batchVestFor(
            _accounts,
            _amounts,
            startDate,
            180 days,
            720 days,
            10,
            uint8(Direction.PRIVATE_ROUND_ONE)
        );
    }

    /**
     * @notice Sets private round two vest for user.
     * @param _accounts The array of users.
     * @param _amounts The array of amounts.
     */
    function setPrivateRoundTwoVestFor(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint128 startDate = startAt;

        _batchVestFor(
            _accounts,
            _amounts,
            startDate,
            180 days,
            720 days,
            10,
            uint8(Direction.PRIVATE_ROUND_TWO)
        );
    }

    /**
     * @notice Sets marketing vest for user.
     * @param _account The user address.
     * @param _amount The amount of vesting token.
     * @param _cliff The duration in seconds when token locks.
     * @param _duration The duration of vesting in seconds.
     */
    function setMarketingVestFor(
        address _account,
        uint256 _amount,
        uint128 _cliff,
        uint128 _duration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint128 startDate = uint128(block.timestamp);

        _vestFor(
            _account,
            _amount,
            startDate,
            _cliff,
            _duration,
            2,
            uint8(Direction.MARKETING)
        );

        uint256 marketingAmount = marketingTotalAmount;

        if (marketingAmount + _amount > MAX_MARKETING_AMOUNT) {
            revert TotalAmountExceeded();
        }

        marketingTotalAmount = marketingAmount + _amount;

        emit VestingCreated(_account, _amount, startDate);
    }

    /**
     * @notice Sets main team vest for user.
     * @param _accounts The array of users.
     * @param _amounts The array of amounts.
     * @param _percents The array of percents.
     */
    function setMainTeamVestFor(
        address[] calldata _accounts,
        uint256[] calldata _amounts,
        uint8[] calldata _percents
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint8 accountsCount = uint8(_accounts.length);

        if (
            accountsCount != _amounts.length ||
            accountsCount != _percents.length
        ) {
            revert DataLengthsNotMatch();
        }

        if (mainTeam.length + accountsCount != MAIN_TEAM_REQUIRED_COUNT) {
            revert FoundersShouldBeThree();
        }

        uint128 startDate = startAt;
        uint8 totalPercent;
        uint256 totalAmount;

        for (uint8 i = 0; i < accountsCount; i++) {
            address account = _accounts[i];
            uint8 percent = _percents[i];
            uint256 amount = _amounts[i];

            _vestFor(
                account,
                amount,
                startDate,
                120 days,
                720 days,
                0,
                uint8(Direction.TEAM)
            );

            totalAmount += amount;
            totalPercent += percent;
            mainTeamPercent[account] = percent;
        }

        mainTeam = _accounts;

        if (totalPercent != 100) {
            revert TotalPercentNotHundred();
        }

        if (totalAmount > MAX_TEAM_AMOUNT) {
            revert TotalAmountExceeded();
        }

        mainTeamTotalAmount = totalAmount;

        emit BatchVestingCreated(_accounts, _amounts, startDate);
    }

    /**
     * @notice Sets additional team vest for user.
     * @param _accounts The array of users.
     * @param _amounts The array of amounts.
     */
    function setAdditionalTeamVestFor(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external onlyRole(MULTISIG_ROLE) {
        uint16 accountsCount = uint16(_accounts.length);
        uint8 mainTeamCount = uint8(mainTeam.length);

        if (accountsCount != _amounts.length) {
            revert DataLengthsNotMatch();
        }

        if (mainTeamCount != MAIN_TEAM_REQUIRED_COUNT) {
            revert FoundersShouldBeThree();
        }

        uint128 startDate = startAt;
        uint256 totalAmount;

        for (uint16 i = 0; i < accountsCount; i++) {
            uint256 amount = _amounts[i];

            totalAmount += amount;

            _vestFor(
                _accounts[i],
                amount,
                startDate,
                120 days,
                720 days,
                0,
                uint8(Direction.TEAM)
            );
        }

        uint256 additionalTeamAmount = additionalTeamTotalAmount;

        if (
            (additionalTeamAmount + totalAmount * 100) / mainTeamTotalAmount >
            50
        ) {
            revert TeamMaxAmountGreaterThanFiftyPercent();
        }

        additionalTeamTotalAmount = additionalTeamAmount + totalAmount;

        for (uint16 i = 0; i < mainTeamCount; i++) {
            address founder = mainTeam[i];
            // After adding a new user to the team, the total amount of
            // founder tokens in the team decreases according to their percentage.
            vestingSchedules[founder][uint8(Direction.TEAM)].totalAmount -=
                (totalAmount * mainTeamPercent[founder]) /
                100;
        }

        emit BatchVestingCreated(_accounts, _amounts, startDate);
    }

    /**
     * @notice Sets foundation vest for user.
     * @param _accounts The array of users.
     * @param _amounts The array of amounts.
     */
    function setFoundationVestFor(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint128 startDate = startAt;

        uint256 totalAmount = _batchVestFor(
            _accounts,
            _amounts,
            startDate,
            0,
            570 days,
            5,
            uint8(Direction.FOUNDATION)
        );

        uint256 foundationAmount = foundationTotalAmount;

        if (foundationAmount + totalAmount > MAX_FOUNDATION_AMOUNT) {
            revert TotalAmountExceeded();
        }

        foundationTotalAmount = foundationAmount + totalAmount;
    }

    /**
     * @notice Gives available amount of tokens.
     */
    function claim() external {
        uint256 totalVestedAmount = 0;

        for (uint8 i = 0; i < DIRECTION_COUNT; i++) {
            VestingSchedule memory schedule = vestingSchedules[msg.sender][i];
            // Returns the available amount of tokens from one of the directions.
            uint256 vestedAmount = _vestedAmount(schedule);

            if (vestedAmount > 0) {
                // Increases released amount in vesting.
                vestingSchedules[msg.sender][i].released =
                    vestedAmount +
                    schedule.released;
            }

            totalVestedAmount += vestedAmount;
        }

        if (totalVestedAmount == 0) {
            revert ClaimAmountIsZero();
        }

        // Current amount of tokens in vesting.
        vestingSchedulesTotalAmount -= totalVestedAmount;

        token.safeTransfer(msg.sender, totalVestedAmount);

        emit Claimed(msg.sender, totalVestedAmount);
    }

    /**
     * @notice Returns available amount of tokens.
     * @param _account The user address.
     */
    function getVestedAmount(address _account)
        external
        view
        returns (uint256 totalVestedAmount)
    {
        for (uint8 i = 0; i < DIRECTION_COUNT; i++) {
            // Returns the available amount of tokens from one of the directions.
            uint256 vestedAmount = _vestedAmount(vestingSchedules[_account][i]);

            totalVestedAmount += vestedAmount;
        }
    }

    /**
     * @notice Withdraws available amount of tokens in the contract.
     * @param _amount The amount of tokens.
     */
    function withdraw(uint256 _amount)
        public
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (getWithdrawableAmount() < _amount) {
            revert NotEnoughFunds();
        }

        token.safeTransfer(msg.sender, _amount);
    }

    /**
     * @notice Returns withdrawable amount of tokens which is available.
     */
    function getWithdrawableAmount() public view returns (uint256) {
        return token.balanceOf(address(this)) - vestingSchedulesTotalAmount;
    }

    /**
     * @notice Creates vesting schedules for user.
     * @param _account The user address.
     * @param _amount The amount of vesting token.
     * @param _startAt The start date of vesting.
     * @param _cliff The duration in seconds when token locks.
     * @param _duration The duration of vesting in seconds.
     * @param _unlockPercent The unlock percent of tokens which available after cliff.
     * @param _direction The direction of vesting.
     */
    function _vestFor(
        address _account,
        uint256 _amount,
        uint128 _startAt,
        uint128 _cliff,
        uint128 _duration,
        uint8 _unlockPercent,
        uint8 _direction
    ) private {
        if (getWithdrawableAmount() < _amount) {
            revert InsufficientTokens();
        }
        if (_amount == 0) {
            revert IncorrectAmount();
        }
        if (_duration == 0) {
            revert DurationIsZero();
        }
        if (_account == address(0)) {
            revert ZeroAddress();
        }
        if (_startAt == 0) {
            revert NotStarted();
        }

        // Current amount of tokens in vesting.
        vestingSchedulesTotalAmount += _amount;
        // Returns cliff date.
        uint128 cliff = _startAt + _cliff;
        // Unlock amount can claim after cliff in any day.
        uint256 unlockAmount = (_amount * _unlockPercent) / 100;

        vestingSchedules[_account][_direction] = VestingSchedule(
            cliff,
            _startAt,
            _duration,
            _unlockPercent,
            _amount,
            0,
            unlockAmount
        );
    }

    /**
     * @notice Creates vesting schedules for users.
     * @param _accounts The array of users.
     * @param _amounts The array of amounts.
     * @param _startAt The start date of vesting.
     * @param _cliff The duration in seconds when token locks.
     * @param _duration The duration of vesting in seconds.
     * @param _unlockPercent The unlock percent of tokens which available after cliff.
     * @param _direction The direction of vesting.
     */
    function _batchVestFor(
        address[] calldata _accounts,
        uint256[] calldata _amounts,
        uint128 _startAt,
        uint128 _cliff,
        uint128 _duration,
        uint8 _unlockPercent,
        uint8 _direction
    ) private returns (uint256 totalAmount) {
        uint16 accountsCount = uint16(_accounts.length);

        if (accountsCount != _amounts.length) {
            revert DataLengthsNotMatch();
        }

        for (uint16 i = 0; i < accountsCount; i++) {
            _vestFor(
                _accounts[i],
                _amounts[i],
                _startAt,
                _cliff,
                _duration,
                _unlockPercent,
                _direction
            );

            totalAmount += _amounts[i];
        }

        emit BatchVestingCreated(_accounts, _amounts, _startAt);
    }

    /**
     * @notice Returns available amount of tokens.
     * @param _vestingSchedule The vesting schedule structure.
     */
    function _vestedAmount(VestingSchedule memory _vestingSchedule)
        private
        view
        returns (uint256)
    {
        if (_vestingSchedule.totalAmount == 0) {
            return 0;
        }

        uint128 currentTime = uint128(block.timestamp);

        // Claims after cliff.
        if (currentTime < _vestingSchedule.cliffAt) {
            return 0;
        }

        // Duration in seconds from starting vesting.
        uint128 timeFromStart = currentTime - _vestingSchedule.startAt;

        // After ending vesting user can claim in any day.
        if (timeFromStart >= _vestingSchedule.durationInSeconds) {
            return _vestingSchedule.totalAmount - _vestingSchedule.released;
        }

        uint256 released = _vestingSchedule.released;
        // Returns true if the user tries to claim every 30 days.
        bool isPayOutDay = (timeFromStart / 86400) % 30 == 0;

        // Once a month, the user can claim tokens, except when the user has the amount to unlock early.
        // !payout day, but user can have early unlock amount.
        if (!isPayOutDay && released == 0) {
            return _vestingSchedule.earlyUnlockAmount;
        }

        // !payout day and user has already got early unlock amount.
        if (!isPayOutDay && released > 0) {
            return 0;
        }

        // Payout day and released amount is 0.
        if (released == 0) {
            return
                _vestingSchedule.earlyUnlockAmount +
                (_vestingSchedule.totalAmount * timeFromStart) /
                _vestingSchedule.durationInSeconds;
        } else {
            // Released amount without early unlock amount.
            uint256 vestedAmountForPeriod = (_vestingSchedule.totalAmount *
                timeFromStart) /
                _vestingSchedule.durationInSeconds -
                (released - _vestingSchedule.earlyUnlockAmount);

            // Released with current vested amount shouldn't be bigger total amount of vesting.
            assert(
                released + vestedAmountForPeriod <= _vestingSchedule.totalAmount
            );

            return vestedAmountForPeriod;
        }
    }
}