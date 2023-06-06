//HEXPOOL.sol
//
//

pragma solidity ^0.5.13;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./HEX.sol";

////////////////////////////////////////////////
////////////////////EVENTS/////////////////////
//////////////////////////////////////////////
contract PoolEvents {

//when a user enters a pool
    event PoolEntry(
        address indexed user,//msg.sender
        uint indexed heartValue,
        uint indexed entryId,
        uint poolId
    );
    
//when a user exits a pool
    event PoolExit(
        address indexed user,//msg.sender
        uint indexed heartValue,
        uint indexed entryId,
        uint poolId
    );

//when a pool starts staking
    event PoolStartStake(
        uint heartValue,//always 150m
        uint indexed dayLength,
        uint indexed poolId,
        uint hexStakeId
    );

//when a pool ends stake
    event PoolEndStake(
        uint heartValue,//always 150m
        uint indexed stakeProfit,
        uint indexed dayLength,
        uint indexed poolId,
        uint hexStakeId
    );

//when an ended stakes rewards are withdrawn
    event Withdrawal(
        address indexed user,
        uint indexed heartValue
    );
}

contract TokenEvents {

//when a user freezes tokens
    event TokenFreeze(
        address indexed user,
        uint indexed value
    );

//when a user unfreezes tokens
    event TokenUnfreeze(
        address indexed user,
        uint indexed value
    );
}

//////////////////////////////////////
//////////POOL TOKEN CONTRACT////////
////////////////////////////////////
contract POOL is IERC20, TokenEvents{

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    bool internal mintBlock;//stops any more tokens ever being minted once _totalSupply reaches _maxSupply - allows for burn rate to take full effect
    uint256 internal _maxSupply = 10000000000000000000;// max supply @ 100B
    uint256 internal _totalSupply;
    string public constant name = "HEXPOOL";
    string public constant symbol = "POOL";
    uint public constant decimals = 8;

    //BUDDY SYSTEM
    uint public buddyDiv;
    //FREEZING
    uint public totalFrozen;
    mapping (address => uint) public tokenFrozenBalances;//balance of POOL frozen mapped by user

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        //1% burn rate
        uint burnt = amount.div(100);
        uint newAmt = amount.sub(burnt);
        _balances[sender] = _balances[sender].sub(newAmt, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(newAmt);
        _burn(sender, burnt);
        emit Transfer(sender, recipient, newAmt);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        uint256 amt = amount;
        require(account != address(0), "ERC20: mint to the zero address");
        if(!mintBlock){
            if(_totalSupply < _maxSupply){
                if(_totalSupply.add(amt) > _maxSupply){
                    amt = _maxSupply.sub(_totalSupply);
                    _totalSupply = _maxSupply;
                    mintBlock = true;
                }
                else{
                    _totalSupply = _totalSupply.add(amt);
                }
                _balances[account] = _balances[account].add(amt);
                emit Transfer(address(0), account, amt);
            }
        }
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance"));
    }

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);//from address(0) for minting

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    //mint POOL to msg.sender
    function mintPool(uint hearts)
        internal
        returns(bool)
    {
        uint amt = hearts.div(100);
        address minter = msg.sender;
        _mint(minter, amt);//mint POOL - 1% of total heart value before fees @ 10 POOL for 1000 HEX
        return true;
    }

    ////////////////////////////////////////////////////////
    /////////////////PUBLIC FACING - POOL CONTROL//////////
    //////////////////////////////////////////////////////

    //freeze POOL to contract
    function FreezeTokens(uint amt)
        public
    {
        require(amt > 0, "zero input");
        require(tokenBalance() >= amt, "Error: insufficient balance");//ensure user has enough funds
        //update balances (allow for 1% burn)
        tokenFrozenBalances[msg.sender] = tokenFrozenBalances[msg.sender].add(amt.sub(amt.div(100)));
        totalFrozen = totalFrozen.add(amt.sub(amt.div(100)));
        _transfer(msg.sender, address(this), amt);//make transfer and burn
        emit TokenFreeze(msg.sender, amt);
    }

    //unfreeze POOL from contract
    function UnfreezeTokens(uint amt)
        public
    {
        require(amt > 0, "zero input");
        require(tokenFrozenBalances[msg.sender] >= amt,"Error: unsufficient frozen balance");//ensure user has enough frozen funds
        tokenFrozenBalances[msg.sender] = tokenFrozenBalances[msg.sender].sub(amt);//update balances
        totalFrozen = totalFrozen.sub(amt);
        _transfer(address(this), msg.sender, amt);//make transfer and burn
        emit TokenUnfreeze(msg.sender, amt);
    }

    ///////////////////////////////
    ////////VIEW ONLY//////////////
    ///////////////////////////////

    //total POOL frozen in contract
    function totalFrozenTokenBalance()
        public
        view
        returns (uint256)
    {
        return totalFrozen;
    }

    //pool balance of caller
    function tokenBalance()
        public
        view
        returns (uint256)
    {
        return balanceOf(msg.sender);
    }
}

contract HEXPOOL is POOL, PoolEvents {

    ///////////////////////////////////////////////////////////////////////
    ////////////////////////////////CONTRACT SETUP///////////////////////
    ////////////////////////////////////////////////////////////////////
    using SafeMath for uint256;

    HEX hexInterface;

    //HEXPOOL
    address payable constant hexAddress = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;

    address payable devAddress;//set in constructor
    address payable constant devAddress2 = 0xD30BC4859A79852157211E6db19dE159673a67E2;

    uint constant fee = 100; //1%;
    uint constant devFee = 2; // 50% of 1% @ 0.5%;
    uint constant devFee2 = 4; // 25% of 1% @ 0.25%;
    uint constant refFee = 4; // 25% of 1% @ 0.25%; - 100% goes to buddyDiv if no ref, 50% if ref;

    uint public last_pool_entry_id;// pool entry id
    uint public last_pool_id;// pool id
    uint public last_stake_id;// stake id

    uint public minEntryHearts;//minimum entry value

    mapping (address => UserInfo) public users;
    mapping (uint => EntryInfo) public entries;
    mapping (uint => PoolInfo) public pools;

    mapping (uint => uint) internal poolUserCount;
    mapping (uint => uint[]) internal poolEntryIds;
    mapping (address => uint[]) internal userEntryIds;

    bool locked;
    bool ready;

    struct UserInfo {
        uint     totalHeartsEntered;
        address  userAddress;
    }

    struct EntryInfo {
        uint     heartValue;
        uint     poolId;
        uint     entryId;
        address payable userAddress;
        address payable refferer;
    }

    struct PoolInfo {
        uint     poolStakeThreshold;//hearts
        uint     poolStakeDayLength;
        uint     poolValue;//hearts
        uint     poolId;
        uint     poolType;
        mapping  (address => bool) poolParticipant;
        mapping  (address => uint) userHeartValue;
        uint     stakeId;
        uint40   hexStakeId;
        bool     isStaking;
        bool     isActive;
        uint256  poolStakeStartTimestamp;
        uint     stakeValue;
        uint     stakeProfit;
        bool     stakeEnded;
    }

    modifier onlyOwner {
        require(msg.sender == devAddress, "notOwner");
        _;
    }

    modifier canEnter(uint id, uint hearts) {
        require(isPoolActive(id), "cannot enter, poolId not active");
        require(id <= last_pool_id, "Error: poolId out of range");
        require(hearts > minEntryHearts, "Error: value must be greater than minEntryHearts");
        _;
    }

    modifier isReady {
        require(ready, "cannot enter, pools not initialized");
        _;
    }

    modifier synchronized {
        require(!locked, "Sync lock");
        locked = true;
        _;
        locked = false;
    }

    constructor() public {
        devAddress = msg.sender;
        hexInterface = HEX(hexAddress);
        initializePools();
    }

    function() external payable {
        require(false); //refunds any eth accidently sent to contract;
    }

    function initializePools()
        internal
        onlyOwner
    {
        require(!ready, "cannot reinitialize");
        //create one of each pool on deployment
        for(uint i = 0; i < 3; i++){
            newPool(i, 0, address(0));
        }
        setMinEntry(100000000000);//1000 HEX @ contract launch, may change dependant on price.
        ready = true;
    }

    ///////////////////////////////////////////////////////////////////////
    ////////////////////////////////HEXPOOL CORE//////////////////////////
    ////////////////////////////////////////////////////////////////////

    //creates a new pool - called on initializePools and when a poolValue reachs its poolStakeThreshold
    function newPool(uint poolType, uint remainderHearts, address payable ref)
       internal
       returns (bool)
    {
        uint threshold;
        uint dayLength;

        if(poolType == 0){
            threshold = 15000000000000000;//150M BPB @ 10% - 36 DAYS
            dayLength = 36;//~1 month
        }
        else if(poolType == 1){
            threshold = 15000000000000000;//150M BPB @ 10% - 365 DAYS
            dayLength = 365;//1 year
        }
        else if(poolType == 2){
            threshold = 15000000000000000;//150M BPB @ 10% - 3650 DAYS
            dayLength = 3650;//10 years (max rewards)
        }
        else{
            revert("invalid poolType");
        }
        uint id = _next_pool_id();
        PoolInfo storage pool = pools[id];
        pool.poolStakeThreshold = threshold;//hearts
        pool.poolStakeDayLength = dayLength;
        pool.poolValue = remainderHearts;//hearts
        pool.poolId = id;
        pool.poolType = poolType;
        pool.isActive = true;
        if(remainderHearts > 0){//update pool, user and entry data as the new pool now has 1 participant
            poolUserCount[id]++;
            pool.poolParticipant[msg.sender] = true;
            pool.userHeartValue[msg.sender] = pool.userHeartValue[msg.sender].add(remainderHearts);
            //user info
            updateUserData(remainderHearts);
            //entry info
            updateEntryData(remainderHearts, id, ref);
        }
        pools[id] = pool;
        return true;
    }

    //enters pool - transfers HEX from user to contract - approval needed
    function enterPool(uint hearts, uint poolId, address payable ref)
        internal
        returns(bool)
    {
        PoolInfo storage pool = pools[poolId];
        require(hearts <= pool.poolStakeThreshold, "amount over threshold - only 1 new pool to be created per tx");
        require(!pool.isStaking, "pool is staking");
        //calc amounts
        uint _fee = hearts.div(fee);
        uint _devFee = _fee.div(devFee);
        uint _devFee2 = _fee.div(devFee2);
        uint _refFee = _fee.div(refFee);
        uint _hearts = hearts.sub(_fee);
        pool.poolValue = pool.poolValue.add(_hearts);//increment pool value with heart value after fees
        if(!pool.poolParticipant[msg.sender]){
            pool.poolParticipant[msg.sender] = true;
            poolUserCount[poolId]++;
        }
         //TOTAL amount of hearts this user has input in THIS pool after fees (EntryInfo for individual pool entries)
        pool.userHeartValue[msg.sender] = pool.userHeartValue[msg.sender].add(_hearts);
        //buddy divs
        if(buddyDiv > 0){
            require(hexInterface.transfer(msg.sender, buddyDiv), "Transfer failed");//send hex as buddy div to user
        }
        if(ref == address(0)){//no ref
            //hex refFee to buddyDivs
            buddyDiv = _refFee;
        }
        else{//ref
            //hex refFee to ref
            buddyDiv = _refFee.div(2);
            require(hexInterface.transferFrom(msg.sender, ref, _refFee.div(2)), "Ref transfer failed");//send hex to refferer
        }
        //send
        require(hexInterface.transferFrom(msg.sender, address(this), _hearts.add(buddyDiv)), "Transfer failed");//send hex from user to contract + buddyDivs to remain in contract
        require(hexInterface.transferFrom(msg.sender, devAddress, _devFee), "Dev1 transfer failed");//send hex to dev
        require(hexInterface.transferFrom(msg.sender, devAddress2, _devFee2), "Dev2 transfer failed");//send hex to dev2
        //check for pool overflow
        if(pool.poolValue > pool.poolStakeThreshold){
            uint remainderHearts = pool.poolValue.sub(pool.poolStakeThreshold);//get remainder
            //user info
            updateUserData(_hearts.sub(remainderHearts));//remainder to be rolled to next pool
            //entry info
            updateEntryData(_hearts.sub(remainderHearts), pool.poolId, ref);//remainder to be rolled to next pool
            pool.poolValue = pool.poolStakeThreshold;//set as max
             //Back out the remainder value that is spilling into the next pool
            pool.userHeartValue[msg.sender] = pool.userHeartValue[msg.sender].sub(remainderHearts);
            require(startStake(poolId, pool), "Error: could not start stake");
            require(newPool(pool.poolType, remainderHearts, ref), "Error: could not create new pool");//create new pool with remainder
        }
        else if(pool.poolValue == pool.poolStakeThreshold){
            //user info
            updateUserData(_hearts);
            //entry info
            updateEntryData(_hearts, pool.poolId, ref);
            require(startStake(poolId, pool), "Error: could not start stake");
            require(newPool(pool.poolType, 0, ref), "Error: could not create new pool");//new pool no remainder
        }
        else{
            //user info
            updateUserData(_hearts);
            //entry info
            updateEntryData(_hearts, pool.poolId, ref);
        }
        //mint bonus POOL tokens relative to HEX amount before fees
        require(mintPool(hearts), "Error: could not mint tokens");
        return true;
    }

    //starts staking poolStakeThreshold to the HEX contract
    function startStake(uint poolId, PoolInfo storage pool)
        internal
        returns (bool)
    {
        require(pool.poolValue == pool.poolStakeThreshold, "Stake amount incorrect");
        uint newStakedHearts = pool.poolStakeThreshold;
        uint newStakedDays = pool.poolStakeDayLength;
        hexInterface.stakeStart(newStakedHearts, newStakedDays);
        uint hexStakeIndex = hexInterface.stakeCount(address(this)).sub(1);//get the most recent stakeIndex
        SStore memory stake = getStakeByIndex(address(this), hexStakeIndex); //get stake from address and stakeindex
        //set pool stake id info
        pool.hexStakeId = stake.stakeId;
        pool.stakeId = last_stake_id;
        pool.poolStakeStartTimestamp = now;
        pool.isActive = false;
        pool.isStaking = true;
        _next_stake_id();
        emit PoolStartStake(
            newStakedHearts,
            newStakedDays,
            poolId,
            stake.stakeId
        );
        return true;
    }

    //end a pool stake - cannot emergency unstake - needs testing
    function endStake(uint poolId)
        internal
        returns (bool)
    {
        require(poolId <= last_pool_id, "Error: poolId out of range");
        PoolInfo storage pool = pools[poolId];
        require(pool.isStaking, "Error: pool is not yet staked, or has already ended staking");
        require(isPoolStakeFinished(poolId), "Error: cannot early unstake");

        uint256 oldBalance = getContractBalance();
        //find the stake index then
        //end stake
        hexInterface.stakeEnd(getStakeIndexById(address(this), pool.hexStakeId), pool.hexStakeId);
        pool.isStaking = false;
        pool.stakeEnded = true;
        //calc stakeValue and stakeProfit
        uint256 stakeValue = getContractBalance().sub(oldBalance);
        pool.stakeValue = stakeValue;
        pool.stakeProfit = stakeValue.sub(pool.poolStakeThreshold);
        emit PoolEndStake(
            pool.stakeProfit,
            pool.poolValue,
            pool.poolStakeDayLength,
            pool.poolId,
            pool.hexStakeId
        );
        return true;
    }

    //withdraws any staking rewards - or ends a stake if finished but not yet unstaked
    function withdrawPoolRewards(uint poolId)
        internal
        returns(bool)
    {
        PoolInfo storage pool = pools[poolId];
        require(pool.poolValue > 0, "pool rewards have been drained");
        require(pools[poolId].userHeartValue[msg.sender] > 0, "you have no share in this pool");
        if(!pool.stakeEnded){
            endStake(poolId);
        }
        uint rewards = getWithdrawableRewards(poolId);//calculate pool share
        pool.poolValue = pool.poolValue.sub(pool.userHeartValue[msg.sender]);//reduce pool value
        pool.userHeartValue[msg.sender] = 0;//user has withdrawn rewards from pool
        if(pool.poolValue == 0){
            delete pools[poolId];//delete pool if empty
        }
        require(hexInterface.transfer(msg.sender, rewards), "Transfer failed");//transfer users share
        emit Withdrawal(msg.sender, rewards);
        return true;
    }

    //get any withdrawable staking rewards of caller
    function getWithdrawableRewards(uint poolId)
        public
        view
        returns (uint)
    {
        PoolInfo storage pool = pools[poolId];
        require(pool.stakeEnded, "pool stake has not yet finished");
        if(pool.userHeartValue[msg.sender] == 0){
            return 0;
        }
        uint stakeWithdrawable = pool.stakeValue.mul(pool.userHeartValue[msg.sender]).div(pool.poolStakeThreshold);//withdrawable rewards
        return stakeWithdrawable;
    }

    //exits pool of entry by entryId
    function exitPool(uint entryId)
        internal
        returns (bool)
    {
        EntryInfo memory entry = entries[entryId];
        require(msg.sender == entry.userAddress, "not entry owner, or already exited");
        PoolInfo storage pool = pools[entry.poolId];
        require(pool.poolParticipant[msg.sender], "you are not a pool participant");
        require(!pool.isStaking, "pool is staking, cannot exit");
        users[msg.sender].totalHeartsEntered = users[msg.sender].totalHeartsEntered.sub(entry.heartValue);
        pool.poolValue = pool.poolValue.sub(entry.heartValue); //reduce pool value
        pool.userHeartValue[msg.sender] = pool.userHeartValue[msg.sender].sub(entry.heartValue);//reduce users pool share
        //remove user from pool data if 0 pool share
        if(pool.userHeartValue[msg.sender] == 0){
            pool.poolParticipant[msg.sender] = false;
            poolUserCount[entry.poolId]--;
        }
        delete entries[entryId];
        //calc fee amount
        uint _fee = entry.heartValue.div(fee);
        uint _devFee = _fee.div(devFee);
        uint _devFee2 = _fee.div(devFee2);
        uint _refFee = _fee.div(refFee);
        uint _hearts = entry.heartValue.sub(_fee);
        
        if(buddyDiv > 0){
            require(hexInterface.transfer(devAddress, buddyDiv.div(2)), "Transfer failed");//send hex as buddy div to dev1 as penalty for user exiting pool
            require(hexInterface.transfer(devAddress2, buddyDiv.div(2)), "Transfer failed");//send hex as buddy div to dev2 as penalty for user exiting pool
        }
        if(entry.refferer == address(0)){//no ref
            //set new buddyDivs as hex refFee
            buddyDiv = _refFee;
        }
        else{//ref
            //set new buddyDivs as hex refFee / 2
            buddyDiv = _refFee.div(2);
            require(hexInterface.transfer(entry.refferer, _refFee.div(2)), "Ref transfer failed");//send hex to refferer
        }
        //send
        require(hexInterface.transfer(msg.sender, _hearts), "Transfer failed");//send hex from contract to user
        require(hexInterface.transfer(devAddress, _devFee), "Dev1 transfer failed");//send hex to dev
        require(hexInterface.transfer(devAddress2, _devFee2), "Dev2 transfer failed");//send hex to dev2
        //events
        emit PoolExit(
            entry.userAddress,
            entry.heartValue,
            entry.entryId,
            pool.poolId
        );
        return true;
    }

    //updates user data
    function updateUserData(uint hearts)
        internal
    {
        UserInfo storage user = users[msg.sender];
        user.totalHeartsEntered = user.totalHeartsEntered.add(hearts);//total amount of hearts deposited by this user after fees
        user.userAddress = msg.sender;
    }

    //updates entry data
    function updateEntryData(uint hearts, uint poolId, address payable ref)
        internal
    {
        uint _entryID = _next_pool_entry_id();
        userEntryIds[msg.sender].push(_entryID);//update userEntryIds
        poolEntryIds[poolId].push(_entryID);//update poolEntryIds
        EntryInfo memory entry;
        entry.heartValue = hearts;//amount of hearts deposited in this entry after fees
        entry.poolId = poolId;//poolId this entry has deposited to
        entry.entryId = _entryID;
        entry.userAddress = msg.sender;
        entry.refferer = ref;
        entries[_entryID] = entry;//update entry data
        emit PoolEntry(
            entry.userAddress,
            entry.heartValue,
            entry.entryId,
            poolId
        );
    }

    //get next entry id
    function _next_pool_entry_id()
        internal
        returns (uint)
    {
        last_pool_entry_id++;
        return last_pool_entry_id;
    }

    //get next pool id
    function _next_pool_id()
        internal
        returns (uint)
    {
        last_pool_id++;
        return last_pool_id;
    }

    //get next stake id
    function _next_stake_id()
        internal
        returns (uint)
    {
        last_stake_id++;
        return last_stake_id;
    }

    //////////////////////////////////////////////////////////////////
    ////////////////////////PUBLIC FACING HEXPOOL////////////////////
    ////////////////////////////////////////////////////////////////

    //enter any pool that isActive
    function EnterPool(uint _hearts, uint _poolId, address payable _ref)
        public
        canEnter(_poolId, _hearts)
        synchronized
    {
        require(enterPool(_hearts, _poolId, _ref), "Error: could not enter pool");
    }

    //withdraw funds from pool by entryId - pool cannot be already staking
    function ExitPool(uint _entryId)
        public
        synchronized
    {
        require(exitPool(_entryId), "Error: could not exit pool");
    }

    //ends a staked pool
    function EndPoolStake(uint _poolId)
        public
        synchronized
    {
        require(endStake(_poolId), "Error: could not end stake");
    }

    //withdraws HEX staking rewards
    function WithdrawHEX(uint _poolId)
        public
        synchronized
    {
        require(withdrawPoolRewards(_poolId), "Error: could not withdraw rewards");
    }

    //////////////////////////////////////////
    ////////////VIEW ONLY/////////////////////
    //////////////////////////////////////////

    //only an active pool can be entered or exited
    function isPoolActive(uint poolId)
        public
        view
        isReady
        returns(bool)
    {
        return pools[poolId].isActive;
    }

    //
    function isPoolStaking(uint poolId)
        public
        view
        returns(bool)
    {
        return pools[poolId].isStaking;
    }

    //
    function isPoolStakeFinished(uint poolId)
        public
        view
        returns(bool)
    {
        //add 1 to stakeDayLength to account for stake pending time
        return pools[poolId].poolStakeStartTimestamp.add((pools[poolId].poolStakeDayLength.add(1)).mul(86400)) <= now;
    }

    //
    function isPoolStakeEnded(uint poolId)
        public
        view
        returns(bool)
    {
        return pools[poolId].stakeEnded;
    }

    //general user info
    function getUserInfo(address addr)
        public
        view
        returns(
        uint    totalHeartsEntered,
        uint[] memory _entryIds,
        address userAddress
        )
    {
        return(users[addr].totalHeartsEntered, userEntryIds[addr], users[addr].userAddress);
    }

    //general entry info
    function getEntryInfo(uint entryId)
        public
        view
        returns(
        uint     heartValue,
        uint     poolId,
        address payable userAddress,
        address payable refferer
        )
    {
        return(entries[entryId].heartValue, entries[entryId].poolId, entries[entryId].userAddress, entries[entryId].refferer);
    }

    //general pool info
    function getPoolInfo(uint poolId)
        public
        view
        returns(
        uint     poolStakeThreshold,//hearts
        uint     poolStakeDayLength,
        uint     poolValue,//hearts
        uint     poolType,
        bool     isStaking,
        uint256  poolStakeStartTimestamp,
        bool     stakeEnded
        )
    {
        return(
            pools[poolId].poolStakeThreshold,
            pools[poolId].poolStakeDayLength,
            pools[poolId].poolValue,
            pools[poolId].poolType,
            pools[poolId].isStaking,
            pools[poolId].poolStakeStartTimestamp,
            pools[poolId].stakeEnded
            );
    }

    //returns all entryIds of a pool
    function getPoolEntryIds(uint poolId)
        public
        view
        returns(uint[] memory)
    {
        return poolEntryIds[poolId];
    }

    //return vital stake params
    function getPoolStakeInfo(uint poolId)
        public
        view
        returns(uint stakeId, uint hexStakeIndex, uint40 hexStakeId)
    {
        return(pools[poolId].stakeId, getStakeIndexById(address(this), pools[poolId].hexStakeId), pools[poolId].hexStakeId);
    }

    //returns amount of users by address in a pool
    function getPoolUserCount(uint poolId)
        public
        view
        returns(uint)
    {
        return poolUserCount[poolId];
    }

    //is address a user of pool
    function isPoolParticipant(uint id, address addr)
        public
        view
        returns(bool)
    {
       return pools[id].poolParticipant[addr];
    }

    //returns total hearts a user owns in pool
    function getUserHeartValue(uint id, address addr)
        public
        view
        returns(uint)
    {
       return pools[id].userHeartValue[addr];
    }

    //returns contract HEX balance
    function getContractBalance()
        public
        view
        returns(uint)
    {
        return hexInterface.balanceOf(address(this));
    }

    ///////////////////////////////////////////////
    //////////////////MUTABLE//////////////////////
    //////////////////////////////////////////////

    function setMinEntry(uint hearts)
        public
        onlyOwner
    {
        minEntryHearts = hearts;
    }

    ///////////////////////////////////////////////
    ///////////////////HEX UTILS///////////////////
    ///////////////////////////////////////////////
    //credits to kyle bahr @ https://gist.github.com/kbahr/80e61ab761053849f7fdc6226b85a354

    struct SStore {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;
    }

    struct DailyDataCache {
        uint256 dayPayoutTotal;
        uint256 dayStakeSharesTotal;
        uint256 dayUnclaimedSatoshisTotal;
    }
    uint256 private constant HEARTS_UINT_SHIFT = 72;
    uint256 private constant HEARTS_MASK = (1 << HEARTS_UINT_SHIFT) - 1;
    uint256 private constant SATS_UINT_SHIFT = 56;
    uint256 private constant SATS_MASK = (1 << SATS_UINT_SHIFT) - 1;

    function decodeDailyData(uint256 encDay)
    private
    pure
    returns (DailyDataCache memory)
    {
        uint256 v = encDay;
        uint256 payout = v & HEARTS_MASK;
        v = v >> HEARTS_UINT_SHIFT;
        uint256 shares = v & HEARTS_MASK;
        v = v >> HEARTS_UINT_SHIFT;
        uint256 sats = v & SATS_MASK;
        return DailyDataCache(payout, shares, sats);
    }

    function interestForRange(DailyDataCache[] memory dailyData, uint256 myShares)
    private
    pure
    returns (uint256)
    {
        uint256 len = dailyData.length;
        uint256 total = 0;
        for(uint256 i = 0; i < len; i++){
            total += interestForDay(dailyData[i], myShares);
        }
        return total;
    }

    function interestForDay(DailyDataCache memory dayObj, uint256 myShares)
    private
    pure
    returns (uint256)
    {
        return myShares * dayObj.dayPayoutTotal / dayObj.dayStakeSharesTotal;
    }

    function getDataRange(uint256 b, uint256 e)
    private
    view
    returns (DailyDataCache[] memory)
    {
        uint256[] memory dataRange = hexInterface.dailyDataRange(b, e);
        uint256 len = dataRange.length;
        DailyDataCache[] memory data = new DailyDataCache[](len);
        for(uint256 i = 0; i < len; i++){
            data[i] = decodeDailyData(dataRange[i]);
        }
        return data;
    }

    function getLastDataDay()
    private
    view
    returns(uint256)
    {
        uint256[13] memory globalInfo = hexInterface.globalInfo();
        uint256 lastDay = globalInfo[4];
        return lastDay;
    }

    function getInterestByStake(SStore memory s)
    private
    view
    returns (uint256)
    {
        uint256 b = s.lockedDay;
        uint256 e = getLastDataDay(); // ostensibly "today"

        if (b >= e) {
            //not started - error
            return 0;
        } else {
            DailyDataCache[] memory data = getDataRange(b, e);
            return interestForRange(data, s.stakeShares);
        }
    }

    function getInterestByStakeId(address addr, uint40 stakeId)
    public
    view
    returns (uint256)
    {
        SStore memory s = getStakeByStakeId(addr, stakeId);

        return getInterestByStake(s);
    }

    function getTotalValueByStakeId(address addr, uint40 stakeId)
    public
    view
    returns (uint256)
    {
        SStore memory stake = getStakeByStakeId(addr, stakeId);

        uint256 interest = getInterestByStake(stake);
        return stake.stakedHearts + interest;
    }

    function getStakeByIndex(address addr, uint256 idx)
    private
    view
    returns (SStore memory)
    {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;

        (stakeId,
            stakedHearts,
            stakeShares,
            lockedDay,
            stakedDays,
            unlockedDay,
            isAutoStake) = hexInterface.stakeLists(addr, idx);

        return SStore(stakeId,
                        stakedHearts,
                        stakeShares,
                        lockedDay,
                        stakedDays,
                        unlockedDay,
                        isAutoStake);
    }

    function getStakeByStakeId(address addr, uint40 sid)
    private
    view
    returns (SStore memory)
    {

        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;

        uint256 stakeCount = hexInterface.stakeCount(addr);
        for(uint256 i = 0; i < stakeCount; i++){
            (stakeId,
            stakedHearts,
            stakeShares,
            lockedDay,
            stakedDays,
            unlockedDay,
            isAutoStake) = hexInterface.stakeLists(addr, i);

            if(stakeId == sid){
                return SStore(stakeId,
                                stakedHearts,
                                stakeShares,
                                lockedDay,
                                stakedDays,
                                unlockedDay,
                                isAutoStake);
            }
        }
    }

    function getStakeIndexById(address addr, uint40 sid)
        private
        view
        returns (uint)
    {
        uint40 stakeId;
        uint72 stakedHearts;
        uint72 stakeShares;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
        bool isAutoStake;

        uint256 stakeCount = hexInterface.stakeCount(addr);
        for(uint256 i = 0; i < stakeCount; i++){
            (stakeId,
            stakedHearts,
            stakeShares,
            lockedDay,
            stakedDays,
            unlockedDay,
            isAutoStake) = hexInterface.stakeLists(addr, i);

            if(stakeId == sid){
                return i;
            }
        }
    }
}
