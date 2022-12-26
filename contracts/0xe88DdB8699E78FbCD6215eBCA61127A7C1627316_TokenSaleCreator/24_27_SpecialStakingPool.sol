pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./helpers/TransferHelper.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IvToken.sol";

contract SpecialStakingPool is Ownable, AccessControl, Pausable, ReentrancyGuard, IStakingPool {
  using SafeMath for uint256;
  using Address for address;

  address public immutable tokenA;
  address public immutable tokenB;

  uint16 public tokenAAPY;
  uint16 public tokenBAPY;
  uint8 public stakingPoolTax;
  uint256 public withdrawalIntervals;

  bytes32 public pauserRole = keccak256(abi.encodePacked("PAUSER_ROLE"));
  bytes32 public apySetterRole = keccak256(abi.encodePacked("APY_SETTER_ROLE"));

  mapping(bytes32 => Stake) public stakes;
  mapping(address => bytes32[]) public poolsByAddresses;
  mapping(address => bool) public blockedAddresses;
  mapping(address => uint256) public nonWithdrawableERC20;

  bytes32[] public stakeIDs;

  uint256 public withdrawable;

  constructor(
    address newOwner,
    address A,
    address B,
    uint16 aAPY,
    uint16 bAPY,
    uint8 stakingTax,
    uint256 intervals
  ) {
    require(A == address(0) || A.isContract(), "A_must_be_zero_address_or_contract");
    require(B.isContract(), "B_must_be_contract");
    tokenA = A;
    tokenB = B;
    tokenAAPY = aAPY;
    tokenBAPY = bAPY;
    stakingPoolTax = stakingTax;
    withdrawalIntervals = intervals;
    _transferOwnership(newOwner);
    _grantRole(pauserRole, newOwner);
    _grantRole(apySetterRole, newOwner);
  }

  function calculateReward(bytes32 stakeId) public view returns (uint256 reward) {
    Stake memory stake = stakes[stakeId];
    uint256 percentage;
    if (stake.tokenStaked == tokenA) {
      // How much percentage reward does this staker yield?
      percentage = uint256(tokenBAPY).mul(block.timestamp.sub(stake.since) / (60 * 60 * 24 * 7 * 4)).div(12);
    } else {
      percentage = uint256(tokenAAPY).mul(block.timestamp.sub(stake.since) / (60 * 60 * 24 * 7 * 4)).div(12);
    }

    reward = stake.amountStaked.mul(percentage) / 100;
  }

  function stakeEther() external payable whenNotPaused nonReentrant {
    require(!blockedAddresses[_msgSender()], "blocked");
    require(msg.value > 0, "must_stake_greater_than_0");
    uint256 tax = msg.value.mul(stakingPoolTax) / 100;
    bytes32 stakeId = keccak256(abi.encodePacked(_msgSender(), address(this), address(0), block.timestamp));
    Stake memory stake = Stake({
      amountStaked: msg.value.sub(tax),
      tokenStaked: address(0),
      since: block.timestamp,
      staker: _msgSender(),
      stakeId: stakeId,
      nextWithdrawalTime: block.timestamp.add(withdrawalIntervals)
    });
    stakes[stakeId] = stake;
    bytes32[] storage stakez = poolsByAddresses[_msgSender()];
    stakez.push(stakeId);
    stakeIDs.push(stakeId);
    withdrawable = withdrawable.add(tax);
    emit Staked(msg.value, address(0), stake.since, _msgSender(), stakeId);
  }

  function stakeAsset(address token, uint256 amount) external whenNotPaused nonReentrant {
    require(token.isContract(), "must_be_contract_address");
    require(token == tokenA, "cannot_stake_this_token");
    require(!blockedAddresses[_msgSender()], "blocked");
    require(amount > 0, "must_stake_greater_than_0");
    uint256 tax = amount.mul(stakingPoolTax) / 100;
    require(IERC20(token).allowance(_msgSender(), address(this)) >= amount, "not_enough_allowance");
    TransferHelpers._safeTransferFromERC20(token, _msgSender(), address(this), amount);
    bytes32 stakeId = keccak256(abi.encodePacked(_msgSender(), address(this), token, block.timestamp));
    Stake memory stake = Stake({
      amountStaked: amount.sub(tax),
      tokenStaked: token,
      since: block.timestamp,
      staker: _msgSender(),
      stakeId: stakeId,
      nextWithdrawalTime: block.timestamp.add(withdrawalIntervals)
    });
    stakes[stakeId] = stake;
    bytes32[] storage stakez = poolsByAddresses[_msgSender()];
    stakez.push(stakeId);
    stakeIDs.push(stakeId);
    nonWithdrawableERC20[token] = nonWithdrawableERC20[token].add(stake.amountStaked);
    emit Staked(amount, token, stake.since, _msgSender(), stakeId);
  }

  function unstakeAmount(bytes32 stakeId, uint256 amount) external whenNotPaused nonReentrant {
    Stake storage stake = stakes[stakeId];
    require(_msgSender() == stake.staker, "not_owner");
    if (stake.tokenStaked == address(0)) {
      TransferHelpers._safeTransferEther(_msgSender(), amount);
    } else {
      TransferHelpers._safeTransferERC20(stake.tokenStaked, _msgSender(), amount);
      nonWithdrawableERC20[stake.tokenStaked] = nonWithdrawableERC20[stake.tokenStaked].sub(amount);
    }

    stake.amountStaked = stake.amountStaked.sub(amount);
    emit Unstaked(amount, stakeId);
  }

  function unstakeAll(bytes32 stakeId) external whenNotPaused nonReentrant {
    Stake memory stake = stakes[stakeId];
    require(_msgSender() == stake.staker, "not_owner");
    if (stake.tokenStaked == address(0)) {
      TransferHelpers._safeTransferEther(_msgSender(), stake.amountStaked);
    } else {
      TransferHelpers._safeTransferERC20(stake.tokenStaked, _msgSender(), stake.amountStaked);
      nonWithdrawableERC20[stake.tokenStaked] = nonWithdrawableERC20[stake.tokenStaked].sub(stake.amountStaked);
    }
    delete stakes[stakeId];

    bytes32[] storage stakez = poolsByAddresses[_msgSender()];

    for (uint256 i = 0; i < stakez.length; i++) {
      if (stakez[i] == stakeId) {
        stakez[i] = bytes32(0);
      }
    }
    emit Unstaked(stake.amountStaked, stakeId);
  }

  function withdrawRewards(bytes32 stakeId) external whenNotPaused nonReentrant {
    Stake storage stake = stakes[stakeId];
    require(_msgSender() == stake.staker, "not_owner");
    require(block.timestamp >= stake.nextWithdrawalTime, "cannot_withdraw_now");
    uint256 reward = calculateReward(stakeId);
    address token = stake.tokenStaked == tokenA ? tokenB : tokenA;
    uint256 amount = stake.amountStaked.add(reward);

    if (token == tokenB) IvToken(token).mint(_msgSender(), amount);
    else {
      if (tokenA == address(0)) TransferHelpers._safeTransferEther(_msgSender(), amount);
      else TransferHelpers._safeTransferERC20(token, _msgSender(), amount);
    }

    stake.since = block.timestamp;
    stake.nextWithdrawalTime = block.timestamp.add(withdrawalIntervals);
    emit Withdrawn(amount, stakeId);
  }

  function retrieveEther(address to) external onlyOwner {
    TransferHelpers._safeTransferEther(to, withdrawable);
    withdrawable = 0;
  }

  function setStakingPoolTax(uint8 poolTax) external onlyOwner {
    stakingPoolTax = poolTax;
  }

  function retrieveERC20(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    require(token.isContract(), "must_be_contract_address");
    uint256 bal = IERC20(token).balanceOf(address(this));
    require(bal > nonWithdrawableERC20[token], "balance_lower_than_staked");

    if (nonWithdrawableERC20[token] > 0) require(bal.sub(amount) < nonWithdrawableERC20[token], "amount_must_be_less_than_staked");

    TransferHelpers._safeTransferERC20(token, to, amount);
  }

  function pause() external {
    require(hasRole(pauserRole, _msgSender()), "only_pauser");
    _pause();
  }

  function unpause() external {
    require(hasRole(pauserRole, _msgSender()), "only_pauser");
    _unpause();
  }

  function setTokenAAPY(uint8 aAPY) external {
    require(hasRole(apySetterRole, _msgSender()), "only_apy_setter");
    tokenAAPY = aAPY;
  }

  function setTokenBAPY(uint8 bAPY) external {
    require(hasRole(apySetterRole, _msgSender()), "only_apy_setter");
    tokenBAPY = bAPY;
  }

  function setAPYSetter(address account) external onlyOwner {
    require(!hasRole(apySetterRole, account), "already_apy_setter");
    _grantRole(apySetterRole, account);
  }

  function removeAPYSetter(address account) external onlyOwner {
    require(hasRole(apySetterRole, account), "not_apy_setter");
    _revokeRole(apySetterRole, account);
  }

  function setWithdrawalIntervals(uint256 intervals) external onlyOwner {
    withdrawalIntervals = intervals;
  }

  function setPauser(address account) external onlyOwner {
    require(!hasRole(pauserRole, account), "already_pauser");
    _grantRole(pauserRole, account);
  }

  function removePauser(address account) external onlyOwner {
    require(hasRole(pauserRole, account), "not_pauser");
    _revokeRole(pauserRole, account);
  }

  receive() external payable {
    withdrawable = withdrawable.add(msg.value);
  }
}