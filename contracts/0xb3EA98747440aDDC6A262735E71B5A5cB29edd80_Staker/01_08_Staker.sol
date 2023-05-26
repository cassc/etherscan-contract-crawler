// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
  @title An asset staking contract.
  @author Tim Clancy

  This staking contract disburses tokens from its internal reservoir according
  to a fixed emission schedule. Assets can be assigned varied staking weights.
  This code is inspired by and modified from Sushi's Master Chef contract.
  https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol
*/
contract Staker is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // A user-specified, descriptive name for this Staker.
  string public name;

  // The token to disburse.
  IERC20 public token;

  // The amount of the disbursed token deposited by users. This is used for the
  // special case where a staking pool has been created for the disbursed token.
  // This is required to prevent the Staker itself from reducing emissions.
  uint256 public totalTokenDeposited;

  // A flag signalling whether the contract owner can add or set developers.
  bool public canAlterDevelopers;

  // An array of developer addresses for finding shares in the share mapping.
  address[] public developerAddresses;

  // A mapping of developer addresses to their percent share of emissions.
  // Share percentages are represented as 1/1000th of a percent. That is, a 1%
  // share of emissions should map an address to 1000.
  mapping (address => uint256) public developerShares;

  // A flag signalling whether or not the contract owner can alter emissions.
  bool public canAlterTokenEmissionSchedule;
  bool public canAlterPointEmissionSchedule;

  // The token emission schedule of the Staker. This emission schedule maps a
  // block number to the amount of tokens or points that should be disbursed with every
  // block beginning at said block number.
  struct EmissionPoint {
    uint256 blockNumber;
    uint256 rate;
  }

  // An array of emission schedule key blocks for finding emission rate changes.
  uint256 public tokenEmissionBlockCount;
  mapping (uint256 => EmissionPoint) public tokenEmissionBlocks;
  uint256 public pointEmissionBlockCount;
  mapping (uint256 => EmissionPoint) public pointEmissionBlocks;

  // Store the very earliest possible emission block for quick reference.
  uint256 MAX_INT = 2**256 - 1;
  uint256 internal earliestTokenEmissionBlock;
  uint256 internal earliestPointEmissionBlock;

  // Information for each pool that can be staked in.
  // - token: the address of the ERC20 asset that is being staked in the pool.
  // - strength: the relative token emission strength of this pool.
  // - lastRewardBlock: the last block number where token distribution occurred.
  // - tokensPerShare: accumulated tokens per share times 1e12.
  // - pointsPerShare: accumulated points per share times 1e12.
  struct PoolInfo {
    IERC20 token;
    uint256 tokenStrength;
    uint256 tokensPerShare;
    uint256 pointStrength;
    uint256 pointsPerShare;
    uint256 lastRewardBlock;
  }

  IERC20[] public poolTokens;

  // Stored information for each available pool per its token address.
  mapping (IERC20 => PoolInfo) public poolInfo;

  // Information for each user per staking pool:
  // - amount: the amount of the pool asset being provided by the user.
  // - tokenPaid: the value of the user's total earning that has been paid out.
  // -- pending reward = (user.amount * pool.tokensPerShare) - user.rewardDebt.
  // - pointPaid: the value of the user's total point earnings that has been paid out.
  struct UserInfo {
    uint256 amount;
    uint256 tokenPaid;
    uint256 pointPaid;
  }

  // Stored information for each user staking in each pool.
  mapping (IERC20 => mapping (address => UserInfo)) public userInfo;

  // The total sum of the strength of all pools.
  uint256 public totalTokenStrength;
  uint256 public totalPointStrength;

  // The total amount of the disbursed token ever emitted by this Staker.
  uint256 public totalTokenDisbursed;

  // Users additionally accrue non-token points for participating via staking.
  mapping (address => uint256) public userPoints;
  mapping (address => uint256) public userSpentPoints;

  // A map of all external addresses that are permitted to spend user points.
  mapping (address => bool) public approvedPointSpenders;

  // Events for depositing assets into the Staker and later withdrawing them.
  event Deposit(address indexed user, IERC20 indexed token, uint256 amount);
  event Withdraw(address indexed user, IERC20 indexed token, uint256 amount);

  // An event for tracking when a user has spent points.
  event SpentPoints(address indexed source, address indexed user, uint256 amount);

  /**
    Construct a new Staker by providing it a name and the token to disburse.
    @param _name The name of the Staker contract.
    @param _token The token to reward stakers in this contract with.
  */
  constructor(string memory _name, IERC20 _token) public {
    name = _name;
    token = _token;
    token.approve(address(this), MAX_INT);
    canAlterDevelopers = true;
    canAlterTokenEmissionSchedule = true;
    earliestTokenEmissionBlock = MAX_INT;
    canAlterPointEmissionSchedule = true;
    earliestPointEmissionBlock = MAX_INT;
  }

  /**
    Add a new developer to the Staker or overwrite an existing one.
    This operation requires that developer address addition is not locked.
    @param _developerAddress The additional developer's address.
    @param _share The share in 1/1000th of a percent of each token emission sent
    to this new developer.
  */
  function addDeveloper(address _developerAddress, uint256 _share) external onlyOwner {
    require(canAlterDevelopers,
      "This Staker has locked the addition of developers; no more may be added.");
    developerAddresses.push(_developerAddress);
    developerShares[_developerAddress] = _share;
  }

  /**
    Permanently forfeits owner ability to alter the state of Staker developers.
    Once called, this function is intended to give peace of mind to the Staker's
    developers and community that the fee structure is now immutable.
  */
  function lockDevelopers() external onlyOwner {
    canAlterDevelopers = false;
  }

  /**
    A developer may at any time update their address or voluntarily reduce their
    share of emissions by calling this function from their current address.
    Note that updating a developer's share to zero effectively removes them.
    @param _newDeveloperAddress An address to update this developer's address.
    @param _newShare The new share in 1/1000th of a percent of each token
    emission sent to this developer.
  */
  function updateDeveloper(address _newDeveloperAddress, uint256 _newShare) external {
    uint256 developerShare = developerShares[msg.sender];
    require(developerShare > 0,
      "You are not a developer of this Staker.");
    require(_newShare <= developerShare,
      "You cannot increase your developer share.");
    developerShares[msg.sender] = 0;
    developerAddresses.push(_newDeveloperAddress);
    developerShares[_newDeveloperAddress] = _newShare;
  }

  /**
    Set new emission details to the Staker or overwrite existing ones.
    This operation requires that emission schedule alteration is not locked.

    @param _tokenSchedule An array of EmissionPoints defining the token schedule.
    @param _pointSchedule An array of EmissionPoints defining the point schedule.
  */
  function setEmissions(EmissionPoint[] memory _tokenSchedule, EmissionPoint[] memory _pointSchedule) external onlyOwner {
    if (_tokenSchedule.length > 0) {
      require(canAlterTokenEmissionSchedule,
        "This Staker has locked the alteration of token emissions.");
      tokenEmissionBlockCount = _tokenSchedule.length;
      for (uint256 i = 0; i < tokenEmissionBlockCount; i++) {
        tokenEmissionBlocks[i] = _tokenSchedule[i];
        if (earliestTokenEmissionBlock > _tokenSchedule[i].blockNumber) {
          earliestTokenEmissionBlock = _tokenSchedule[i].blockNumber;
        }
      }
    }
    require(tokenEmissionBlockCount > 0,
      "You must set the token emission schedule.");

    if (_pointSchedule.length > 0) {
      require(canAlterPointEmissionSchedule,
        "This Staker has locked the alteration of point emissions.");
      pointEmissionBlockCount = _pointSchedule.length;
      for (uint256 i = 0; i < pointEmissionBlockCount; i++) {
        pointEmissionBlocks[i] = _pointSchedule[i];
        if (earliestPointEmissionBlock > _pointSchedule[i].blockNumber) {
          earliestPointEmissionBlock = _pointSchedule[i].blockNumber;
        }
      }
    }
    require(tokenEmissionBlockCount > 0,
      "You must set the point emission schedule.");
  }

  /**
    Permanently forfeits owner ability to alter the emission schedule.
    Once called, this function is intended to give peace of mind to the Staker's
    developers and community that the inflation rate is now immutable.
  */
  function lockTokenEmissions() external onlyOwner {
    canAlterTokenEmissionSchedule = false;
  }

  /**
    Permanently forfeits owner ability to alter the emission schedule.
    Once called, this function is intended to give peace of mind to the Staker's
    developers and community that the inflation rate is now immutable.
  */
  function lockPointEmissions() external onlyOwner {
    canAlterPointEmissionSchedule = false;
  }

  /**
    Returns the length of the developer address array.
    @return the length of the developer address array.
  */
  function getDeveloperCount() external view returns (uint256) {
    return developerAddresses.length;
  }

  /**
    Returns the length of the staking pool array.
    @return the length of the staking pool array.
  */
  function getPoolCount() external view returns (uint256) {
    return poolTokens.length;
  }

  /**
    Returns the amount of token that has not been disbursed by the Staker yet.
    @return the amount of token that has not been disbursed by the Staker yet.
  */
  function getRemainingToken() external view returns (uint256) {
    return token.balanceOf(address(this));
  }

  /**
    Allows the contract owner to add a new asset pool to the Staker or overwrite
    an existing one.
    @param _token The address of the asset to base this staking pool off of.
    @param _tokenStrength The relative strength of the new asset for earning token.
    @param _pointStrength The relative strength of the new asset for earning points.
  */
  function addPool(IERC20 _token, uint256 _tokenStrength, uint256 _pointStrength) external onlyOwner {
    require(tokenEmissionBlockCount > 0 && pointEmissionBlockCount > 0,
      "Staking pools cannot be addded until an emission schedule has been defined.");
    uint256 lastTokenRewardBlock = block.number > earliestTokenEmissionBlock ? block.number : earliestTokenEmissionBlock;
    uint256 lastPointRewardBlock = block.number > earliestPointEmissionBlock ? block.number : earliestPointEmissionBlock;
    uint256 lastRewardBlock = lastTokenRewardBlock > lastPointRewardBlock ? lastTokenRewardBlock : lastPointRewardBlock;
    if (address(poolInfo[_token].token) == address(0)) {
      poolTokens.push(_token);
      totalTokenStrength = totalTokenStrength.add(_tokenStrength);
      totalPointStrength = totalPointStrength.add(_pointStrength);
      poolInfo[_token] = PoolInfo({
        token: _token,
        tokenStrength: _tokenStrength,
        tokensPerShare: 0,
        pointStrength: _pointStrength,
        pointsPerShare: 0,
        lastRewardBlock: lastRewardBlock
      });
    } else {
      totalTokenStrength = totalTokenStrength.sub(poolInfo[_token].tokenStrength).add(_tokenStrength);
      poolInfo[_token].tokenStrength = _tokenStrength;
      totalPointStrength = totalPointStrength.sub(poolInfo[_token].pointStrength).add(_pointStrength);
      poolInfo[_token].pointStrength = _pointStrength;
    }
  }

  /**
    Uses the emission schedule to calculate the total amount of staking reward
    token that was emitted between two specified block numbers.

    @param _fromBlock The block to begin calculating emissions from.
    @param _toBlock The block to calculate total emissions up to.
  */
  function getTotalEmittedTokens(uint256 _fromBlock, uint256 _toBlock) public view returns (uint256) {
    require(_toBlock >= _fromBlock,
      "Tokens cannot be emitted from a higher block to a lower block.");
    uint256 totalEmittedTokens = 0;
    uint256 workingRate = 0;
    uint256 workingBlock = _fromBlock;
    for (uint256 i = 0; i < tokenEmissionBlockCount; ++i) {
      uint256 emissionBlock = tokenEmissionBlocks[i].blockNumber;
      uint256 emissionRate = tokenEmissionBlocks[i].rate;
      if (_toBlock < emissionBlock) {
        totalEmittedTokens = totalEmittedTokens.add(_toBlock.sub(workingBlock).mul(workingRate));
        return totalEmittedTokens;
      } else if (workingBlock < emissionBlock) {
        totalEmittedTokens = totalEmittedTokens.add(emissionBlock.sub(workingBlock).mul(workingRate));
        workingBlock = emissionBlock;
      }
      workingRate = emissionRate;
    }
    if (workingBlock < _toBlock) {
      totalEmittedTokens = totalEmittedTokens.add(_toBlock.sub(workingBlock).mul(workingRate));
    }
    return totalEmittedTokens;
  }

  /**
    Uses the emission schedule to calculate the total amount of points
    emitted between two specified block numbers.

    @param _fromBlock The block to begin calculating emissions from.
    @param _toBlock The block to calculate total emissions up to.
  */
  function getTotalEmittedPoints(uint256 _fromBlock, uint256 _toBlock) public view returns (uint256) {
    require(_toBlock >= _fromBlock,
      "Points cannot be emitted from a higher block to a lower block.");
    uint256 totalEmittedPoints = 0;
    uint256 workingRate = 0;
    uint256 workingBlock = _fromBlock;
    for (uint256 i = 0; i < pointEmissionBlockCount; ++i) {
      uint256 emissionBlock = pointEmissionBlocks[i].blockNumber;
      uint256 emissionRate = pointEmissionBlocks[i].rate;
      if (_toBlock < emissionBlock) {
        totalEmittedPoints = totalEmittedPoints.add(_toBlock.sub(workingBlock).mul(workingRate));
        return totalEmittedPoints;
      } else if (workingBlock < emissionBlock) {
        totalEmittedPoints = totalEmittedPoints.add(emissionBlock.sub(workingBlock).mul(workingRate));
        workingBlock = emissionBlock;
      }
      workingRate = emissionRate;
    }
    if (workingBlock < _toBlock) {
      totalEmittedPoints = totalEmittedPoints.add(_toBlock.sub(workingBlock).mul(workingRate));
    }
    return totalEmittedPoints;
  }

  /**
    Update the pool corresponding to the specified token address.
    @param _token The address of the asset to update the corresponding pool for.
  */
  function updatePool(IERC20 _token) internal {
    PoolInfo storage pool = poolInfo[_token];
    if (block.number <= pool.lastRewardBlock) {
      return;
    }
    uint256 poolTokenSupply = pool.token.balanceOf(address(this));
    if (address(_token) == address(token)) {
      poolTokenSupply = totalTokenDeposited;
    }
    if (poolTokenSupply <= 0) {
      pool.lastRewardBlock = block.number;
      return;
    }

    // Calculate tokens and point rewards for this pool.
    uint256 totalEmittedTokens = getTotalEmittedTokens(pool.lastRewardBlock, block.number);
    uint256 tokensReward = totalEmittedTokens.mul(pool.tokenStrength).div(totalTokenStrength).mul(1e12);
    uint256 totalEmittedPoints = getTotalEmittedPoints(pool.lastRewardBlock, block.number);
    uint256 pointsReward = totalEmittedPoints.mul(pool.pointStrength).div(totalPointStrength).mul(1e30);

    // Directly pay developers their corresponding share of tokens and points.
    for (uint256 i = 0; i < developerAddresses.length; ++i) {
      address developer = developerAddresses[i];
      uint256 share = developerShares[developer];
      uint256 devTokens = tokensReward.mul(share).div(100000);
      tokensReward = tokensReward - devTokens;
      uint256 devPoints = pointsReward.mul(share).div(100000);
      pointsReward = pointsReward - devPoints;
      token.safeTransferFrom(address(this), developer, devTokens.div(1e12));
      userPoints[developer] = userPoints[developer].add(devPoints.div(1e30));
    }

    // Update the pool rewards per share to pay users the amount remaining.
    pool.tokensPerShare = pool.tokensPerShare.add(tokensReward.div(poolTokenSupply));
    pool.pointsPerShare = pool.pointsPerShare.add(pointsReward.div(poolTokenSupply));
    pool.lastRewardBlock = block.number;
  }

  /**
    A function to easily see the amount of token rewards pending for a user on a
    given pool. Returns the pending reward token amount.
    @param _token The address of a particular staking pool asset to check for a
    pending reward.
    @param _user The user address to check for a pending reward.
    @return the pending reward token amount.
  */
  function getPendingTokens(IERC20 _token, address _user) public view returns (uint256) {
    PoolInfo storage pool = poolInfo[_token];
    UserInfo storage user = userInfo[_token][_user];
    uint256 tokensPerShare = pool.tokensPerShare;
    uint256 poolTokenSupply = pool.token.balanceOf(address(this));
    if (address(_token) == address(token)) {
      poolTokenSupply = totalTokenDeposited;
    }

    if (block.number > pool.lastRewardBlock && poolTokenSupply > 0) {
      uint256 totalEmittedTokens = getTotalEmittedTokens(pool.lastRewardBlock, block.number);
      uint256 tokensReward = totalEmittedTokens.mul(pool.tokenStrength).div(totalTokenStrength).mul(1e12);
      tokensPerShare = tokensPerShare.add(tokensReward.div(poolTokenSupply));
    }

    return user.amount.mul(tokensPerShare).div(1e12).sub(user.tokenPaid);
  }

  /**
    A function to easily see the amount of point rewards pending for a user on a
    given pool. Returns the pending reward point amount.

    @param _token The address of a particular staking pool asset to check for a
    pending reward.
    @param _user The user address to check for a pending reward.
    @return the pending reward token amount.
  */
  function getPendingPoints(IERC20 _token, address _user) public view returns (uint256) {
    PoolInfo storage pool = poolInfo[_token];
    UserInfo storage user = userInfo[_token][_user];
    uint256 pointsPerShare = pool.pointsPerShare;
    uint256 poolTokenSupply = pool.token.balanceOf(address(this));
    if (address(_token) == address(token)) {
      poolTokenSupply = totalTokenDeposited;
    }

    if (block.number > pool.lastRewardBlock && poolTokenSupply > 0) {
      uint256 totalEmittedPoints = getTotalEmittedPoints(pool.lastRewardBlock, block.number);
      uint256 pointsReward = totalEmittedPoints.mul(pool.pointStrength).div(totalPointStrength).mul(1e30);
      pointsPerShare = pointsPerShare.add(pointsReward.div(poolTokenSupply));
    }

    return user.amount.mul(pointsPerShare).div(1e30).sub(user.pointPaid);
  }

  /**
    Return the number of points that the user has available to spend.
    @return the number of points that the user has available to spend.
  */
  function getAvailablePoints(address _user) public view returns (uint256) {
    uint256 concreteTotal = userPoints[_user];
    uint256 pendingTotal = 0;
    for (uint256 i = 0; i < poolTokens.length; ++i) {
      IERC20 poolToken = poolTokens[i];
      uint256 _pendingPoints = getPendingPoints(poolToken, _user);
      pendingTotal = pendingTotal.add(_pendingPoints);
    }
    uint256 spentTotal = userSpentPoints[_user];
    return concreteTotal.add(pendingTotal).sub(spentTotal);
  }

  /**
    Return the total number of points that the user has ever accrued.
    @return the total number of points that the user has ever accrued.
  */
  function getTotalPoints(address _user) external view returns (uint256) {
    uint256 concreteTotal = userPoints[_user];
    uint256 pendingTotal = 0;
    for (uint256 i = 0; i < poolTokens.length; ++i) {
      IERC20 poolToken = poolTokens[i];
      uint256 _pendingPoints = getPendingPoints(poolToken, _user);
      pendingTotal = pendingTotal.add(_pendingPoints);
    }
    return concreteTotal.add(pendingTotal);
  }

  /**
    Return the total number of points that the user has ever spent.
    @return the total number of points that the user has ever spent.
  */
  function getSpentPoints(address _user) external view returns (uint256) {
    return userSpentPoints[_user];
  }

  /**
    Deposit some particular assets to a particular pool on the Staker.
    @param _token The asset to stake into its corresponding pool.
    @param _amount The amount of the provided asset to stake.
  */
  function deposit(IERC20 _token, uint256 _amount) external nonReentrant {
    PoolInfo storage pool = poolInfo[_token];
    require(pool.tokenStrength > 0 || pool.pointStrength > 0,
      "You cannot deposit assets into an inactive pool.");
    UserInfo storage user = userInfo[_token][msg.sender];
    updatePool(_token);
    if (user.amount > 0) {
      uint256 pendingTokens = user.amount.mul(pool.tokensPerShare).div(1e12).sub(user.tokenPaid);
      token.safeTransferFrom(address(this), msg.sender, pendingTokens);
      totalTokenDisbursed = totalTokenDisbursed.add(pendingTokens);
      uint256 pendingPoints = user.amount.mul(pool.pointsPerShare).div(1e30).sub(user.pointPaid);
      userPoints[msg.sender] = userPoints[msg.sender].add(pendingPoints);
    }
    pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
    if (address(_token) == address(token)) {
      totalTokenDeposited = totalTokenDeposited.add(_amount);
    }
    user.amount = user.amount.add(_amount);
    user.tokenPaid = user.amount.mul(pool.tokensPerShare).div(1e12);
    user.pointPaid = user.amount.mul(pool.pointsPerShare).div(1e30);
    emit Deposit(msg.sender, _token, _amount);
  }

  /**
    Withdraw some particular assets from a particular pool on the Staker.
    @param _token The asset to withdraw from its corresponding staking pool.
    @param _amount The amount of the provided asset to withdraw.
  */
  function withdraw(IERC20 _token, uint256 _amount) external nonReentrant {
    PoolInfo storage pool = poolInfo[_token];
    UserInfo storage user = userInfo[_token][msg.sender];
    require(user.amount >= _amount,
      "You cannot withdraw that much of the specified token; you are not owed it.");
    updatePool(_token);
    uint256 pendingTokens = user.amount.mul(pool.tokensPerShare).div(1e12).sub(user.tokenPaid);
    token.safeTransferFrom(address(this), msg.sender, pendingTokens);
    totalTokenDisbursed = totalTokenDisbursed.add(pendingTokens);
    uint256 pendingPoints = user.amount.mul(pool.pointsPerShare).div(1e30).sub(user.pointPaid);
    userPoints[msg.sender] = userPoints[msg.sender].add(pendingPoints);
    if (address(_token) == address(token)) {
      totalTokenDeposited = totalTokenDeposited.sub(_amount);
    }
    user.amount = user.amount.sub(_amount);
    user.tokenPaid = user.amount.mul(pool.tokensPerShare).div(1e12);
    user.pointPaid = user.amount.mul(pool.pointsPerShare).div(1e30);
    pool.token.safeTransfer(address(msg.sender), _amount);
    emit Withdraw(msg.sender, _token, _amount);
  }

  /**
    Allows the owner of this Staker to grant or remove approval to an external
    spender of the points that users accrue from staking resources.
    @param _spender The external address allowed to spend user points.
    @param _approval The updated user approval status.
  */
  function approvePointSpender(address _spender, bool _approval) external onlyOwner {
    approvedPointSpenders[_spender] = _approval;
  }

  /**
    Allows an approved spender of points to spend points on behalf of a user.
    @param _user The user whose points are being spent.
    @param _amount The amount of the user's points being spent.
  */
  function spendPoints(address _user, uint256 _amount) external {
    require(approvedPointSpenders[msg.sender],
      "You are not permitted to spend user points.");
    uint256 _userPoints = getAvailablePoints(_user);
    require(_userPoints >= _amount,
      "The user does not have enough points to spend the requested amount.");
    userSpentPoints[_user] = userSpentPoints[_user].add(_amount);
    emit SpentPoints(msg.sender, _user, _amount);
  }

  /**
    Sweep all of a particular ERC-20 token from the contract.

    @param _token The token to sweep the balance from.
  */
  function sweep(IERC20 _token) external onlyOwner {
    uint256 balance = _token.balanceOf(address(this));
    _token.safeTransferFrom(address(this), msg.sender, balance);
  }
}