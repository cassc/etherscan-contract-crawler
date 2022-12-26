pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStakingPool.sol";
import "./helpers/TransferHelper.sol";

contract StakingPool is Ownable, AccessControl, Pausable, ReentrancyGuard, IStakingPool {
  using SafeMath for uint256;
  using Address for address;

  bytes32 public pauserRole = keccak256(abi.encodePacked("PAUSER_ROLE"));
  address public immutable tokenA;
  address public immutable tokenB;
  uint16 public tokenAAPY;
  uint16 public tokenBAPY;
  uint8 public stakingPoolTax;
  uint256 public withdrawalIntervals;

  mapping(bytes32 => Stake) public stakes;
  mapping(address => bytes32[]) public poolsByAddresses;
  mapping(address => bool) public blockedAddresses;
  mapping(address => uint256) public nonWithdrawableERC20;

  bytes32[] public stakeIDs;

  constructor(
    address newOwner,
    address token0,
    address token1,
    uint16 apy1,
    uint16 apy2,
    uint8 poolTax,
    uint256 intervals
  ) {
    require(token0.isContract());
    require(token1.isContract());
    tokenA = token0;
    tokenB = token1;
    tokenAAPY = apy1;
    tokenBAPY = apy2;
    stakingPoolTax = poolTax;
    withdrawalIntervals = intervals;
    _grantRole(pauserRole, _msgSender());
    _grantRole(pauserRole, newOwner);
    _transferOwnership(newOwner);
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

  function stakeAsset(address token, uint256 amount) external whenNotPaused nonReentrant {
    require(token == tokenA || token == tokenB);
    require(token.isContract());
    require(!blockedAddresses[_msgSender()]);
    require(amount > 0);
    uint256 tax = amount.mul(stakingPoolTax) / 100;
    require(IERC20(token).allowance(_msgSender(), address(this)) >= amount);
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
    require(_msgSender() == stake.staker);
    TransferHelpers._safeTransferERC20(stake.tokenStaked, _msgSender(), amount);
    stake.amountStaked = stake.amountStaked.sub(amount);
    nonWithdrawableERC20[stake.tokenStaked] = nonWithdrawableERC20[stake.tokenStaked].sub(amount);
    emit Unstaked(amount, stakeId);
  }

  function unstakeAll(bytes32 stakeId) external nonReentrant {
    Stake memory stake = stakes[stakeId];
    require(_msgSender() == stake.staker);
    TransferHelpers._safeTransferERC20(stake.tokenStaked, _msgSender(), stake.amountStaked);
    delete stakes[stakeId];

    bytes32[] storage stakez = poolsByAddresses[_msgSender()];

    for (uint256 i = 0; i < stakez.length; i++) {
      if (stakez[i] == stakeId) {
        stakez[i] = bytes32(0);
      }
    }
    nonWithdrawableERC20[stake.tokenStaked] = nonWithdrawableERC20[stake.tokenStaked].sub(stake.amountStaked);
    emit Unstaked(stake.amountStaked, stakeId);
  }

  function withdrawRewards(bytes32 stakeId) external whenNotPaused nonReentrant {
    Stake storage stake = stakes[stakeId];
    require(_msgSender() == stake.staker);
    require(block.timestamp >= stake.nextWithdrawalTime, "cannot_withdraw_now");
    uint256 reward = calculateReward(stakeId);
    address token = stake.tokenStaked == tokenA ? tokenB : tokenA;
    uint256 amount = stake.amountStaked.add(reward);
    TransferHelpers._safeTransferERC20(token, stake.staker, amount);
    stake.since = block.timestamp;
    stake.nextWithdrawalTime = block.timestamp.add(withdrawalIntervals);
    emit Withdrawn(amount, stakeId);
  }

  function retrieveEther(address to) external onlyOwner {
    TransferHelpers._safeTransferEther(to, address(this).balance);
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

    if (nonWithdrawableERC20[token] > 0) {
      require(bal.sub(amount) < nonWithdrawableERC20[token], "amount_must_be_less_than_staked");
    }

    TransferHelpers._safeTransferERC20(token, to, amount);
  }

  function pause() external {
    require(hasRole(pauserRole, _msgSender()));
    _pause();
  }

  function unpause() external {
    require(hasRole(pauserRole, _msgSender()));
    _unpause();
  }

  receive() external payable {}
}