// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./WhitelistedPoolVerifier.sol";

contract SDAOLaunchpad is WhitelistedPoolVerifier, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  struct UserInfo {
    uint256 deposited;
    uint256 claimed;
  }

  struct EmissionPeriod {
    uint256 startOfEmissions;
    uint256 endOfVestingCliff;
    uint256 endOfEmissions;
    bool vestingCliffAccrues;
  }
  
  struct PoolInfo {
    address depositToken;
    uint256 depositedAmount;

    uint256 minDeposit;
    uint256 maxDeposit;
    uint256 startOfDeposits;
    uint256 endOfDeposits;
    
    uint256 price;
    EmissionPeriod emissionPeriod;
    bool collected;

    uint256 cappedTotalDeposits; // maximum total pool deposits
    uint256 instantUnlockRatio; // % of emissions to unlock instantly at start of emission period in 0.01% basis points
    uint256 totalClaimed;
  }

  //==========  Constants  ==========
  uint256 public constant MAX_BASIS_POINTS = 10000; // 100.00% or 10k bps

  /// @dev MAX Pools allowed in the contract to avoid Block gas limits
  uint256 public constant MAX_POOLS_ALLOWED = 50;

  /// @dev ERC20 launch token to distribute.   
  address public immutable launchToken;
  /// @dev For precision calculation while computing the vesting.
  uint256 public immutable launchTokenPrecision;

  /** ==========  Storage  ========== */
  /// @dev Info of each launch pool.
  PoolInfo[] public poolInfo;
  
  /// @dev Info of each user that stakes tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;
  
  uint256 public reservedLaunchTokens;

  // ==========  Events  ==========
  event PoolAdded(uint256 indexed pid, address indexed token);
  event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address token, address indexed to);
  event UpdatedEmissions(uint256 indexed pid, uint256 startOfEmissions, uint256 endOfEmissions);
  event CollectedDeposits(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
  event Claimed(address indexed user, uint256 indexed pid, uint256 amount);

  // ==========  Constructor  ==========

  /// @dev During the deployment of the contract pass the ERC-20 contract address used for rewards.
  constructor(address _launchToken) {

    // Check the input parameter
    require(_launchToken != address(0), "Invalid launch token");

    launchToken = _launchToken;
    launchTokenPrecision = 10 ** IERC20Metadata(launchToken).decimals();
    _setSigner(msg.sender);
  }

  //*** External functions ***//

  /// @dev Add a new launchpad pool.
  /// Can only be called by the owner
  function createPool(address _token,
                      uint256 _minDeposit,
                      uint256 _maxDeposit,
                      uint256 _startOfDeposits,
                      uint256 _endOfDeposits,
                      uint256 _price,
                      uint256 _cappedTotalDeposits,
                      uint256 _instantUnlockRatio)
           external onlyOwner {
    require(_token != address(0), "ERR_ZERO_ADDRESS");
    require(_maxDeposit > 0 && _maxDeposit > _minDeposit, "ERR_MAX_DEPOSIT");
    require(_startOfDeposits < _endOfDeposits, "ERR_START_DEPOSITS");
    require(_endOfDeposits > block.timestamp, "ERR_END_DEPOSITS");
    require(_price > 0, "ERR_PRICE");
    require(_instantUnlockRatio < MAX_BASIS_POINTS, "ERR_INSTANT_UNLOCK_RATIO");

    uint256 pid = poolInfo.length;

    // To restrict the number of pools per contract instance
    require(pid <= MAX_POOLS_ALLOWED, "Pool size exceeded");

    poolInfo.push(PoolInfo({
      depositToken: _token,
      depositedAmount: 0,

      minDeposit: _minDeposit,
      maxDeposit: _maxDeposit,
      startOfDeposits: _startOfDeposits,
      endOfDeposits: _endOfDeposits,

      price: _price,
      emissionPeriod: EmissionPeriod({
                        startOfEmissions: 0,
                        endOfVestingCliff: 0,
                        endOfEmissions: 0,
                        vestingCliffAccrues: false
                      }),
      collected: false,
      cappedTotalDeposits: _cappedTotalDeposits,
      instantUnlockRatio: _instantUnlockRatio,
      totalClaimed: 0
    }));

    emit PoolAdded(pid, _token);
  }

  function setEmission(uint256 _pid, 
                       uint256 _startOfEmissions, 
                       uint256 _endOfVestingCliff, 
                       uint256 _endOfEmissions, 
                       bool _vestingCliffAccrues)
    external onlyOwner {
    require(_pid < poolInfo.length, "ERR_POOLID");
    require(poolInfo[_pid].emissionPeriod.startOfEmissions == 0, "ERR_ALREADY_DEFINED");
    require(_startOfEmissions < _endOfEmissions, "ERR_START_EMISSIONS");
    require(_endOfVestingCliff >= _startOfEmissions
            && _endOfVestingCliff <= _endOfEmissions,
            "ERR_END_OF_VESTING_CLIFF");
    require(_endOfEmissions > block.timestamp, "ERR_END_EMISSIONS");

    EmissionPeriod memory emissionPeriod = poolInfo[_pid].emissionPeriod;
    emissionPeriod.startOfEmissions = _startOfEmissions;
    emissionPeriod.endOfVestingCliff = _endOfVestingCliff;
    emissionPeriod.endOfEmissions = _endOfEmissions;
    emissionPeriod.vestingCliffAccrues = _vestingCliffAccrues;
    
    poolInfo[_pid].emissionPeriod = emissionPeriod;
    emit UpdatedEmissions(_pid, _startOfEmissions, _endOfEmissions);
  }

  /// @dev Withdraw tokens from the launchpad contract.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _to Receiver of the tokens.
  function collectDeposits(uint256 _pid, address _to) external nonReentrant onlyOwner {
    require(_pid < poolInfo.length, "ERR_POOLID");
    require(_to != address(0), "ERR_ZERO_ADDRESS");

    PoolInfo memory pool = poolInfo[_pid];
    require(pool.depositedAmount > 0, "ERR_NO_DEPOSITS");
    require(pool.endOfDeposits < block.timestamp, "ERR_OPEN_DEPOSITS");
    require(pool.emissionPeriod.startOfEmissions > 0, "ERR_NO_EMISSIONS");
    require(!pool.collected, "ERR_ALREADY_COLLECTED");

    // Effects
    pool.collected = true;
    poolInfo[_pid] = pool;

    // Interactions
    IERC20(pool.depositToken).safeTransfer(_to, pool.depositedAmount);
    emit CollectedDeposits(msg.sender, _pid, pool.depositedAmount, _to);
  }

  function setSigner(address signer) external onlyOwner{
    require(signer != address(0), "ERR_ZERO_ADDRESS");
    _setSigner(signer);
  }

  // Recover any tokens accidentally sent to the contract excluding properly deposited or bought tokens
  function recoverAnyTokens(address token) external onlyOwner {
    require(token != address(0), "ERR_ZERO_ADDRESS");
    
    (bool success, ) = (msg.sender).call{value: address(this).balance}("");
    require(success, "ERR_TRANSFER_ETH");
    
    uint256 reservedTokens = 0;
    uint256 pids = poolInfo.length;
    for (uint256 pid = 0; pid < pids; pid++) {
      PoolInfo memory pool = poolInfo[pid];
      if (token == pool.depositToken && !pool.collected) {
         reservedTokens += pool.depositedAmount;
      } else if (token == launchToken) {
         uint256 totalSold = pool.depositedAmount * launchTokenPrecision / pool.price;
         reservedTokens += totalSold - pool.totalClaimed;
      }
    }
    uint256 currentTokenBalance = IERC20(token).balanceOf(address(this));
    require(currentTokenBalance > reservedTokens, "ERR_NO_EXCESS_TOKENS");
    uint256 excessTokens = currentTokenBalance - reservedTokens;
    IERC20(token).safeTransfer(msg.sender, excessTokens); 
  }

  /// @dev Claim all pools for end user
  function claimAll() external {
    bool claimed;
    uint256 pids = poolInfo.length;
    for (uint256 pid = 0; pid < pids; pid++) {
      if (claimableTokens(pid, msg.sender) > 0) {
         claim(pid, msg.sender);
         claimed = true;
      }
    }
    require(claimed, "ERR_ZERO_CLAIMABLE");
  }

  //*** External view functions ***//

  function nrOfPools() external view returns (uint256) {
    return poolInfo.length;
  }

  function getPoolDepositToken(uint256 _pid) external view returns (address) {
      return poolInfo[_pid].depositToken;
  }

  //*** Public functions ***//

  /// @dev Deposit tokens to be entitled for launch tokens.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _amount Token amount to deposit.
  function deposit(uint256 _pid,
                   uint256 _amount,
                   string calldata _salt,
                   bytes memory _signature)
           external {
    depositFor(_pid, _amount, msg.sender, _salt, _signature);
  }

  /// @dev Deposit tokens to be entitle for launch tokens.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _amount Token amount to deposit.
  /// @param _to The wallet entitled to claim `_amount` deposit benefit.
  function depositFor(uint256 _pid,
                      uint256 _amount,
                      address _to,
                      string calldata _salt,
                      bytes memory _signature)
           public nonReentrant {
    require(_pid < poolInfo.length, "ERR_POOLID");
    require(_to != address(0), "ERR_ZERO_ADDRESS");

    PoolInfo memory pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_to];

    // check if deposit window is valid 
    require(pool.startOfDeposits < block.timestamp,"ERR_BEFORE_DEPOSITS_START");
    require(pool.endOfDeposits > block.timestamp,"ERR_AFTER_DEPOSITS_END");

    require(user.deposited +_amount >= pool.minDeposit, "ERR_MIN_DEPOSIT");
    require(user.deposited + _amount <= pool.maxDeposit, "ERR_MAX_DEPOSIT");
    
    require(pool.depositedAmount + _amount <= pool.cappedTotalDeposits, "ERR_POOL_SOLD_OUT");
    
    require(IERC20(pool.depositToken).balanceOf(msg.sender) >= _amount, "ERR_DEPOSIT_BALANCE");
    require(IERC20(pool.depositToken).allowance(msg.sender, address(this)) >= _amount, "ERR_DEPOSIT_ALLOWANCE");
    
    uint256 boughtTokens = _amount * launchTokenPrecision / pool.price;
    require(IERC20(launchToken).balanceOf(address(this)) >= boughtTokens + reservedLaunchTokens
           , "ERR_LAUNCHPAD_BALANCE");

    require(isValidSignature(_salt, _pid, _to, _signature), "ERR_WHITELIST");
    
    reservedLaunchTokens += boughtTokens;
    user.deposited += _amount;
    pool.depositedAmount += _amount;
    // Update the pool back
    poolInfo[_pid] = pool;

    // Interactions
    IERC20(pool.depositToken).safeTransferFrom(msg.sender, address(this), _amount);

    emit Deposit(msg.sender, _pid, _amount, pool.depositToken, _to);
  }

  /// @dev Claim proceeds for transaction sender to `_to`.
  /// @param _pid The index of the pool. See `poolInfo`.
  /// @param _to Receiver of rewards.
  function claim(uint256 _pid, address _to) public {
    require(_pid < poolInfo.length, "ERR_POOLID");
    require(_to != address(0), "ERR_ZERO_ADDRESS");

    uint256 claimable = claimableTokens(_pid, msg.sender);
    require(claimable > 0, "ERR_ZERO_CLAIMABLE");
	
    // Interactions
    reservedLaunchTokens -= claimable;
    UserInfo storage user = userInfo[_pid][msg.sender];
    user.claimed += claimable;
    PoolInfo storage pool = poolInfo[_pid];
    pool.totalClaimed += claimable;

    IERC20(launchToken).safeTransfer(_to, claimable);
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
    if (pool.emissionPeriod.startOfEmissions == 0
        || pool.emissionPeriod.startOfEmissions > block.timestamp) {
       return 0;
    }
    UserInfo memory user = userInfo[_pid][_user];
    uint256 boughtAmount = user.deposited * launchTokenPrecision / pool.price;
    uint256 instantUnlockedAmount = boughtAmount * pool.instantUnlockRatio / MAX_BASIS_POINTS;
    uint256 vestedAmount = boughtAmount - instantUnlockedAmount;
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