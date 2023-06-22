// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SDAOClaimpad is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  struct UserInfo {
    uint256 allocated;
    uint256 claimed;
  }

  struct EmissionPeriod {
    uint256 startOfEmissions;
    uint256 endOfVestingCliff;
    uint256 endOfEmissions;
    bool vestingCliffAccrues;
  }
  
  struct PoolInfo {
    address claimToken;
    uint256 allocatedAmount;

    EmissionPeriod emissionPeriod;

    uint256 instantUnlockRatio; // % of emissions to unlock instantly at start of emission period in 0.01% basis points
    uint256 totalClaimed;
  }

  struct Allocation {
    uint256 pid;
    uint256 amount;
    address user;
  }
  
  //==========  Constants  ==========
  uint256 public constant MAX_BASIS_POINTS = 10000; // 100.00% or 10k bps

  /// @dev MAX Pools allowed in the contract to avoid Block gas limits
  uint256 public constant MAX_POOLS_ALLOWED = 50;

  /** ==========  Storage  ========== */
  /// @dev Info of each launch pool.
  PoolInfo[] public poolInfo;
  
  /// @dev Info of each user that has allocated tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  
  /// @dev Info for total reserved amount per claimtoken.
  mapping(address => uint256) public reservedAmount;
  
  // ==========  Events  ==========
  event PoolAdded(uint256 indexed pid, address indexed token, uint256 startOfEmissions, uint256 endOfEmissions);
  event Allocated(address indexed user, uint256 indexed pid, uint256 amount, address indexed token);
  event Deallocated(address indexed user, uint256 indexed pid, uint256 amount, address indexed token);
  event Claimed(address indexed user, uint256 indexed pid, uint256 amount);

  //*** External functions ***//

  /// @dev Add a new launchpad pool.
  /// Can only be called by the owner
  function createPool(address _token,
                      uint256 _startOfEmissions,
                      uint256 _endOfVestingCliff,
                      uint256 _endOfEmissions,
                      bool _vestingCliffAccrues,
                      uint256 _instantUnlockRatio)
           external onlyOwner {
    require(_token != address(0), "ERR_ZERO_ADDRESS");
    require(_instantUnlockRatio < MAX_BASIS_POINTS, "ERR_INSTANT_UNLOCK_RATIO");
    require(_startOfEmissions < _endOfEmissions, "ERR_START_EMISSIONS");
    require(_endOfVestingCliff >= _startOfEmissions
            && _endOfVestingCliff <= _endOfEmissions,
            "ERR_END_OF_VESTING_CLIFF");
    require(_endOfEmissions > block.timestamp, "ERR_END_EMISSIONS");

    uint256 pid = poolInfo.length;

    // To restrict the number of pools per contract instance
    require(pid <= MAX_POOLS_ALLOWED - 1, "ERR_MAX_POOLS_ALLOWED");

    poolInfo.push(PoolInfo({
      claimToken: _token,
      allocatedAmount: 0,
      emissionPeriod: EmissionPeriod({
                        startOfEmissions: _startOfEmissions,
                        endOfVestingCliff: _endOfVestingCliff,
                        endOfEmissions: _endOfEmissions,
                        vestingCliffAccrues: _vestingCliffAccrues
                      }),
      instantUnlockRatio: _instantUnlockRatio,
      totalClaimed: 0
    }));

    emit PoolAdded(pid, _token,  _startOfEmissions, _endOfEmissions);
  }

  // Recover any tokens accidentally sent to the contract excluding properly deposited or bought tokens
  function recoverAnyTokens(address token) external onlyOwner {
    require(token != address(0), "ERR_ZERO_ADDRESS");
    
    if(address(this).balance > 0) {
      (bool success, ) = (msg.sender).call{value: address(this).balance}("");
      require(success, "ERR_TRANSFER_ETH");
    }

    uint256 reservedTokens = reservedAmount[token];
    uint256 currentTokenBalance = IERC20(token).balanceOf(address(this));
    require(currentTokenBalance > reservedTokens, "ERR_NO_EXCESS_TOKENS");
    uint256 excessTokens = currentTokenBalance - reservedTokens;
    IERC20(token).safeTransfer(msg.sender, excessTokens); 
    
  }

  //*** External view functions ***//

  function nrOfPools() external view returns (uint256) {
    return poolInfo.length;
  }

  function getPoolClaimToken(uint256 _pid) external view returns (address) {
      return poolInfo[_pid].claimToken;
  }

  //*** Public functions ***//

  /// @dev Allocate tokens to be entitled for launch tokens.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _amount Token amount to deposit.
  /// @param _to The wallet entitled to claim `_amount` deposit benefit.
  function allocateFor(uint256 _pid,
                      uint256 _amount,
                      address _to)
           public onlyOwner {
    require(_pid < poolInfo.length, "ERR_POOLID");
    require(_to != address(0), "ERR_ZERO_ADDRESS");

    //PoolInfo memory pool = poolInfo[_pid];
    address claimToken = poolInfo[_pid].claimToken;
    UserInfo storage user = userInfo[_pid][_to];
    
    uint256 reservedClaimTokens = reservedAmount[claimToken];
    require(IERC20(claimToken).balanceOf(address(this)) >= _amount + reservedClaimTokens
           , "ERR_CLAIMPAD_BALANCE");

    user.allocated += _amount;
    poolInfo[_pid].allocatedAmount += _amount;
    reservedAmount[claimToken] += _amount;

    emit Allocated(_to, _pid, _amount, claimToken);
  }
  
  function bulkAllocate(Allocation[] calldata allocations) external {
     uint256 nrOfAllocations = allocations.length;
     for (uint256 i = 0; i < nrOfAllocations; i++) {
        allocateFor(allocations[i].pid, allocations[i].amount, allocations[i].user);
     }
  }
  
  function remove(uint256 _pid, address _user) public onlyOwner {
     require(_pid < poolInfo.length, "ERR_POOLID");
     require(_user != address(0), "ERR_ZERO_ADDRESS");
     PoolInfo storage pool = poolInfo[_pid];
     UserInfo storage user = userInfo[_pid][_user];
     uint256 left = user.allocated - user.claimed;
     user.allocated -= left;
     pool.allocatedAmount -= left;
     reservedAmount[pool.claimToken] -= left;
     emit Deallocated(_user, _pid, left, pool.claimToken);
  }
  
  function removeAll(address _user) external {
    uint256 pids = poolInfo.length;
    for (uint256 pid = 0; pid < pids; pid++) {
      if (userInfo[pid][_user].allocated > 0) {
         remove(pid, _user);
      }
    }     
  }

  /// @dev Claim proceeds for transaction sender to `_to`.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _to Receiver of rewards.
  function claim(uint256 _pid, address _to) external {
    require(_pid < poolInfo.length, "ERR_POOLID");
    require(_to != address(0), "ERR_ZERO_ADDRESS");

    uint256 claimable = claimableTokens(_pid, msg.sender);
    require(claimable > 0, "ERR_ZERO_CLAIMABLE");
	
    // Interactions
    UserInfo storage user = userInfo[_pid][msg.sender];
    user.claimed += claimable;
    PoolInfo storage pool = poolInfo[_pid];
    pool.totalClaimed += claimable;
    reservedAmount[pool.claimToken] -= claimable;

    IERC20(pool.claimToken).safeTransfer(_to, claimable);
    emit Claimed(msg.sender, _pid, claimable);
  }

  //*** Public view functions ***//
  
  /// @dev View function to see claimable tokens on frontend.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _user Address of user.
  /// @return claimableAmount tokens for a given user.
  function claimableTokens(uint256 _pid, address _user) public view returns (uint256 claimableAmount) {
    require(_pid < poolInfo.length, "ERR_POOLID");
    PoolInfo memory pool = poolInfo[_pid];
    if (pool.emissionPeriod.startOfEmissions > block.timestamp) {
       return 0;
    }
    UserInfo memory user = userInfo[_pid][_user];
    uint256 allocatedAmount = user.allocated;
    uint256 instantUnlockedAmount = allocatedAmount * pool.instantUnlockRatio / MAX_BASIS_POINTS;
    uint256 vestedAmount = allocatedAmount - instantUnlockedAmount;
    uint256 startOfEmissions = pool.emissionPeriod.vestingCliffAccrues 
                               ? pool.emissionPeriod.startOfEmissions 
                               : pool.emissionPeriod.endOfVestingCliff;
    uint256 totalEmissionSeconds = pool.emissionPeriod.endOfEmissions - startOfEmissions;
    uint256 emissionPassed = (block.timestamp < pool.emissionPeriod.endOfEmissions)
                             ? (block.timestamp > startOfEmissions ? block.timestamp - startOfEmissions : 0)
                             : totalEmissionSeconds;
    uint256 vestedUnlockedAmount = (block.timestamp >= pool.emissionPeriod.endOfVestingCliff)
                                   ? vestedAmount * emissionPassed / totalEmissionSeconds
                                   : 0;
    uint256 unlockedAmount = instantUnlockedAmount + vestedUnlockedAmount;
    claimableAmount = unlockedAmount - user.claimed;
  }


}