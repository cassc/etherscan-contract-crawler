// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title SymbiosisTokenVesting
 *
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 * There are 3 types of vesting schedule: CONTINUOUS, MONTHLY (every 30 days), QUARTERLY (every 90 days).
 */
contract SymbiosisTokenVesting is Ownable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeERC20 for IERC20;

    event ReservedAdded(address indexed beneficiary, uint256 reserved);
    event TokensReleased(
        address indexed beneficiary,
        address indexed transferredTo,
        uint256 amount
    );
    event TokensWithdrawnByOwner(address indexed token, uint256 amount);

    // 100% in basis points
    uint256 public constant MAX_BPS = 10000;

    // private VestingSchedule time constants
    uint256 private constant MONTHLY_TIME = 30 days;
    uint256 private constant QUARTERLY_TIME = 90 days;

    // SymbiosisTokenVesting name
    string public name;

    // ERC20 token which is being vested
    IERC20 public token;

    // staking contract address
    address public stakingAddress;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 public cliff; // the cliff time of the token vesting
    uint256 public start; // the start time of the token vesting
    uint256 public duration; // the duration of the token vesting

    // type of the token vesting
    enum VestingSchedule {
        CONTINUOUS,
        MONTHLY,
        QUARTERLY
    }
    VestingSchedule public immutable schedule;

    // basis points of the initial unlock – after the start and before the end of the cliff period
    uint256 public immutable cliffUnlockedBP;

    // total reserved tokens for beneficiaries
    uint256 public reserved;

    // reserved tokens to beneficiary
    mapping(address => uint256) public reservedForBeneficiary;

    // frozen amount for staking
    mapping(address => uint256) public frozenForStakeAmount;

    // total released (transferred) tokens
    uint256 public released;

    // released (transferred) tokens to beneficiary
    mapping(address => uint256) public releasedToBeneficiary;

    // array of beneficiaries for getters
    address[] internal beneficiaries;

    /**
     * @dev Creates a vesting contract that vests its balance of specific ERC20 token to the
     * beneficiaries, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param _token ERC20 token which is being vested
     * @param _cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param _cliffUnlockedBP basis points of initial unlock – after the start and before the end of the cliff period
     * @param _start the time (as Unix time) at which point vesting starts
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _schedule type of the token vesting: CONTINUOUS, MONTHLY, QUARTERLY
     * @param _name SymbiosisTokenVesting name
     */
    constructor(
        IERC20 _token,
        uint256 _start,
        uint256 _cliffDuration,
        uint256 _cliffUnlockedBP,
        uint256 _duration,
        VestingSchedule _schedule,
        string memory _name
    ) {
        require(
            address(_token) != address(0),
            "SymbiosisTokenVesting: token is the zero address"
        );
        require(_duration > 0, "SymbiosisTokenVesting: duration is 0");

        require(
            _cliffDuration <= _duration,
            "SymbiosisTokenVesting: cliff is longer than duration"
        );

        require(
            _start + _duration > block.timestamp,
            "SymbiosisTokenVesting: final time is before current time"
        );

        require(
            _cliffUnlockedBP <= MAX_BPS,
            "SymbiosisTokenVesting: invalid cliff unlocked BP"
        );

        token = _token;
        duration = _duration;
        cliff = _start + _cliffDuration;
        start = _start;
        schedule = _schedule;
        name = _name;

        cliffUnlockedBP = _cliffUnlockedBP;
    }

    modifier onlyStaking() {
        require(
            msg.sender == stakingAddress,
            "SymbiosisTokenVesting: caller is not the staking address"
        );
        _;
    }

    function setStakingAddress(address _stakingAddress) external onlyOwner {
        stakingAddress = _stakingAddress;
    }

    /**
     * @notice Calculates the total amount of vested tokens.
     */
    function totalVested() public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        return currentBalance + released;
    }

    /**
     * @notice Calculates the amount that has already vested but hasn't been released yet.
     * @param _beneficiary Address of vested tokens beneficiary
     */
    function releasableAmount(address _beneficiary)
        public
        view
        returns (uint256)
    {
        uint256 releasable = _vestedAmount(_beneficiary) - releasedToBeneficiary[_beneficiary];
        uint256 frozen = frozenForStakeAmount[_beneficiary];
        return (releasable > frozen) ? (releasable - frozen) : 0;
    }

    /**
     * @notice Get a beneficiary address with current index.
     */
    function getBeneficiary(uint256 index) external view returns (address) {
        return beneficiaries[index];
    }

    /**
     * @notice Get an array of beneficiary addresses.
     */
    function getBeneficiaries() external view returns (address[] memory) {
        return beneficiaries;
    }

    /**
     * @notice Adds beneficiaries to SymbiosisTokenVesting by owner.
     *
     * Requirements:
     * - can only be called by owner.
     *
     * @param _beneficiaries Addresses of beneficiaries
     * @param _amounts Amounts of tokens reserved for beneficiaries
     */
    function addBeneficiaries(
        address[] memory _beneficiaries,
        uint256[] memory _amounts
    ) external onlyOwner {
        uint256 len = _beneficiaries.length;
        require(len == _amounts.length, "SymbiosisTokenVesting: Array lengths do not match");

        uint256 amountToBeneficiaries = 0;
        for (uint256 i = 0; i < len; i++) {
            amountToBeneficiaries = amountToBeneficiaries + _amounts[i];

            // add new beneficiary to array
            if (reservedForBeneficiary[_beneficiaries[i]] == 0) {
                beneficiaries.push(_beneficiaries[i]);
            }

            reservedForBeneficiary[_beneficiaries[i]] =
                reservedForBeneficiary[_beneficiaries[i]] +
                _amounts[i];

            emit ReservedAdded(_beneficiaries[i], _amounts[i]);
        }

        reserved = reserved + amountToBeneficiaries;

        // check reserved condition
        require(
            reserved <= totalVested(),
            "SymbiosisTokenVesting: reserved exceeds totalVested"
        );
    }

    /**
     * @notice Withdraws ERC20 token funds by owner (except vested token).
     *
     * Requirements:
     * - can only be called by owner.
     *
     * @param _token Token address (except vested token)
     * @param _amount The amount of token to withdraw
     **/
    function withdrawFunds(IERC20 _token, uint256 _amount) external onlyOwner {
        require(
            _token != token,
            "SymbiosisTokenVesting: vested token is not available for withdrawal"
        );
        _token.safeTransfer(msg.sender, _amount);
        emit TokensWithdrawnByOwner(address(_token), _amount);
    }

    /**
     * @notice Withdraws ERC20 vested token by owner.
     *
     * Requirements:
     * - can only be called by owner.
     *
     * @param _amount The amount of token to withdraw
     **/
    function emergencyWithdraw(uint256 _amount) external onlyOwner {
        require(
            block.timestamp < start,
            "SymbiosisTokenVesting: vesting has already started"
        );
        token.safeTransfer(msg.sender, _amount);
        emit TokensWithdrawnByOwner(address(token), _amount);
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param _beneficiary Address of vested tokens beneficiary
     */
    function release(address _beneficiary) external {
        _release(_beneficiary, _beneficiary);
    }

    /**
     * @notice Transfers vested tokens of sender to specified address.
     * @param _transferTo Address to which tokens are transferred
     */
    function releaseToAddress(address _transferTo) external {
        _release(msg.sender, _transferTo);
    }

    function allocateStake(address _beneficiary, uint256 _amount)
        external
        onlyStaking
        returns (bool)
    {
        require(
            reservedForBeneficiary[_beneficiary] - releasedToBeneficiary[_beneficiary] >= _amount,
            "SymbiosisTokenVesting: allocation amount exceeds balance"
        );
        frozenForStakeAmount[_beneficiary] += _amount;

        return true;
    }

    function unlockStake(address _beneficiary, uint256 _amount)
        external
        onlyStaking
        returns (bool)
    {
        require(
            _amount <= frozenForStakeAmount[_beneficiary],
            "SymbiosisTokenVesting: amount exceeds frozen amount for this beneficiary"
        );
        frozenForStakeAmount[_beneficiary] -= _amount;

        return true;
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param _beneficiary Address of vested tokens beneficiary
     */
    function _vestedAmount(address _beneficiary)
        private
        view
        returns (uint256)
    {
        uint256 curTimestamp = block.timestamp;

        if (curTimestamp < start) {
            return 0;
        } else if (curTimestamp < cliff) {
            return reservedForBeneficiary[_beneficiary] * cliffUnlockedBP / MAX_BPS;
        } else if (curTimestamp >= start + duration) {
            return reservedForBeneficiary[_beneficiary];
        } else {
            return
                reservedForBeneficiary[_beneficiary] * cliffUnlockedBP / MAX_BPS +
                reservedForBeneficiary[_beneficiary] * (MAX_BPS - cliffUnlockedBP) * _vestedPeriod() / (duration - (cliff - start)) / MAX_BPS;
        }
    }

    /**
     * @dev Calculates the duration of period that is already unlocked according to VestingSchedule type.
     */
    function _vestedPeriod() private view returns (uint256 period) {
        period = block.timestamp - cliff; // CONTINUOUS from cliff

        if (schedule == VestingSchedule.MONTHLY) {
            period = period - (period % MONTHLY_TIME);
        } else if (schedule == VestingSchedule.QUARTERLY) {
            period = period - (period % QUARTERLY_TIME);
        }
    }

    /**
     * @dev Transfers vested tokens.
     * @param _beneficiary Address of vested tokens beneficiary
     * @param _transferTo Address to which tokens are transferred
     */
    function _release(address _beneficiary, address _transferTo) private {
        uint256 unreleased = releasableAmount(_beneficiary);

        require(unreleased > 0, "SymbiosisTokenVesting: no tokens are due");

        releasedToBeneficiary[_beneficiary] =
            releasedToBeneficiary[_beneficiary] +
            unreleased;
        released = released + unreleased;

        token.safeTransfer(_transferTo, unreleased);

        emit TokensReleased(_beneficiary, _transferTo, unreleased);
    }
}