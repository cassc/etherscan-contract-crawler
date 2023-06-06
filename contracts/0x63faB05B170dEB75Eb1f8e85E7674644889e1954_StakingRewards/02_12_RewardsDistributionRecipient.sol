pragma solidity ^0.8.10;

// Inheritance
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardsDistributionRecipient is Ownable {
  address public rewardsDistribution;

  function notifyRewardAmount(uint256 reward) external virtual {}

  modifier onlyRewardsDistribution() {
    require(
      msg.sender == rewardsDistribution,
      "Caller is not RewardsDistribution contract"
    );
    _;
  }

  function setRewardsDistribution(address _rewardsDistribution) external onlyOwner {
    rewardsDistribution = _rewardsDistribution;
  }
}