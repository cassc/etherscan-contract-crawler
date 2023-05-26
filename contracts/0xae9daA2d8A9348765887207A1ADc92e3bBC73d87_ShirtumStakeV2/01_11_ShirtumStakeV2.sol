// SPDX-License-Identifier: MIT
pragma solidity = 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ShirtumStakeV2 is AccessControl, ReentrancyGuard, Pausable {

    using Strings for uint256;

    // Create a new role identifier for the owner role
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    event Deposit(uint256 indexed depositId, address indexed user, uint256 amount, uint256 rewards,
                uint256 unlockTime,uint256 apr);
    event Withdraw(uint256 indexed depositId, address indexed user, uint256 amount);
    event Restake(uint256 indexed depositId, address indexed user);

    //Struct that holds each deposit data
    struct Deposits {
        address user;
        uint256 amount;
        uint256 rewards;
        uint256 total;
        uint256 apr;
        uint256 unlockTime;
        bool withdrawn;
    }

    //Struct that holds the locking period data
    struct LockingPeriod {
        uint256 lockingTime; //Time to lock the funds (expressed in days)
        uint256 value; //APR
        bool enabled;
    }    

    //Deposits index
    uint256 public depositId;
    
    //Array of all deposits IDs
    uint256[] public allDepositIds;

    //User deposits
    mapping (address => uint256[]) public depositsByAddress;
    
    //Indexed deposits    
    mapping (uint256 => Deposits) public lockedDeposits;

    //Lockin periods index
    uint256 public periodsId;
    //Array of all periods IDs
    uint256[] public allPeriodsIds;
    
    //Indexed locking periods
    mapping (uint256 => LockingPeriod) public lockingPeriods;
                 
    //ERC20 Token
    address public token;

    //Available rewards
    uint256 public availableRewards;

    //Unlock time for admin withdraw
    uint256 public adminWidrawUnlockTime;

    //Variable that defines if restake option is enabled;
    bool public restakeEnabled;

    constructor (address _token,uint256[] memory _lockingPeriods,uint256[] memory intrestRates ) {
        require(_token != address(0x0), 'Shirtum Stake V2: Address must be different to zero address');
        require(_lockingPeriods.length == intrestRates.length, "Shirtum Stake V2: Amounts length must be equals to locking periods length");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE,msg.sender);
        
        token = _token;

        //Available rewards balance can be withdrawn only after the first year.
        adminWidrawUnlockTime = block.timestamp + 365 days;

        //Load of initial locking periods
        for (uint256 i=0; i<_lockingPeriods.length; i++)
        {
            addLockingPeriod(_lockingPeriods[i], intrestRates[i]);            
        }
    }

    /**
     * @dev Returns the total balance of the user.
     */
    function balanceOf(address user) public view returns (uint256 balance) {
        uint256[] memory ids = depositsByAddress[user];
        for (uint256 i; i < ids.length;i++){
            balance += lockedDeposits[ids[i]].total;
        }

        return balance;
    }

    /**
     * @dev Validates that locking period exists and it's enabled.
     */
    function validateLockinPeriod(uint256 periodId) internal view{
        //Check that lockingPeriod-APR exists
        require(lockingPeriodExistsById(periodId),"Shirtum Stake V2: locking period doesn't exists");
        //Check that lockingPeriod-APR es enabled
        require(lockingPeriods[periodId].enabled,"Shirtum Stake V2: locking period is not enabled");
    }

    /**
     * @dev Validates available rewards.
     * Returns rewards
     */
    function validateRewards(uint256 amount,uint256 periodId) internal view returns(uint256 rewards){
        rewards = calculateRewards(amount, periodId);        
        //Check that required rewards are available
        require(availableRewards >= rewards,'Shirtum Stake V2: insuficient funds to pay required rewards');
        return rewards;
    }

    /**
     * @dev Returns the rewards for the given amount and locking period
     */
    function calculateRewards(uint256 amount, uint256 periodId) public view returns(uint256 rewards){
        uint intrestRate = lockingPeriods[periodId].value;
        uint lockingTime =  lockingPeriods[periodId].lockingTime;
        return (amount * intrestRate * lockingTime) / (100 * 365);
    }

    /**
     * @dev Generates the deposit
     * Requirements: contract must not be paused
     *   
     */
    function stake(uint256 amount,uint256 periodId) public nonReentrant whenNotPaused{        
        validateLockinPeriod(periodId);
        uint256 rewards = validateRewards(amount, periodId);
        uint256 _id = depositId++;
        
        //Create the deposit        
        lockedDeposits[_id].user = msg.sender;
        lockedDeposits[_id].amount = amount;
        lockedDeposits[_id].rewards = rewards;
        lockedDeposits[_id].total = amount + rewards;
        lockedDeposits[_id].apr = lockingPeriods[periodId].value;
        lockedDeposits[_id].unlockTime = block.timestamp + (lockingPeriods[periodId].lockingTime * 1 days);
        lockedDeposits[_id].withdrawn = false;

        allDepositIds.push(_id);
        depositsByAddress[msg.sender].push(_id);

        //Update available rewards
        availableRewards -= rewards;

        require(
        IERC20(token).transferFrom(msg.sender, address(this), amount),
        "Shirtum Stake V2: Unable to transfer the tokens"
        );
        emit Deposit(_id,msg.sender, amount,rewards,lockedDeposits[_id].unlockTime,lockingPeriods[periodId].value);
    }

    /**
     * @dev Update a specific deposit details (unlocktime and/or intrest rate applied)
     *   
     */
    function restake(uint256 _id,uint256 periodId) public nonReentrant{
        require(restakeEnabled,"Shirtum Stake V2: restake is not enabled");
        validateLockinPeriod(periodId);
        require(!lockedDeposits[_id].withdrawn, "Shirtum Stake V2: Locked token has been already withdrawn");
        require(msg.sender == lockedDeposits[_id].user, "Shirtum Stake V2: Sender is not the owner of the deposit");
                
        uint256 amount = lockedDeposits[_id].total;
        
        uint256 rewards = validateRewards(amount, periodId);
        
        uint256 unlockTime = lockedDeposits[_id].unlockTime > block.timestamp ? lockedDeposits[_id].unlockTime : block.timestamp;

        //Update deposit values
        lockedDeposits[_id].total += rewards;
        lockedDeposits[_id].unlockTime = unlockTime + (lockingPeriods[periodId].lockingTime * 1 days);

        //Update available rewards
        availableRewards -= rewards; 

        emit Deposit(_id,msg.sender, amount,rewards,lockedDeposits[_id].unlockTime,lockingPeriods[periodId].value);
        emit Restake(_id,msg.sender);
    }

    /**
     * @dev Withdraw user deposit
     * Requirements: unlock time has to be reached.
     *   
     */
    function withdraw(uint256 _id) public nonReentrant{
        require(block.timestamp >= lockedDeposits[_id].unlockTime, "Shirtum Stake V2: Unlock time has not arrived");
        require(msg.sender == lockedDeposits[_id].user, "Shirtum Stake V2: Sender is not the owner of the deposit");
        require(!lockedDeposits[_id].withdrawn, "Shirtum Stake V2: deposit has been already withdrawn");
        
        lockedDeposits[_id].withdrawn = true;        
                        
        //Remove this id from this address        
        uint256 totalByAddress = depositsByAddress[lockedDeposits[_id].user].length;
        for (uint256 i = 0; i < totalByAddress; i++) {
            if (depositsByAddress[lockedDeposits[_id].user][i] == _id) {
                depositsByAddress[lockedDeposits[_id].user][i] = depositsByAddress[lockedDeposits[_id].user][totalByAddress - 1];
                depositsByAddress[lockedDeposits[_id].user].pop();
                break;
            }
        }
        
        //Transfer tokens to user
        require(
            IERC20(token).transfer(msg.sender, lockedDeposits[_id].total),
            "Shirtun Stake V2: Unable to transfer the tokens"
        );
        
        emit Withdraw(_id,msg.sender, lockedDeposits[_id].total);
    }

    function transferRewardFunds(uint256 amount) public nonReentrant{
        availableRewards += amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function adminWithdraw(uint256 amount,address withdrawalWallet) public onlyRole(OWNER_ROLE){
        require(amount <= availableRewards,"Shirtum Stake V2: can only withdraw upto available rewards balance");
        require(block.timestamp >= adminWidrawUnlockTime,"Shirtum Stake V2: it's not possible to withdraw befor unlock time");
        require(withdrawalWallet != address(0x0), 'Shirtum Stake V2: Address must be different to zero address');

        availableRewards -= amount;
        IERC20(token).transfer(withdrawalWallet, amount);
    }

    function lockingPeriodExists(uint256 lockingTime) internal view returns(bool){
        for (uint256 i;i<allPeriodsIds.length;i++){
            if (lockingPeriods[i].lockingTime == lockingTime){
                return true;
            }
        }
        return false;
    }

    function lockingPeriodExistsById(uint256 periodId) internal view returns(bool){
        return lockingPeriods[periodId].lockingTime > 0;
    }

    function toggleLockingPeriodStatus(uint256 periodId) public onlyRole(OWNER_ROLE){
        require(lockingPeriodExistsById(periodId),"Shirtum Stake V2: locking period doesn't exists");

        lockingPeriods[periodId].enabled = !lockingPeriods[periodId].enabled;
    }

    function addLockingPeriod (uint256 lockingTime, uint256 intrestRate) public onlyRole(OWNER_ROLE){
        require(lockingTime > 0, "Shirtum Stake V2: staking period must be greater than 0");
        require(!lockingPeriodExists(lockingTime),"Shirtum Stake V2: locking period already exists");        
        
        uint256 periodId = periodsId++;        

        lockingPeriods[periodId].lockingTime = lockingTime;
        lockingPeriods[periodId].value = intrestRate;
        lockingPeriods[periodId].enabled = true;

        allPeriodsIds.push(periodId);
    }

    function updateLockingPeriod (uint256 periodId,uint256 lockingTime, uint256 intrestRate) public onlyRole(OWNER_ROLE){
        require(lockingTime > 0, "Shirtum Stake V2: locking time must be greater than 0");
        require(lockingPeriodExistsById(periodId),"Shirtum Stake V2: locking period doesn't exists");        
        
        //Reverts operation if locking time already exists for another locking period
        if (lockingPeriodExists(lockingTime) && lockingPeriods[periodId].lockingTime != lockingTime){
            revert("Locking time already exists for another locking period");
        }

        lockingPeriods[periodId].lockingTime = lockingTime;
        lockingPeriods[periodId].value = intrestRate;
    }

    function getAllLockingPeriodsDetails() view external returns (string[] memory arr)
    {
        arr = new string[](allPeriodsIds.length);
        for (uint256 i;i<allPeriodsIds.length;i++){                        
            arr[i] = string(abi.encodePacked(i.toString(),";",
                            lockingPeriods[i].lockingTime.toString(),";",
                            lockingPeriods[i].value.toString(),";",
                            lockingPeriods[i].enabled ? (uint256(1).toString()) : uint256(0).toString()));
        }
        return arr;
    }

    function getAllLockingPeriodsIds() view external returns (uint256[] memory)
    {
        return allPeriodsIds;
    }

    function getLockingPeriodsDetails(uint256 _id) view external returns (uint256 lockingTime, uint256 value,bool enabled)
    {
        return (
            lockingPeriods[_id].lockingTime,
            lockingPeriods[_id].value,
            lockingPeriods[_id].enabled
        );
    }

    function getAllDepositIds() external view returns (uint256[] memory)
    {
        return allDepositIds;
    }
    
    function getDepositDetails(uint256 _id) external view returns (address _user, uint256 _amount, 
    uint256 _rewards, uint256 _total, uint256 _apr,uint256 _unlockTime, bool _withdrawn)
    {
        return (            
            lockedDeposits[_id].user,
            lockedDeposits[_id].amount,
            lockedDeposits[_id].rewards,
            lockedDeposits[_id].total,
            lockedDeposits[_id].apr,
            lockedDeposits[_id].unlockTime,
            lockedDeposits[_id].withdrawn
        );
    }
    
    function getDepositsByAddress(address _address) view public returns (uint256[] memory)
    {
        return depositsByAddress[_address];
    }

    function pause() public onlyRole(OWNER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        _unpause();
    }

    function toggleRestakeEnabledStatus() public onlyRole(OWNER_ROLE){
        restakeEnabled = !restakeEnabled;
    }

    receive () external payable {
      revert();
    }
}