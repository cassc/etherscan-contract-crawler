// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./libraries/BoringMath.sol";
import "./libraries/SignedSafeMath.sol";
import "./libraries/BoringERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
/************************************************************************************************
Originally from
https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChefV2.sol
and
https://github.com/sdaoswap/sushiswap/blob/master/contracts/MasterChef.sol
This source code has been modified from the original, which was copied from the github repository
at commit hash 10148a31d9192bc803dac5d24fe0319b52ae99a4.
*************************************************************************************************/


contract SDAOTokenStaking is Ownable,ReentrancyGuard {
  using BoringMath for uint256;
  using BoringERC20 for IERC20;
  using SignedSafeMath for int256;

  //==========  Structs  ==========
  
  /// @dev Info of each user.
  /// @param amount LP token amount the user has provided.
  /// @param rewardDebt The amount of rewards entitled to the user.
  struct UserInfo {
    uint256 amount;
    int256 rewardDebt;
  }


  /// @dev Info of each rewards pool.
  /// @param tokenPerBlock Reward tokens per block number.
  /// @param lpSupply Total staked amount.
  /// @param accRewardsPerShare Total rewards accumulated per staked token.
  /// @param lastRewardBlock Last time rewards were updated for the pool.
  /// @param endOfEpochBlock End of epoc block number for compute and to avoid deposits.
  struct PoolInfo {
    uint256 tokenPerBlock;
    uint256 lpSupply;
    uint256 accRewardsPerShare;
    uint256 lastRewardBlock;
    uint256 endOfEpochBlock;
  }

  //==========  Constants  ==========

  /// @dev For percision calculation while computing the rewards.
  uint256 private constant ACC_REWARDS_PRECISION = 1e18;

  /// @dev ERC20 token used to distribute rewards.   
  IERC20 public immutable rewardsToken;

  /** ==========  Storage  ========== */

  /// @dev Indicates whether a staking pool exists for a given staking token.
  //mapping(address => bool) public stakingPoolExists;
  
  /// @dev Info of each staking pool.
  PoolInfo[] public poolInfo;
  
  /// @dev Address of the LP token for each staking pool.
  mapping(uint256 => IERC20) public lpToken;
  
  /// @dev Info of each user that stakes tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  /// @dev Total rewards received from governance for distribution.
  /// Used to return remaining rewards if staking is canceled.
  uint256 public totalRewardsReceived;

  // ==========  Events  ==========

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
  event LogPoolAddition(uint256 indexed pid, IERC20 indexed lpToken);
  event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accRewardsPerShare);
  event RewardsAdded(uint256 amount);
  event ExtendPool(uint256 indexed pid, uint256 rewardBlock, uint256 endOfEpochBlock);

  // ==========  Constructor  ==========

  /// @dev During the deployment of the contract pass the ERC-20 contract address used for rewards.
  constructor(address _rewardsToken) public {
    rewardsToken = IERC20(_rewardsToken);
  }

  /// @dev Add rewards to be distributed.
  /// Note: This function must be used to add rewards if the owner
  /// wants to retain the option to cancel distribution and reclaim
  /// undistributed tokens.  
  function addRewards(uint256 amount) external onlyOwner {
    
    require(rewardsToken.balanceOf(msg.sender) > 0, "ERC20: not enough tokens to transfer");

    totalRewardsReceived = totalRewardsReceived.add(amount);
    rewardsToken.safeTransferFrom(msg.sender, address(this), amount);
    
    emit RewardsAdded(amount);
  }

  // ==========  Pools  ==========
  
  /// @dev Add a new LP to the pool.
  /// Can only be called by the owner or the points allocator.
  /// @param _lpToken Address of the LP ERC-20 token.
  /// @param _sdaoPerBlock Rewards per block.
  /// @param _endOfEpochBlock Epocs end block number.
  function add(IERC20 _lpToken, uint256 _sdaoPerBlock, uint256 _endOfEpochBlock) public onlyOwner {

    //This is not needed as we are going to use the contract for multiple pools with the same LP Tokens
    //require(!stakingPoolExists[address(_lpToken)], " Staking pool already exists.");
    
    require(_endOfEpochBlock > block.number, "Cannot create the pool for past time.");

    uint256 pid = poolInfo.length;

    lpToken[pid] = _lpToken;

    poolInfo.push(PoolInfo({
      tokenPerBlock: _sdaoPerBlock,
      endOfEpochBlock:_endOfEpochBlock,
      lastRewardBlock: block.number,
      lpSupply:0,
      accRewardsPerShare: 0
    }));

    //stakingPoolExists[address(_lpToken)] = true;

    emit LogPoolAddition(pid, _lpToken);
  }

  /// @dev Add a new LP to the pool.
  /// Can only be called by the owner or the points allocator.
  /// @param _pid Pool Id to extend the schedule.
  /// @param _sdaoPerBlock Rewards per block.
  /// @param _endOfEpochBlock Epocs end block number.
  function extendPool(uint256 _pid, uint256 _sdaoPerBlock, uint256 _endOfEpochBlock) public onlyOwner {
    
    require(_endOfEpochBlock > block.number && _endOfEpochBlock > poolInfo[_pid].endOfEpochBlock, "Cannot extend the pool for past time.");

    // Update the accumulated rewards
    PoolInfo memory pool = updatePool(_pid);

    pool.tokenPerBlock = _sdaoPerBlock;
    pool.endOfEpochBlock = _endOfEpochBlock;
    pool.lastRewardBlock = block.number;

    // Update the Pool Storage
    poolInfo[_pid] = pool;

    emit ExtendPool(_pid, _sdaoPerBlock, _endOfEpochBlock);
  }

  /// @dev To get the rewards per block.
  function sdaoPerBlock(uint256 _pid) public view returns (uint256 amount) {
      PoolInfo memory pool = poolInfo[_pid];
      amount = pool.tokenPerBlock;
  }

  /// @dev Update reward variables for all pools in `pids`.
  /// Note: This can become very expensive.
  /// @param pids Pool IDs of all to be updated. Make sure to update all active pools.
  function massUpdatePools(uint256[] calldata pids) external onlyOwner {
    uint256 len = pids.length;
    for (uint256 i = 0; i < len; ++i) {
      updatePool(pids[i]);
    }
  }


  /// @dev Update reward variables of the given pool.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @return pool Returns the pool that was updated.
 function updatePool(uint256 _pid) private returns (PoolInfo memory pool) {

    pool = poolInfo[_pid];
    uint256 lpSupply = pool.lpSupply;

    if (block.number > pool.lastRewardBlock && pool.lastRewardBlock < pool.endOfEpochBlock) {

       if(lpSupply > 0){
         
           uint256 blocks;
           if(block.number < pool.endOfEpochBlock) {
             blocks = block.number.sub(pool.lastRewardBlock);
           } else {
             blocks = pool.endOfEpochBlock.sub(pool.lastRewardBlock);
          }

          uint256 sdaoReward = blocks.mul(sdaoPerBlock(_pid));
          pool.accRewardsPerShare = pool.accRewardsPerShare.add((sdaoReward.mul(ACC_REWARDS_PRECISION) / lpSupply));

       }

       pool.lastRewardBlock = block.number;
       poolInfo[_pid] = pool;
       emit LogUpdatePool(_pid, pool.lastRewardBlock, lpSupply, pool.accRewardsPerShare);

    }

  }



  // ==========  Users  ==========

  /// @dev View function to see pending rewards on frontend.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _user Address of user.
  /// @return pending rewards for a given user.
  function pendingRewards(uint256 _pid, address _user) external view returns (uint256 pending) {

    PoolInfo memory pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];

    uint256 accRewardsPerShare = pool.accRewardsPerShare;
    uint256 lpSupply = pool.lpSupply;

    if (block.number > pool.lastRewardBlock && pool.lastRewardBlock < pool.endOfEpochBlock) {

      if(lpSupply > 0){

        uint256 blocks;

        if(block.number < pool.endOfEpochBlock) {
            blocks = block.number.sub(pool.lastRewardBlock);
        } else {
          blocks = pool.endOfEpochBlock.sub(pool.lastRewardBlock);
        }
        
        uint256 sdaoReward = blocks.mul(sdaoPerBlock(_pid));
        accRewardsPerShare = accRewardsPerShare.add(sdaoReward.mul(ACC_REWARDS_PRECISION) / lpSupply);

      }

    }

    pending = int256(user.amount.mul(accRewardsPerShare) / ACC_REWARDS_PRECISION).sub(user.rewardDebt).toUInt256();
  }


  /// @dev Deposit LP tokens to earn rewards.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _amount LP token amount to deposit.
  /// @param _to The receiver of `_amount` deposit benefit.
  function deposit(uint256 _pid, uint256 _amount, address _to) external nonReentrant {

    // Input Validation
    require(_amount > 0 && _to != address(0), "Invalid inputs for deposit.");

    PoolInfo memory pool = updatePool(_pid);
    UserInfo storage user = userInfo[_pid][_to];

    // check if epoch as ended or if pool doesnot exist 
    require (pool.endOfEpochBlock > block.number,"This pool epoch has ended. Please join staking new session.");
    
    user.amount = user.amount.add(_amount);
    user.rewardDebt = user.rewardDebt.add(int256(_amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION));

    // Add to total supply
    pool.lpSupply = pool.lpSupply.add(_amount);
    // Update the pool back
    poolInfo[_pid] = pool;

    // Interactions
    lpToken[_pid].safeTransferFrom(msg.sender, address(this), _amount);

    emit Deposit(msg.sender, _pid, _amount, _to);
  }

  /// @dev Withdraw LP tokens from the staking contract.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _amount LP token amount to withdraw.
  /// @param _to Receiver of the LP tokens.
  function withdraw(uint256 _pid, uint256 _amount, address _to) external nonReentrant {

    require(_to != address(0), "ERC20: transfer to the zero address");

    PoolInfo memory pool = updatePool(_pid);
    UserInfo storage user = userInfo[_pid][msg.sender];

    // Check whether user has deposited stake
    require(user.amount >= _amount && _amount > 0, "Invalid amount to withdraw.");

    // Effects
    user.rewardDebt = user.rewardDebt.sub(int256(_amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION));
    user.amount = user.amount.sub(_amount);

    // Subtract from total supply
    pool.lpSupply = pool.lpSupply.sub(_amount);
    // Update the pool back
    poolInfo[_pid] = pool;

    // Interactions
    lpToken[_pid].safeTransfer(_to, _amount);

    emit Withdraw(msg.sender, _pid, _amount, _to);
  }


   /// @dev Harvest proceeds for transaction sender to `_to`.
   /// @param _pid The index of the pool. See `poolInfo`.
   /// @param _to Receiver of rewards.
   function harvest(uint256 _pid, address _to) external nonReentrant {
    
    require(_to != address(0), "ERC20: transfer to the zero address");

    PoolInfo memory pool = updatePool(_pid);
    UserInfo storage user = userInfo[_pid][msg.sender];

    int256 accumulatedRewards = int256(user.amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION);
    uint256 _pendingRewards = accumulatedRewards.sub(user.rewardDebt).toUInt256();

    // Effects
    user.rewardDebt = accumulatedRewards;

    // Interactions
    if(_pendingRewards > 0 ) {
      rewardsToken.safeTransfer(_to, _pendingRewards);
    }
    
    emit Harvest(msg.sender, _pid, _pendingRewards);
  }

  //// @dev Withdraw LP tokens and harvest accumulated rewards, sending both to `to`.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _amount LP token amount to withdraw.
  /// @param _to Receiver of the LP tokens and rewards.
  function withdrawAndHarvest(uint256 _pid, uint256 _amount, address _to) external nonReentrant {

    require(_to != address(0), "ERC20: transfer to the zero address");

    PoolInfo memory pool = updatePool(_pid);
    UserInfo storage user = userInfo[_pid][msg.sender];

    // Check if the user has stake in the pool
    require(user.amount >= _amount && _amount > 0, "Cannot withdraw more than staked.");

    int256 accumulatedRewards = int256(user.amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION);
    uint256 _pendingRewards = accumulatedRewards.sub(user.rewardDebt).toUInt256();

    // Effects
    user.rewardDebt = accumulatedRewards.sub(int256(_amount.mul(pool.accRewardsPerShare) / ACC_REWARDS_PRECISION));
    user.amount = user.amount.sub(_amount);

    // Subtract from total supply
    pool.lpSupply = pool.lpSupply.sub(_amount);
    // Update the pool back
    poolInfo[_pid] = pool;

    // Interactions
    if(_pendingRewards > 0) {
      rewardsToken.safeTransfer(_to, _pendingRewards);
    }
    lpToken[_pid].safeTransfer(_to, _amount);

    emit Harvest(msg.sender, _pid, _pendingRewards);
    emit Withdraw(msg.sender, _pid, _amount, _to);
  }


  /// @dev Withdraw without caring about rewards. EMERGENCY ONLY.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _to Receiver of the LP tokens.  
  function emergencyWithdraw(uint256 _pid, address _to) external nonReentrant { 

    require(_to != address(0), "ERC20: transfer to the zero address");

    UserInfo storage user = userInfo[_pid][msg.sender];
    uint256 amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;

    PoolInfo memory pool = updatePool(_pid);
    pool.lpSupply = pool.lpSupply.sub(amount);
    // Update the pool back
    poolInfo[_pid] = pool;

    // Note: transfer can fail or succeed if `amount` is zero.
    lpToken[_pid].safeTransfer(_to, amount);

    emit EmergencyWithdraw(msg.sender, _pid, amount, _to);
  }


  function withdrawETHAndAnyTokens(address token) external onlyOwner {
    msg.sender.send(address(this).balance);
    IERC20 Token = IERC20(token);
    uint256 currentTokenBalance = Token.balanceOf(address(this));
    Token.safeTransfer(msg.sender, currentTokenBalance); 
  }

  // ==========  Getter Functions  ==========

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }



}