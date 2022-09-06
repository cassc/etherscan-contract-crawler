// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity = 0.8.12;

// Inheritance
import "./CustomOwnable.sol";
import "./interfaces/IERC20.sol";

contract Escrow is CustomOwnable {

    /* The escrow token. */
    address public token;
    mapping(address => uint256) private allAccounts;
    mapping(uint256 => address) private accountMapperCounter;
    uint256 public accountsCount;

    uint8 private constant MAX_ACCOUNTS_COUNT = 200;
    uint8 private constant PERCENT_DISTRIBUTION_PER_MONTH = 20;
    uint8 private constant DENOMINATOR = 100;
    uint8 private constant MAX_TIMES_LENGTH = 5;

    /* An account's total vested balance to save recomputing this for fee extraction purposes. */
    mapping(address => uint256) private totalVestedAccountBalance;

    //amount per distribution user
    mapping(address => uint256) private singleDistributionAmount;

    mapping(uint256 => uint256) private vestingSchedules;
    mapping(uint256 => uint256) private VestingSchedulesRemained;
    uint256 public countSchedules;

    /* The total remaining vested balance, for verifying the actual balance of this contract against. */
    uint256 private totalVestedBalance;

    /* ========== CONSTRUCTOR ========== */
    constructor(address _token, uint[] memory _times) {
        require(_times.length == MAX_TIMES_LENGTH, 'Not equal to 5 times');
        require(block.timestamp < _times[0], 'Timestamp in past');
        require(_token != address(0), 'Token can not be zero address');

        token = _token;
        for (uint8 i = 0; i < _times.length; i++) {
            if (i < _times.length - 1) {
                require(_times[i] < _times[i + 1], 'Not lower then next timestamp');
            }

            vestingSchedules[i] = _times[i];
            VestingSchedulesRemained[i] = _times[i];
        }

        countSchedules = _times.length;
    }
    /* ========== VIEW FUNCTIONS ========== */
    /**
     * @notice A simple alias to totalVestedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account) external view returns (uint256) {
        return totalVestedAccountBalance[account];
    }

    function getTotalVestedBalance() external view returns (uint256) {
        return totalVestedBalance;
    }

    function getVestingSchedule(uint256 index) external view returns (uint256) {
        return vestingSchedules[index];
    }

    function getNextVestingTime() external view returns (uint256) {

        for (uint256 i = 0; i <= countSchedules; i++) {
            if(VestingSchedulesRemained[i] != 0) {
                return VestingSchedulesRemained[i];
            }
        }

        return 0;
    }

    function getSingleDistributionAmount(address account) public view returns (uint256) {
        return singleDistributionAmount[account];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /**
     * @notice Destroy the vesting information associated with an account.
     */
    function purgeAccount(address account) external onlyOwner {
        uint256 indexAccount = allAccounts[account];
        require(accountMapperCounter[indexAccount] != address(0), 'Already deleted user');
        delete allAccounts[account];
        delete accountMapperCounter[indexAccount];
        totalVestedBalance = totalVestedBalance - totalVestedAccountBalance[account];
        delete singleDistributionAmount[account];
        delete totalVestedAccountBalance[account];

        emit PurgeAccount(account);
    }

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @dev A call to this should be accompanied by either enough balance already available
     * in this contract, or a corresponding call to.endow(), to ensure that when
     * the funds are withdrawn, there is enough balance, as well as correctly calculating
     * the fees.
     * This may only be called by the owner during the contract's setup period.
     * Note; although this function could technically be used to produce unbounded
     * arrays, it's only in the foundation's command to add to these lists.
     * @param account The account to append a new vesting entry to.
     * @param quantity The quantity of WBT that will vest.
     */
    function appendVestingEntry (
        address account,
        uint256 quantity
    ) public onlyOwner {
        /* No empty or already-passed vesting entries allowed. */
        require(quantity != 0, "Quantity cannot be zero");
        require(totalVestedAccountBalance[account] == 0, 'Account already exist');
        require(account != address(0), 'Can not be zero address');
        require(accountsCount < MAX_ACCOUNTS_COUNT, 'Reached max account count');
        require(block.timestamp < vestingSchedules[0], 'Can not be added user after first vesting distributed');
        /* There must be enough balance in the contract to provide for the vesting entry. */
        totalVestedBalance = totalVestedBalance + quantity;
        totalVestedAccountBalance[account] = quantity;

        uint256 amountDistribution = (totalVestedAccountBalance[account] * PERCENT_DISTRIBUTION_PER_MONTH) / DENOMINATOR;
        singleDistributionAmount[account] = amountDistribution;
        accountsCount++;
        allAccounts[account] = accountsCount;
        accountMapperCounter[accountsCount] = account;
        require(
            totalVestedBalance <= IERC20(token).balanceOf(address(this)),
            "Must be enough balance in the contract to provide for the vesting entry"
        );

        emit AppendVestingEntry(account, quantity);
    }

    /**
     * @notice Construct a vesting schedule to release a quantities of WBT
     * over a series of intervals.
     * @dev Assumes that the quantities are nonzero
     * and that the sequence of timestamps is strictly increasing.
     * This may only be called by the owner during the contract's setup period.
     */
    function addVestingEntry(
        address[] calldata account,
        uint[] memory quantities
    ) external onlyOwner {
        require(account.length == quantities.length, 'Not the same count of elements');

        for (uint256 i = 0; i < account.length; i++) {
            appendVestingEntry(account[i], quantities[i]);
        }
    }

    function vest() external onlyOwner {
        for(uint256 i = 0; i < countSchedules; i++){

            if (block.timestamp < VestingSchedulesRemained[i]) {
                break;
            }

            if (VestingSchedulesRemained[i] == 0) {
                continue;
            }

            uint256 _totalVestedBalance = totalVestedBalance;

            for (uint256 j = 1; j <= accountsCount; j++) {
                address account = accountMapperCounter[j];

                if (account == address(0)) {
                    continue;
                }

                uint amount = getSingleDistributionAmount(account);
                totalVestedAccountBalance[account] = totalVestedAccountBalance[account] - amount;

                _totalVestedBalance = _totalVestedBalance - amount;
                require(IERC20(token).transfer(account, amount), 'Failed transfer from contract');
                emit Vested(account, block.timestamp, amount);
            }

            totalVestedBalance = _totalVestedBalance;

            delete VestingSchedulesRemained[i];
        }
    }

    function withdrawal() external onlyOwner returns(bool) {
        uint256 extraFunds = IERC20(token).balanceOf(address(this)) - totalVestedBalance;
        require(extraFunds > 0, 'Not greater then zero');

        require(IERC20(token).transfer(owner(), extraFunds), 'failed transfer from contract');

        return true;
    }

    /* ========== EVENTS ========== */
    event Vested(address indexed beneficiary, uint256 time, uint256 value);
    event AppendVestingEntry(address indexed account, uint256 quantity);
    event PurgeAccount(address indexed deletedAccount);
}