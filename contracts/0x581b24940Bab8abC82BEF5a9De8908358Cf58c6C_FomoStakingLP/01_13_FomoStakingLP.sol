// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FomoStakingLP is Pausable, Ownable, AccessControlEnumerable {
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 public constant DELEGATE_ROLE = keccak256("DELEGATE_ROLE");

  struct Stake {
    uint256 timestamp;
    uint256 amount;
    uint256 interestRate;
  }

  struct UserStake {
    uint256 firstTimestamp;
    uint256 totalPrincipal;
    uint256 length;
  }

  struct StakeEntry {
    address stakerAddress;
    uint256 stakeId;
  }

  mapping(address => mapping(uint256 => Stake)) public stakes;

  EnumerableSet.AddressSet private users;

  mapping(address => UserStake) public userStakes;

  StakeEntry[] public stakesList;

  mapping(address => uint256) public lastClaimedTime;

  IERC20 public token;
  IERC20 public tokenLP;

  address public tokenAddress = 0xb0cfb062dE74F0410430a37305b878B7ad65903b;
  address public tokenAddressLP = 0xE577F14Da73974544C19432e7B39bfE4dDa5Db59;

  uint256 public interestRate = 3240;
  uint256 public lockPeriod = 15780000;

  uint256 public minimumStakeAmount = 10000000000000000000;

  uint256 public rewardsPoolBalance;
  uint256 public totalStakedBalance;

  mapping(address => uint256) public totalEarnedTokens;
  uint256 public totalClaimedRewards = 0;

  event LiquidityDeposited(address indexed stakerAddress, uint256 amount);

  event LiquidityWithdrawn(address indexed stakerAddress, uint256 amount);

  event InterestRateUpdated(uint256 timestamp, uint256 rate);

  event RewardsTransferred(address indexed stakerAddress, uint256 rewards);

  event LockPeriodUpdated(uint256 lockPeriod);
  event ExcessTokenWithdrawal(address targetAddress, uint256 amount);
  event RewardsPoolTokenTopUp(address sender, uint256 amount);
  event RewardsPoolTokenWithdrawal(address targetAddress, uint256 amount);
  event WithdrawAll(address targetAddress, uint256 amount, uint256 ethAmount);

  /* Only callable by owner or delegate */
  modifier onlyDelegate() {
    require(
      owner() == _msgSender() || hasRole(DELEGATE_ROLE, _msgSender()),
      "Caller is neither owner nor delegate"
    );
    _;
  }

  /*******************
    Contract start
    *******************/

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(DELEGATE_ROLE, _msgSender());
    token = IERC20(tokenAddress);
    tokenLP = IERC20(tokenAddressLP);
  }

  // **********************************************************
  // ******************    STAKE / UNSTAKE METHODS   *****************

  function deposit(uint256 _amount) external whenNotPaused {
    require(_amount > 0, "deposit amount must not be zero.");

    require(
      _amount >= minimumStakeAmount,
      "amount must be at least minimum amount."
    );

    if (!users.contains(_msgSender())) {
      users.add(_msgSender());
      userStakes[_msgSender()].firstTimestamp = block.timestamp;
    }

    userStakes[_msgSender()].totalPrincipal += _amount;
    userStakes[_msgSender()].length += 1;

    uint256 currentStakeId = userStakes[_msgSender()].length;

    stakes[_msgSender()][currentStakeId].timestamp = block.timestamp;
    stakes[_msgSender()][currentStakeId].amount = _amount;
    stakes[_msgSender()][currentStakeId].interestRate = interestRate;

    stakesList.push(
      StakeEntry({ stakerAddress: _msgSender(), stakeId: currentStakeId })
    );

    totalStakedBalance += _amount;

    tokenLP.transferFrom(_msgSender(), address(this), _amount);

    emit LiquidityDeposited(_msgSender(), _amount);
  }

  function claimRewards() external whenNotPaused {
    _claimRewards();
  }

  /**
   * @notice Withdraws all rewards and staked amounts available to sender.
   *∏
   * @dev public access
   */
  function withdrawTokens(uint256 _amount) external whenNotPaused {
    UserStake storage u = userStakes[_msgSender()];
    require(u.totalPrincipal > 0, "nothing to withdraw");

    require(
      u.totalPrincipal >= _amount,
      "amount to withdraw must not be more than staked"
    );

    require(
      block.timestamp > userStakes[_msgSender()].firstTimestamp + lockPeriod,
      "please wait until lockperiod is over."
    );

    _claimRewards();

    u.totalPrincipal -= _amount;
    totalStakedBalance -= _amount;
    tokenLP.transfer(_msgSender(), _amount);

    emit LiquidityWithdrawn(_msgSender(), _amount);
  }

  function getRewardsPoolBalance() external view returns (uint256) {
    return rewardsPoolBalance;
  }

  function getStake(address _forAddress, uint256 _id)
    public
    view
    returns (Stake memory)
  {
    return stakes[_forAddress][_id];
  }

  function getNumberOfStakesForUser(address _forAddress)
    external
    view
    returns (uint256 length)
  {
    length = userStakes[_forAddress].length;
  }

  function getStakeByIndex(uint256 _index)
    external
    view
    returns (Stake memory)
  {
    return
      getStake(stakesList[_index].stakerAddress, stakesList[_index].stakeId);
  }

  function getStakesLength() external view returns (uint256 length) {
    length = stakesList.length;
  }

  function getUserByIndex(uint256 _index) external view returns (address user) {
    user = users.at(_index);
  }

  function getUsersLength() external view returns (uint256 length) {
    length = users.length();
  }

  function getUserAccountInfo(address forAddress)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    UserStake storage userStake = userStakes[forAddress];

    uint256 principal = userStake.totalPrincipal;

    uint256 pendingRewards = getPendingRewards(forAddress);

    uint256 total = principal + pendingRewards;

    return (principal, pendingRewards, total);
  }

  /**
       @dev Even though this is considered as administrative action (is not affected by
            by contract paused state, it can be executed by anyone who wishes to
            top-up the rewards pool (funds are sent in to contract, *not* the other way around).
            The Rewards Pool is exclusively dedicated to cover withdrawals of user' compound interest,
            which is effectively the reward.
     */
  function topUpRewardsPool(uint256 _amount) external {
    require(_amount > 0, "topup amount must not be zero.");

    token.transferFrom(_msgSender(), address(this), _amount);

    rewardsPoolBalance += _amount;
    emit RewardsPoolTokenTopUp(_msgSender(), _amount);
  }

  /**
   * @notice Updates Interest rate per second value
   * @param _rate  Interest rate per second
   * @dev Delegate only
   */
  function updateInterestRate(uint64 _rate) external onlyDelegate {
    _updateInterestRate(_rate);
  }

  /**
   * @notice Updates Lock Period value
   * @param _lockPeriod  seconds of the lock period
   * @dev Delegate only
   */
  function updateLockPeriod(uint64 _lockPeriod) external onlyDelegate {
    _updateLockPeriod(_lockPeriod);
  }

  /**
   * @dev Withdraw tokens from rewards pool.
   *
   * @param amount : amount to withdraw.
   *                 If `amount == 0` then whole amount in rewards pool will be withdrawn.
   * @param targetAddress : address to send tokens to
   */
  function withdrawFromRewardsPool(
    uint256 amount,
    address payable targetAddress
  ) external onlyOwner {
    if (amount == 0) {
      amount = rewardsPoolBalance;
    } else {
      require(amount <= rewardsPoolBalance, "Amount higher than rewards pool");
    }

    // NOTE(pb): Strictly speaking, consistency check in following lines is not necessary,
    //           the if-else code above guarantees that everything is alright:
    uint256 contractBalance = token.balanceOf(address(this));
    uint256 expectedMinContractBalance = totalStakedBalance + amount;
    require(
      expectedMinContractBalance <= contractBalance,
      "Contract inconsistency."
    );

    rewardsPoolBalance -= amount;

    require(
      token.transfer(targetAddress, amount),
      "Not enough funds on contr. addr."
    );

    emit RewardsPoolTokenWithdrawal(targetAddress, amount);
  }

  /**
   * @dev Withdraw "excess" tokens, which were sent to contract directly via direct ERC20.transfer(...),
   *      without interacting with API of this (Staking) contract, what could be done only by mistake.
   *      Thus this method is meant to be used primarily for rescue purposes, enabling withdrawal of such
   *      "excess" tokens out of contract.
   * @param targetAddress : address to send tokens to
   */
  function withdrawExcessTokens(address payable targetAddress)
    external
    onlyOwner
  {
    uint256 contractBalance = token.balanceOf(address(this));
    uint256 expectedMinContractBalance = totalStakedBalance +
      rewardsPoolBalance;
    // NOTE(pb): The following subtraction shall *fail* (revert) IF the contract is in *INCONSISTENT* state,
    //           = when contract balance is less than minial expected balance:
    uint256 excessAmount = contractBalance - expectedMinContractBalance;
    require(
      token.transfer(targetAddress, excessAmount),
      "Not enough funds on contract address"
    );
    emit ExcessTokenWithdrawal(targetAddress, excessAmount);
  }

  function withdrawExcessLPTokens(address payable targetAddress)
    external
    onlyOwner
  {
    uint256 contractLPBalance = tokenLP.balanceOf(address(this));

    require(
      tokenLP.transfer(targetAddress, contractLPBalance),
      "Not enough funds on contract address"
    );
    emit ExcessTokenWithdrawal(targetAddress, contractLPBalance);
  }

  /**
     * @notice Transfers the remaining token and ether balance to the specified
       payoutAddress
     * @param _payoutAddress address to transfer the balances to. Ensure that this is able to handle ERC20 tokens
     * @dev owner only + only on or after `_earliestDelete` block
     */
  function withdrawAll(address payable _payoutAddress) external onlyOwner {
    uint256 contractBalance = token.balanceOf(address(this));
    require(token.transfer(_payoutAddress, contractBalance));
    uint256 contractEthBalance = address(this).balance;

    (bool success, ) = payable(_payoutAddress).call{
      value: contractEthBalance
    }("");
    require(success, "payable ETH sending failed.");

    emit WithdrawAll(_payoutAddress, contractBalance, contractEthBalance);
  }

  // **********************************************************
  // ******************    INTERNAL METHODS   *****************

  /**
   * @notice Add new interest rate in to the ordered container of previously added interest rates
   * @param _rate - signed interest rate value in [10**18] units => real_rate [1] = rate [10**18] / 10**18
   */
  function _updateInterestRate(uint256 _rate) internal {
    interestRate = _rate;
    emit InterestRateUpdated(block.timestamp, interestRate);
  }

  /**
   * @notice Updates Lock Period value
   * @param _lockPeriod  length of the lock period
   */
  function _updateLockPeriod(uint256 _lockPeriod) internal {
    lockPeriod = _lockPeriod;
    emit LockPeriodUpdated(lockPeriod);
  }

  function _claimRewards() internal {
    uint256 pendingRewards = getPendingRewards(_msgSender());

    require(
      pendingRewards <= rewardsPoolBalance,
      "not enough balance in rewards pool"
    );

    if (pendingRewards > 0) {
      token.transfer(_msgSender(), pendingRewards);
      totalEarnedTokens[_msgSender()] = totalEarnedTokens[
        _msgSender()
      ] += pendingRewards;
      totalClaimedRewards = totalClaimedRewards += pendingRewards;

      rewardsPoolBalance -= pendingRewards;

      lastClaimedTime[_msgSender()] = block.timestamp;

      emit RewardsTransferred(_msgSender(), pendingRewards);
    }
  }

  function getPendingRewards(address forAddress) public view returns (uint256) {
    if (userStakes[forAddress].totalPrincipal == 0) return 0;

    uint256 stakedAmount = userStakes[forAddress].totalPrincipal;

    uint256 referenceTime = lastClaimedTime[forAddress];

    if (lastClaimedTime[forAddress] == 0) {
      referenceTime = userStakes[forAddress].firstTimestamp;
    }

    uint256 timeDiff = block.timestamp - referenceTime;

    uint256 pendingRewards = ((stakedAmount * interestRate * timeDiff) /
      lockPeriod) / 1e4;

    return pendingRewards;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }
}