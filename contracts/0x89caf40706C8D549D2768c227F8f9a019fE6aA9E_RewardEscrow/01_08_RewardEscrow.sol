pragma solidity 0.5.12;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";


/**
 * @title SharesTimelock interface
 */
interface ISharesTimeLock {
    function depositByMonths(uint256 amount, uint256 months, address receiver) external;
}


/**
 * @title DoughEscrow interface
 */
interface IDoughEscrow {
    function balanceOf(address account) external view returns (uint);
    function appendVestingEntry(address account, uint quantity) external;
}

interface IBuyback {
    function buyback(uint256 _tokenInQty, address _receiver) external returns (bool success);
    function maxAvailableToBuy() external view returns (uint available);     
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       RewardEscrow.sol
version:    1.1
author:     Jackson Chan
            Clinton Ennis

date:       2019-03-01

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------
Escrows the DOUGH rewards from the inflationary supply awarded to
users for staking their DOUGH and maintaining the c-rationn target.

SNW rewards are escrowed for 1 year from the claim date and users
can call vest in 12 months time.
-----------------------------------------------------------------
*/


/**
 * @title A contract to hold escrowed DOUGH and free them at given schedules.
 */
contract RewardEscrow is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public dough;

    mapping(address => bool) public isRewardContract;

    /* Lists of (timestamp, quantity) pairs per account, sorted in ascending time order.
     * These are the times at which each given quantity of DOUGH vests. */
    mapping(address => uint[2][]) public vestingSchedules;

    /* An account's total escrowed dough balance to save recomputing this for fee extraction purposes. */
    mapping(address => uint) public totalEscrowedAccountBalance;

    /* An account's total vested reward dough. */
    mapping(address => uint) public totalVestedAccountBalance;

    /* The total remaining escrowed balance, for verifying the actual dough balance of this contract against. */
    uint public totalEscrowedBalance;

    uint constant TIME_INDEX = 0;
    uint constant QUANTITY_INDEX = 1;

    /* Limit vesting entries to disallow unbounded iteration over vesting schedules.
    * There are 5 years of the supply scedule */
    uint constant public MAX_VESTING_ENTRIES = 52*5;

    uint8 public constant decimals = 18;
    string public name;
    string public symbol;

    uint256 public constant STAKE_DURATION = 36;
    ISharesTimeLock public sharesTimeLock;

    /* @dev added in 1.1 */

    /* Commonly used burn address 
     * @dev as a constant this does not affect proxy storage */
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;    

    /* Address of the buyback contract for early exits */
    IBuyback public buyback;

    /* Admin function to permit calling the burn function */
    bool public burnEnabled;

    /* ========== Initializer ========== */

    function initialize (address _dough, string memory _name, string memory _symbol) public initializer
    {
        dough = IERC20(_dough);
        name = _name;
        symbol = _symbol;
        Ownable.initialize(msg.sender);
    }


    /* ========== SETTERS ========== */

    /**
     * @notice set the dough contract address as we need to transfer DOUGH when the user vests
     */
    function setDough(address _dough)
    external
    onlyOwner
    {
        dough = IERC20(_dough);
        emit DoughUpdated(address(_dough));
    }

    /**
     * @notice set the dough contract address as we need to transfer DOUGH when the user vests
     */
    function setTimelock(address _timelock)
    external
    onlyOwner
    {
        sharesTimeLock = ISharesTimeLock(_timelock);
        emit TimelockUpdated(address(_timelock));
    }

    /**
     * @notice Add a whitelisted rewards contract
     */
    function addRewardsContract(address _rewardContract) external onlyOwner {
        isRewardContract[_rewardContract] = true;
        emit RewardContractAdded(_rewardContract);
    }

    /**
     * @notice Remove a whitelisted rewards contract
    */
    function removeRewardsContract(address _rewardContract) external onlyOwner {
        isRewardContract[_rewardContract] = false;
        emit RewardContractRemoved(_rewardContract);
    }

    /**
     * @notice set the address for the dough buyback functionality
     */
    function setBuyback(address _buyback)
    external
    onlyOwner
    {
        buyback = IBuyback(_buyback);
        emit BuybackContractUpdated(_buyback);
    }

    /**
     * @notice if enabled, will allow users to burn edough 
     */
    function setBurnEnabled(bool _enabled)
    external
    onlyOwner
    {
        burnEnabled =  _enabled;
        emit BurnEnabledUpdated(_enabled);
    }    

    /**
     * @notice approve DOUGH to be transfered to another address
     * @dev call to linked contracts such as eDOUGH buyback to save on approvals each time
     * @param _spender the address to approve
     * @param _amount the quantity to approve
     */
    function approve(address _spender, uint _amount) external onlyOwner returns (bool) {
        require(_spender != address(0), "Cannot approve to zero address");
        dough.safeApprove(_spender, _amount);
        return true;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice A simple alias to totalEscrowedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account)
    public
    view
    returns (uint)
    {
        return totalEscrowedAccountBalance[account];
    }

    /**
     * @notice A simple alias to totalEscrowedBalance: provides ERC20 totalSupply integration.
    */
    function totalSupply() external view returns (uint256) {
        return totalEscrowedBalance;
    }

    /**
     * @notice The number of vesting dates in an account's schedule.
     */
    function numVestingEntries(address account)
    public
    view
    returns (uint)
    {
        return vestingSchedules[account].length;
    }

    /**
     * @notice Get a particular schedule entry for an account.
     * @return A pair of uints: (timestamp, dough quantity).
     */
    function getVestingScheduleEntry(address account, uint index)
    public
    view
    returns (uint[2] memory)
    {
        return vestingSchedules[account][index];
    }

    /**
     * @notice Get the time at which a given schedule entry will vest.
     */
    function getVestingTime(address account, uint index)
    public
    view
    returns (uint)
    {
        return getVestingScheduleEntry(account,index)[TIME_INDEX];
    }

    /**
     * @notice Get the quantity of DOUGH associated with a given schedule entry.
     */
    function getVestingQuantity(address account, uint index)
    public
    view
    returns (uint)
    {
        return getVestingScheduleEntry(account,index)[QUANTITY_INDEX];
    }

    /**
     * @notice Obtain the index of the next schedule entry that will vest for a given user.
     */
    function getNextVestingIndex(address account)
    public
    view
    returns (uint)
    {
        uint len = numVestingEntries(account);
        for (uint i = 0; i < len; i++) {
            if (getVestingTime(account, i) != 0) {
                return i;
            }
        }
        return len;
    }

    /**
     * @notice Obtain the next schedule entry that will vest for a given user.
     * @return A pair of uints: (timestamp, DOUGH quantity). */
    function getNextVestingEntry(address account)
    public
    view
    returns (uint[2] memory)
    {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account)) {
            return [uint(0), 0];
        }
        return getVestingScheduleEntry(account, index);
    }

    /**
     * @notice Obtain the time at which the next schedule entry will vest for a given user.
     */
    function getNextVestingTime(address account)
    external
    view
    returns (uint)
    {
        return getNextVestingEntry(account)[TIME_INDEX];
    }

    /**
     * @notice Obtain the quantity which the next schedule entry will vest for a given user.
     */
    function getNextVestingQuantity(address account)
    external
    view
    returns (uint)
    {
        return getNextVestingEntry(account)[QUANTITY_INDEX];
    }

    /**
     * @notice return the full vesting schedule entries vest for a given user.
     */
    function checkAccountSchedule(address account)
        public
        view
        returns (uint[520] memory)
    {
        uint[520] memory _result;
        uint schedules = numVestingEntries(account);
        for (uint i = 0; i < schedules; i++) {
            uint[2] memory pair = getVestingScheduleEntry(account, i);
            _result[i*2] = pair[0];
            _result[i*2 + 1] = pair[1];
        }
        return _result;
    }

    /**
     * @notice how much eDOUGH can currently be sold back to the DAO, based on vesting + available balance of the buyback contract
     * @dev this does not account for the deadline passing - this must be checked separately
     * @param _recipient the account to check for
     * @return total units of DOUGH that can be sold to the DAO at the price listed in the buyback contract 
     * @return lastFulfillableVestingEntry last index of the sorted vesting array where we are able to completely fulfil the order
     * @dev use lastFulfillableVestingEntry in the buyback function to zero out all values at and before, while keeping this a view function 
     */
    function getAvailableForBuyBack(address _recipient) public view returns (uint total, uint lastFulfillableVestingEntry) {
        uint numEntries = numVestingEntries(_recipient);
        uint maxAvailableDough = buyback.maxAvailableToBuy();

        // iterate though the user's entries 
        for (uint i = 0; i < numEntries; i++) {
            uint[2] memory entry = getVestingScheduleEntry(_recipient, i);        
            uint quantity = entry[QUANTITY_INDEX];
            // we check if quantity and vestingTime is greater than 0 (otherwise, the entry was already claimed)
            if(quantity > 0 && entry[TIME_INDEX] > 0) {
                // edough claimants can enter into buyback at any point as long as we can afford it
                // No partial vests - must fulfill the entire entry
                if (total.add(quantity) <= maxAvailableDough) {
                    // cache the index so we can zero all entries in a non-view function
                    lastFulfillableVestingEntry = i;
                    total = total.add(quantity);
                } else {
                    // save gas by stopping the loop
                    break;
                }
            }
        }
    }    

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @dev A call to this should accompany a previous successfull call to dough.transfer(rewardEscrow, amount),
     * to ensure that when the funds are withdrawn, there is enough balance.
     * Note; although this function could technically be used to produce unbounded
     * arrays, it's only withinn the 4 year period of the weekly inflation schedule.
     * @param account The account to append a new vesting entry to.
     * @param quantity The quantity of DOUGH that will be escrowed.
     */
    function appendVestingEntry(address account, uint quantity)
    public
    onlyRewardsContract
    {
        /* No empty or already-passed vesting entries allowed. */
        require(quantity != 0, "Quantity cannot be zero");

        /* There must be enough balance in the contract to provide for the vesting entry. */
        totalEscrowedBalance = totalEscrowedBalance.add(quantity);
        require(totalEscrowedBalance <= dough.balanceOf(address(this)),
        "Must be enough balance in the contract to provide for the vesting entry");

        /* Disallow arbitrarily long vesting schedules in light of the gas limit. */
        uint scheduleLength = vestingSchedules[account].length;
        require(scheduleLength <= MAX_VESTING_ENTRIES, "Vesting schedule is too long");

        /* Escrow the tokens for 1 year. */
        uint time = now + 52 weeks;

        if (scheduleLength == 0) {
            totalEscrowedAccountBalance[account] = quantity;
        } else {
            /* Disallow adding new vested DOUGH earlier than the last one.
             * Since entries are only appended, this means that no vesting date can be repeated. */
            require(getVestingTime(account, numVestingEntries(account) - 1) < time, "Cannot add new vested entries earlier than the last one");
            totalEscrowedAccountBalance[account] = totalEscrowedAccountBalance[account].add(quantity);
        }

        // If last window is less than a week old add amount to that one.
        if(
            vestingSchedules[account].length != 0 && 
            vestingSchedules[account][vestingSchedules[account].length - 1][0] > time - 1 weeks
        ) {
            vestingSchedules[account][vestingSchedules[account].length - 1][1] = vestingSchedules[account][vestingSchedules[account].length - 1][1].add(quantity);
        } else {
            vestingSchedules[account].push([time, quantity]);
        }
        
        emit Transfer(address(0), account, quantity);
        emit VestingEntryCreated(account, now, quantity);
    }

    /**
     * @notice Allow a user to withdraw any DOUGH in their schedule that have vested.
     */
    function vest()
    external
    {
        uint numEntries = numVestingEntries(msg.sender);
        uint total;
        for (uint i = 0; i < numEntries; i++) {
            uint time = getVestingTime(msg.sender, i);
            /* The list is sorted; when we reach the first future time, bail out. */
            if (time > now) {
                break;
            }
            uint qty = getVestingQuantity(msg.sender, i);
            if (qty == 0) {
                continue;
            }

            vestingSchedules[msg.sender][i] = [0, 0];
            total = total.add(qty);
        }

        if (total != 0) {
            totalEscrowedBalance = totalEscrowedBalance.sub(total);
            totalEscrowedAccountBalance[msg.sender] = totalEscrowedAccountBalance[msg.sender].sub(total);
            totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].add(total);
            dough.safeTransfer(msg.sender, total);
            emit Vested(msg.sender, now, total);
            emit Transfer(msg.sender, address(0), total);
        }
    }

    /**
     * @notice Allow a user to withdraw any DOUGH in their schedule to skip waiting and migrate to veDOUGH at maximum stake.
     * 
     */
    function migrateToVeDOUGH()
    external
    {
        require(address(sharesTimeLock) != address(0), "SharesTimeLock not set");
        uint numEntries = numVestingEntries(msg.sender); // get the number of entries for msg.sender
        
        /* 
        // As per PIP-67: 
        // We propose that a bridge be created to swap eDOUGH to veDOUGH with a non-configurable time lock of 3 years.
        // Only eDOUGH that has vested for 6+ months will be eligible for this bridge.
        // https://snapshot.org/#/piedao.eth/proposal/0xaf04cb5391de0cb3d9c9e694a2bf6e5d20f0e4e1c48e0a1d6f85c5233aa580b6
        */
        uint total;
        for (uint i = 0; i < numEntries; i++) {
            uint[2] memory entry = getVestingScheduleEntry(msg.sender, i);        
            (uint quantity, uint vestingTime) = (entry[QUANTITY_INDEX], entry[TIME_INDEX]);
            
            // we check if quantity and vestingTime is greater than 0 (otherwise, the entry was already claimed)
            if(quantity > 0 && vestingTime > 0) {
                uint activationTime = entry[TIME_INDEX].sub(26 weeks); // point in time when the bridge becomes possible (52 weeks - 26 weeks = 26 weeks (6 months))

                if(block.timestamp >= activationTime) {
                    vestingSchedules[msg.sender][i] = [0, 0];
                    total = total.add(quantity);
                }
            }
        }

        // require amount to stake > 0, else we emit events and update the state
        require(total > 0, 'No vesting entries to bridge');

        totalEscrowedBalance = totalEscrowedBalance.sub(total);
        totalEscrowedAccountBalance[msg.sender] = totalEscrowedAccountBalance[msg.sender].sub(total);
        totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].add(total);

        // Approve DOUGH to Timelock (we need to approve)
        dough.safeApprove(address(sharesTimeLock), 0);
        dough.safeApprove(address(sharesTimeLock), total);

        // Deposit to timelock
        sharesTimeLock.depositByMonths(total, STAKE_DURATION, msg.sender);

        emit MigratedToVeDOUGH(msg.sender, now, total);
        emit Transfer(msg.sender, address(0), total);
    }
    

    /**
     * @notice eDOUGH that has been vesting for less than 6 months can be sold back to the DAO at a fixed price
     * @dev as part of setup, ensure approve has been called with the address of the vesting contract
     */
    function eDoughBuyback()
    external
    {
        require(address(buyback) != address(0), "Buyback contract not set");

        (uint total, uint lastFulfillableVestingEntry) = getAvailableForBuyBack(msg.sender);
        require(total > 0, 'Nothing available for buyback');

        // for all entries we can completely fulfil, zero them out
        for (uint i = 0; i <= lastFulfillableVestingEntry; i++) {
            vestingSchedules[msg.sender][i] = [0, 0];
        }

        totalEscrowedBalance = totalEscrowedBalance.sub(total);
        totalEscrowedAccountBalance[msg.sender] = totalEscrowedAccountBalance[msg.sender].sub(total);
        totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].add(total);

        // buyback will execute transfers - will throw if price has expired
        bool success = buyback.buyback(total, msg.sender);
        require(success, "Buyback failed");

        emit Buyback(msg.sender, block.timestamp, total);
        emit Transfer(msg.sender, address(buyback), total);
    }

    function eDoughBurn()
    external
    {
        require(burnEnabled, "Burn disabled");
        // we can just burn the entire user balance
        uint userBalance = balanceOf(msg.sender);
        require(userBalance > 0, 'Nothing to burn');

        // get the user's vesting entries and zero them out
        uint numEntries = numVestingEntries(msg.sender); 
        for (uint i = 0; i < numEntries; i++) {
            // user is burning everything once, so just zero their entire schedule
            if (vestingSchedules[msg.sender][i][0] != 0) {
                vestingSchedules[msg.sender][i] = [0, 0];
            }
        }

        // sub off the escrow but don't increment state variables (we resolve off-chain)
        totalEscrowedBalance = totalEscrowedBalance.sub(userBalance);
        totalEscrowedAccountBalance[msg.sender] = 0;

        // burn corresponding DOUGH
        dough.safeTransfer(BURN_ADDRESS, userBalance);

        emit Burned(msg.sender, userBalance);
        emit Transfer(msg.sender, BURN_ADDRESS, userBalance);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRewardsContract() {
        require(isRewardContract[msg.sender], "Only reward contract can perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event DoughUpdated(address newDough);

    event TimelockUpdated(address newTimelock);

    event Vested(address indexed beneficiary, uint time, uint value);

    event MigratedToVeDOUGH(address indexed beneficiary, uint time, uint value);

    event VestingEntryCreated(address indexed beneficiary, uint time, uint value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event RewardContractAdded(address indexed rewardContract);

    event RewardContractRemoved(address indexed rewardContract);

    event BuybackContractUpdated(address newBuyback);

    event Buyback(address indexed beneficiary, uint time, uint value);

    event Burned(address indexed from, uint value);

    event BurnEnabledUpdated(bool enabled);
}