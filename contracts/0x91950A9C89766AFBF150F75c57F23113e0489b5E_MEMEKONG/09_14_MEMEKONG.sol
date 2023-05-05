// SPDX-License-Identifier: NONE

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "contracts/TokenEvents.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "uniswap-v2-contract/contracts/uniswap-v2-periphery/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "uniswap-v2-contract/contracts/uniswap-v2-core/interfaces/IUniswapV2Factory.sol";
import "uniswap-v2-contract/contracts/uniswap-v2-core/interfaces/IUniswapV2Pair.sol";

pragma solidity ^0.8.18;
contract MEMEKONG is IERC20Upgradeable, TokenEvents, OwnableUpgradeable{

    using AddressUpgradeable for address payable;

    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint64;
    using SafeMathUpgradeable for uint32;
    using SafeMathUpgradeable for uint16;
    using SafeMathUpgradeable for uint8;
    using SafeERC20Upgradeable for MEMEKONG;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) public bots;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniPool;
    address public admin;
    
    uint256 internal _totalSupply;
    uint256 public totalStaked;
    
    bool private sync;

    //burn setup
    uint256 public burnAdjust;
    uint256 public poolBurnAdjust;

    //stake setup
    // Setting numer of days of stacking
    uint internal MINUTESECONDS;
    uint internal DAYSECONDS;
    uint private MINSTAKEDAYLENGTH;
    uint256 private maximumStakingAmount; 
    uint private apyCount;
    uint private adminPercentage;
    uint private burnPercentage;
    
    //tokenomics
    // Changing values according to meme kong
    string public constant name = "MEME KONG";
    string public constant symbol = "MKONG";
    uint8 public decimals = 9;

    bool public isLocked;

    //lock
    bool internal lockContract;

    uint256 public UNSTAKE_TIMEOFF;

    event UniSwapBuySell(address indexed from, address indexed to, uint value, uint adminCommission, uint burnAmount);
    
    struct Staker{
        uint256 stakedBalance;
        uint256 stakeStartTimestamp;
        uint256 totalStakingInterest;
        uint256 totalBurnt;
        bool activeUser;
        uint256 lastDepositTime;
        uint256 unstakeStartTime;
        uint256 pendingAmount;
    }
    
    // mapping(address => bool) admins;
    mapping (address => Staker) public staker;
    //protects against potential reentrancy
    modifier synchronized {  
        require(!sync, "Sync lock");
        sync = true;
        _; 
        sync = false;
    }

    function init(uint256 initialTokens, address _adminAccount, address _router) external initializer{

        //burn setup
        burnAdjust = 10;
        decimals = 9;
        poolBurnAdjust = 100;

    //stake setup
    // Setting numer of days of stacking
        MINUTESECONDS = 60;
        DAYSECONDS = 86400;
        MINSTAKEDAYLENGTH = 9;
        maximumStakingAmount = 2e8 * 10 ** decimals; 
        apyCount = 1251;
        adminPercentage = 7;
        burnPercentage = 2;

        UNSTAKE_TIMEOFF = 9 days;
    
        isLocked = false;

    //lock
        lockContract = false;

        __Ownable_init();

        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router; 
      
        mintInitialTokens(initialTokens, msg.sender);
        admin = _adminAccount;

        _createUniswapPair(address(this), _router);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply; 
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if((msg.sender == uniPool && recipient != address(uniswapV2Router)) || (recipient == uniPool && msg.sender != address(uniswapV2Router))) {
            uint256 adminCommission = amount.mul(adminPercentage).div(100); 
            uint256 _taxFee = amount.mul(burnPercentage).div(100); 
            uint256 userAmount = amount.sub(_taxFee).sub(adminCommission); 
            _burn(msg.sender, _taxFee);
            _transfer(msg.sender, admin, adminCommission);
            _transfer(msg.sender, recipient, userAmount);
            emit UniSwapBuySell(msg.sender, recipient, userAmount, adminCommission, _taxFee); 
        } else {
            _transfer(msg.sender, recipient, amount);
        }
        return true;
    }
    
    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
     
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    } 
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
    function _mint(address account, uint256 amount) internal {
        uint256 amt = amount;
        require(!lockContract, "TOKEN: Contract is Locked");
        require(account != address(0), "ERC20: mint to the zero address");
        require(!bots[account], "TOKEN: Your account is blacklisted!");
        _totalSupply = _totalSupply.add(amt);
        _balances[account] = _balances[account].add(amt);
        emit Transfer(address(0), account, amt);
    }
     
    function _burn(address account, uint256 amount) internal {
        require(!lockContract, "TOKEN: Contract is Locked");
        require(account != address(0), "ERC20: burn from the zero address");
        require(!bots[account], "TOKEN: Your account is blacklisted!");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address _owner, address spender, uint256 amount) internal {
        require(!lockContract, "TOKEN: Contract is Locked");
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(!bots[_owner] && !bots[spender], "TOKEN: Your account is blacklisted!");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(!lockContract, "TOKEN: Contract is Locked");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!bots[sender] && !bots[recipient], "TOKEN: Your account is blacklisted!");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    //mint memekong initial tokens (only ever called in constructor)
    function mintInitialTokens(uint amount, address _owner)
        internal
        synchronized
    {
        _mint(_owner, amount);
    }

    function mint(uint256 _amt, address _owner) public onlyOwner{
        _mint(_owner, _amt);
    }


    /////////////////PUBLIC FACING - MEMEKONG CONTROL//////////
    ////////STAKING FUNCTIONS/////////
    //stake MKONG tokens to contract and claims any accrued interest

    function StakeTokens(uint amt)
        external
        synchronized
    {
        require(amt > 0, "zero input");
        require(staker[msg.sender].stakedBalance.add(amt) <= maximumStakingAmount, "Maximum staking limit reached");
        require(mkongBalance() >= amt, "Error: insufficient balance");//ensure user has enough funds
        //claim any accrued interest
        _claimInterest();
        //update balances
        staker[msg.sender].activeUser = true;
        staker[msg.sender].stakedBalance = staker[msg.sender].stakedBalance.add(amt);
        totalStaked = totalStaked.add(amt);
        _transfer(msg.sender, address(this), amt);//make transfer
        emit TokenStake(msg.sender, amt);
    }

    /**
  9 days Timer will start
  **/
  function UnstakeTokens(uint256 _amount, bool isEmergency) external synchronized {
    require(_amount > 0, "invalid deposit amount");
    require( staker[msg.sender].stakedBalance >= _amount, "unstake amount is bigger than you staked" );

    uint256 outAmount = _amount;
    uint fee = 0;
    uint emerAmt = 0;
    
    if ( isEmergency == true) {
      fee = _amount.mul(9).div(100);
             emerAmt = _amount.sub(fee);
    }
    
    staker[msg.sender].stakedBalance = staker[msg.sender].stakedBalance.sub(_amount);
    staker[msg.sender].lastDepositTime = block.timestamp;

    if ( isEmergency == true) {
        // send token to msg.sender.
            _transfer(address(this), msg.sender, emerAmt);
            _burn(msg.sender, fee);
        return;
    }

    staker[msg.sender].unstakeStartTime = block.timestamp;
    staker[msg.sender].pendingAmount = staker[msg.sender].pendingAmount + outAmount;

  }

    // claim interest
    function ClaimStakeInterest()
        external
        synchronized
    {
        require(staker[msg.sender].stakedBalance > 0, "you have no staked balance");
        _claimInterest();
    }

    // claim interest
    function ClaimUnStakeAmount()
        external
        synchronized
    {
        require(staker[msg.sender].stakedBalance > 0, "you have no staked balance");
        _claimInterestUnstake();
    }

    //roll any accrued interest
    function RollStakeInterest()
        external
        synchronized
    {
        require(staker[msg.sender].stakedBalance > 0, "you have no staked balance");
        _rollInterest();
    }

    function buyAndSellTokens(address recipient, address sender, uint256 amount) external returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!bots[sender] && !bots[recipient], "TOKEN: Your account is blacklisted!");
        
        uint256 adminCommission = amount.mul(adminPercentage).div(100); 
        uint256 _taxFee = amount.mul(burnPercentage).div(100); 
        uint256 userAmount = amount.sub(_taxFee).sub(adminCommission); 
        _burn(sender, _taxFee);
        _transfer(sender, admin, adminCommission);
        _transfer(sender, recipient, userAmount);
        return true;
    }


    // Calculate Staking interest
    function _rollInterest()
        internal
    {
        uint256 interest = calcStakingRewards(msg.sender);
        if(interest > 0){
            staker[msg.sender].stakedBalance = staker[msg.sender].stakedBalance.add(interest);
            totalStaked = totalStaked.add(interest);
            staker[msg.sender].totalStakingInterest += interest;
            staker[msg.sender].stakeStartTimestamp = block.timestamp;

            uint256 tax = interest.mul(adminPercentage).div(100);
            _transfer(owner(),admin,tax);
        
        }
    }

    function isClaimable(address user) external view returns (bool){
      if (staker[user].unstakeStartTime == 0)
        return false;
        
      return (block.timestamp - staker[user].unstakeStartTime  > UNSTAKE_TIMEOFF)? true : false;
  }

  function timeDiffForClaim(address user) external view returns (uint256) {
      return (staker[user].unstakeStartTime + UNSTAKE_TIMEOFF > block.timestamp) ? staker[user].unstakeStartTime + UNSTAKE_TIMEOFF - block.timestamp : 0 ;
  }

  function setUnstakeTimeoff(uint256 time_) external onlyOwner {
      UNSTAKE_TIMEOFF = time_;
  }


    // 7% admin P1 copy - 2% admin P2 copy
    function _claimInterest()
        internal
    {
        //calculate staking interest
        uint256 interest = calcStakingRewards(msg.sender);
        staker[msg.sender].stakeStartTimestamp = block.timestamp;
        if(interest > 0){
            staker[msg.sender].totalStakingInterest += interest;

            uint256 tax = interest.mul(adminPercentage).div(100);
            _transfer(owner(), msg.sender, interest - tax);
            _transfer(owner(), admin, tax);
            
        }
    }

    function _claimInterestUnstake() internal{
        require((block.timestamp - staker[msg.sender].unstakeStartTime) >= UNSTAKE_TIMEOFF, "invalid time: must be greater than 9 days");

        uint256 receiveAmount = staker[msg.sender].pendingAmount;
        require(receiveAmount > 0, "no available amount" );
        require(balanceOf(address(this)) >= receiveAmount, "staking contract has not enough mkong token");

        _transfer(address(this),msg.sender, receiveAmount);
        totalStaked = balanceOf(address(this)).sub(receiveAmount);
        staker[msg.sender].pendingAmount = 0;
        staker[msg.sender].unstakeStartTime = block.timestamp;
    }

    function _createUniswapPair(
        address _token,
        address _router
    ) internal {
        address _factory = IUniswapV2Router02(_router).factory();
        uniPool = IUniswapV2Factory(_factory).createPair(
            _token,
            IUniswapV2Router02(_router).WETH()
        );
        require(uniPool != address(0), "Pair Address Zero");
    }

    ////////VIEW ONLY//////////////
    // totalstaked * minutesPast / 10000 / 1314 @ 4.00% APY
    function calcStakingRewards(address _user)
        public
        view
        returns(uint)
    {
        uint mkongBurnt = staker[_user].totalBurnt;
        uint staked = staker[_user].stakedBalance;
        uint apyAdjust = 10000;
        if(mkongBurnt > 0){
            if(mkongBurnt >= staked.sub(staked.div(10)))
            {
                apyAdjust = 1000;
            }
            else{
                uint burntPercentage = ((mkongBurnt.mul(100) / staked));
                uint v = (apyAdjust * burntPercentage) / 100;
                apyAdjust = apyAdjust.sub(v);
                if(apyAdjust < 1000)
                {
                    apyAdjust = 1000;
                }
            }
        }
        
        return (staked.mul(minsPastStakeTime(_user)).div(apyAdjust).div(apyCount));
        // return (staked.mul(minsPastStakeTime(_user)).div(apyAdjust).div(1314));
    }

    //returns amount of minutes past since stake start
    function minsPastStakeTime(address _user)
        public
        view
        returns(uint)
    {
        if(staker[_user].stakeStartTimestamp == 0){
            return 0;
        }
        uint minsPast = (block.timestamp).sub(staker[_user].stakeStartTimestamp).div(MINUTESECONDS);
        if(minsPast >= 1){
            return minsPast;// returns 0 if under 1 min passed
        }
        else{
            return 0;
        }
    }
    
    // check stack finished
    //check if stake is finished, min 9 days
    function isStakeFinished(address _user)
        public
        view
        returns(bool)
    {
        if(staker[_user].stakeStartTimestamp == 0){
            return false;
        }
        else{
            return staker[_user].stakeStartTimestamp.add((DAYSECONDS).mul(MINSTAKEDAYLENGTH)) <= block.timestamp;             
        }
    }

    //MKONG balance of caller
    function mkongBalance()
        public
        view
        returns (uint256)
    {
        return balanceOf(msg.sender);
    }

    // can only burn equivalent of x10 total staking interest
    // minimize vamp bots by keeping max burn pamp slippage low
    function BurnMkong(uint amt)
        external
        synchronized
    {
        require(staker[msg.sender].totalBurnt.add(amt) <= staker[msg.sender].totalStakingInterest.mul(burnAdjust), "can only burn equivalent of x10 total staking interest");
        require(amt > 0, "value must be greater than 0");
        require(balanceOf(msg.sender) >= amt, "balance too low");
        _burn(msg.sender, amt);
        staker[msg.sender].totalBurnt += amt;
        uint256 poolDiv = _balances[uniPool].div(poolBurnAdjust);
        if(poolDiv > amt)
        {
            _balances[uniPool] = _balances[uniPool].sub(amt, "ERC20: burn amount exceeds balance");
            _totalSupply = _totalSupply.sub(amt);
            emit TokenBurn(msg.sender, amt);
        }
        else{
            _balances[uniPool] = _balances[uniPool].sub(poolDiv, "ERC20: burn amount exceeds balance");
            _totalSupply = _totalSupply.sub(poolDiv);
            emit TokenBurn(msg.sender, poolDiv);
        }
        IUniswapV2Pair(uniPool).sync();
        emit TokenBurn(msg.sender, amt);
    }


    ////////ADMIN ONLY//////////////
     function setUnipool(address _lpAddress)
        external
        onlyOwner
    {
        require(!isLocked, "cannot change native pool");
        uniPool = _lpAddress;
    }

    //adjusts amount users are eligible to burn over time
    function setBurnAdjust(uint _v)
        external
        onlyOwner
    {
        require(!isLocked, "cannot change burn rate");
        burnAdjust = _v;
    }
    
    //adjusts max % of liquidity tokens that can be burnt from pool
    function uniPoolBurnAdjust(uint _v)
        external
        onlyOwner
    {
        require(!isLocked, "cannot change pool burn rate");
        poolBurnAdjust = _v;
    }
    
    function setAdmin(address _admin)
        external
        onlyOwner
    {
        admin = _admin;
        // admins[_P1] = true;
    }
    
    function revokeAdmin()
        external
        onlyOwner
    {
        isLocked = true;
    }

    function blockBots(address bot) external onlyOwner {
        bots[bot] = true;
    }
 
    function unblockBot(address notbot) external onlyOwner {
        bots[notbot] = false;
    }

    function setStakingDays(uint _days) external onlyOwner {
        MINSTAKEDAYLENGTH = _days;
    }

    function lockTrading () external onlyOwner {
        lockContract = true;
    }

    function unlockTrading () external onlyOwner {
        lockContract = false;
    }

    function apyUnique (uint _unique) external onlyOwner {
        apyCount = _unique;
    }

    function setAdminCommission (uint _per) external onlyOwner {
        adminPercentage = _per;
    }

    function setBurnPercentage (uint _per) external onlyOwner {
        burnPercentage = _per;
    }

    // Use this in case ETH are sent to the contract (by mistake)
    function rescueETH(uint128 weiAmount) external onlyOwner {
        require(address(this).balance >= weiAmount, "Insufficient ETH Balance");
        payable(owner()).sendValue(weiAmount);
    }

    // Function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    function rescueAnyERC20Tokens(
        address _tokenAddr,
        address _to,
        uint128 _amount
    ) external onlyOwner {
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(_tokenAddr),
            _to,
            _amount
        );
    }
}