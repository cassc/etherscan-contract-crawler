pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';
import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';
import 'OpenZeppelin/[email protected]/contracts/proxy/Initializable.sol';

contract AlphaStaking is Initializable, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  event SetWorker(address worker);
  event Stake(address owner, uint share, uint amount);
  event Unbond(address owner, uint unbondTime, uint unbondShare);
  event Withdraw(address owner, uint withdrawShare, uint withdrawAmount);
  event CancelUnbond(address owner, uint unbondTime, uint unbondShare);
  event Reward(address worker, uint rewardAmount);
  event Extract(address governor, uint extractAmount);

  uint public constant STATUS_READY = 0;
  uint public constant STATUS_UNBONDING = 1;
  uint public constant UNBONDING_DURATION = 7 days;
  uint public constant WITHDRAW_DURATION = 1 days;

  struct Data {
    uint status;
    uint share;
    uint unbondTime;
    uint unbondShare;
  }

  IERC20 public alpha;
  address public governor;
  address public pendingGovernor;
  address public worker;
  uint public totalAlpha;
  uint public totalShare;
  mapping(address => Data) public users;

  modifier onlyGov() {
    require(msg.sender == governor, 'onlyGov/not-governor');
    _;
  }

  modifier onlyWorker() {
    require(msg.sender == worker || msg.sender == governor, 'onlyWorker/not-worker');
    _;
  }

  function initialize(IERC20 _alpha, address _governor) external initializer {
    alpha = _alpha;
    governor = _governor;
  }

  function setWorker(address _worker) external onlyGov {
    worker = _worker;
    emit SetWorker(_worker);
  }

  function setPendingGovernor(address _pendingGovernor) external onlyGov {
    pendingGovernor = _pendingGovernor;
  }

  function acceptGovernor() external {
    require(msg.sender == pendingGovernor, 'acceptGovernor/not-pending');
    pendingGovernor = address(0);
    governor = msg.sender;
  }

  function getStakeValue(address user) external view returns (uint) {
    uint share = users[user].share;
    return share == 0 ? 0 : share.mul(totalAlpha).div(totalShare);
  }

  function stake(uint amount) external nonReentrant {
    require(amount >= 1e18, 'stake/amount-too-small');
    Data storage data = users[msg.sender];
    if (data.status != STATUS_READY) {
      emit CancelUnbond(msg.sender, data.unbondTime, data.unbondShare);
      data.status = STATUS_READY;
      data.unbondTime = 0;
      data.unbondShare = 0;
    }
    alpha.safeTransferFrom(msg.sender, address(this), amount);
    uint share = totalAlpha == 0 ? amount : amount.mul(totalShare).div(totalAlpha);
    totalAlpha = totalAlpha.add(amount);
    totalShare = totalShare.add(share);
    data.share = data.share.add(share);
    emit Stake(msg.sender, share, amount);
  }

  function unbond(uint share) external nonReentrant {
    Data storage data = users[msg.sender];
    if (data.status != STATUS_READY) {
      emit CancelUnbond(msg.sender, data.unbondTime, data.unbondShare);
    }
    require(share <= data.share, 'unbond/insufficient-share');
    data.status = STATUS_UNBONDING;
    data.unbondTime = block.timestamp;
    data.unbondShare = share;
    emit Unbond(msg.sender, block.timestamp, share);
  }

  function withdraw() external nonReentrant {
    Data storage data = users[msg.sender];
    require(data.status == STATUS_UNBONDING, 'withdraw/not-unbonding');
    require(block.timestamp >= data.unbondTime.add(UNBONDING_DURATION), 'withdraw/not-valid');
    require(
      block.timestamp < data.unbondTime.add(UNBONDING_DURATION).add(WITHDRAW_DURATION),
      'withdraw/already-expired'
    );
    uint share = data.unbondShare;
    uint amount = totalAlpha.mul(share).div(totalShare);
    totalAlpha = totalAlpha.sub(amount);
    totalShare = totalShare.sub(share);
    data.share = data.share.sub(share);
    emit Withdraw(msg.sender, share, amount);
    data.status = STATUS_READY;
    data.unbondTime = 0;
    data.unbondShare = 0;
    alpha.safeTransfer(msg.sender, amount);
    require(totalAlpha >= 1e18, 'withdraw/too-low-total-alpha');
  }

  function reward(uint amount) external onlyWorker {
    require(totalShare >= 1e18, 'reward/share-too-small');
    alpha.safeTransferFrom(msg.sender, address(this), amount);
    totalAlpha = totalAlpha.add(amount);
    emit Reward(msg.sender, amount);
  }

  function skim(uint amount) external onlyGov {
    alpha.safeTransfer(msg.sender, amount);
    require(alpha.balanceOf(address(this)) >= totalAlpha, 'skim/not-enough-balance');
  }

  function extract(uint amount) external onlyGov {
    totalAlpha = totalAlpha.sub(amount);
    alpha.safeTransfer(msg.sender, amount);
    require(totalAlpha >= 1e18, 'extract/too-low-total-alpha');
    emit Extract(msg.sender, amount);
  }
}