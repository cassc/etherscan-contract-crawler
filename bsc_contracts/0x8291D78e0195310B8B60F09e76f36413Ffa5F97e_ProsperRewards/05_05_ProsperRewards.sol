// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ProsperRewards is Ownable {
  using SafeMath for uint256;

  struct UserReward {
    address user;
    uint256 rewardAmount;
  }

  // on BSC
  address public PROS_ADDRESS = 0xEd8c8Aa8299C10f067496BB66f8cC7Fb338A3405;
  // user => token address => reward amount
  mapping (address => mapping (address => uint256)) public userRewardAmount;
  mapping (address => bool) public whitelisted;

  modifier canGetRewards(address _claimingToken) {
    require(userRewardAmount[msg.sender][_claimingToken] > 0);
    _;
  }

  modifier onlyWhitelisted() {
    require(whitelisted[msg.sender] || msg.sender == owner());
    _;
  }

  function transfer(address from, address payable to, address asset, uint amount) internal {
        if (asset == address(0)) {
            if (address(this) != to) {
                to.call{value: amount};
            }
        } else {
            if (from == address(this)) {
                IERC20(asset).transfer(to, amount);
            } else {
                IERC20(asset).transferFrom(from, to, amount);
            }
        }
    }

  function getRewards(address _claimingToken) external canGetRewards(_claimingToken) {
    uint256 rewardAmount = userRewardAmount[msg.sender][_claimingToken];
    userRewardAmount[msg.sender][_claimingToken] = 0;
    transfer(address(this), payable(msg.sender), _claimingToken, rewardAmount);
  }

  function setRewards(UserReward[] calldata _rewards, address _rewardToken, uint256 _totalRewards) public onlyWhitelisted {
    transfer(msg.sender, payable(address(this)), _rewardToken, _totalRewards);
    for (uint i = 0; i < _rewards.length; i++) {
      userRewardAmount[_rewards[i].user][_rewardToken] = userRewardAmount[_rewards[i].user][_rewardToken].add(_rewards[i].rewardAmount);
    }
  }

  function addToWhitelist(address _address) public onlyOwner {
    whitelisted[_address] = true;
  }
}