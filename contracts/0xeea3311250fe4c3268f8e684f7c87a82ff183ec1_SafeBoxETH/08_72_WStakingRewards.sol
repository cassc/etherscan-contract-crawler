pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/token/ERC1155/ERC1155.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC20/SafeERC20.sol';
import 'OpenZeppelin/[email protected]/contracts/utils/ReentrancyGuard.sol';

import '../utils/HomoraMath.sol';
import '../../interfaces/IERC20Wrapper.sol';
import '../../interfaces/IStakingRewards.sol';

contract WStakingRewards is ERC1155('WStakingRewards'), ReentrancyGuard, IERC20Wrapper {
  using SafeMath for uint;
  using HomoraMath for uint;
  using SafeERC20 for IERC20;

  address public immutable staking;
  address public immutable underlying;
  address public immutable reward;

  constructor(
    address _staking,
    address _underlying,
    address _reward
  ) public {
    staking = _staking;
    underlying = _underlying;
    reward = _reward;
    IERC20(_underlying).approve(_staking, uint(-1));
  }

  function getUnderlyingToken(uint) external view override returns (address) {
    return underlying;
  }

  function getUnderlyingRate(uint) external view override returns (uint) {
    return 2**112;
  }

  function mint(uint amount) external nonReentrant returns (uint) {
    IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
    IStakingRewards(staking).stake(amount);
    uint rewardPerToken = IStakingRewards(staking).rewardPerToken();
    _mint(msg.sender, rewardPerToken, amount, '');
    return rewardPerToken;
  }

  function burn(uint id, uint amount) external nonReentrant returns (uint) {
    if (amount == uint(-1)) {
      amount = balanceOf(msg.sender, id);
    }
    _burn(msg.sender, id, amount);
    IStakingRewards(staking).withdraw(amount);
    IStakingRewards(staking).getReward();
    IERC20(underlying).safeTransfer(msg.sender, amount);
    uint stRewardPerToken = id;
    uint enRewardPerToken = IStakingRewards(staking).rewardPerToken();
    uint stReward = stRewardPerToken.mul(amount).divCeil(1e18);
    uint enReward = enRewardPerToken.mul(amount).div(1e18);
    if (enReward > stReward) {
      IERC20(reward).safeTransfer(msg.sender, enReward.sub(stReward));
    }
    return enRewardPerToken;
  }
}