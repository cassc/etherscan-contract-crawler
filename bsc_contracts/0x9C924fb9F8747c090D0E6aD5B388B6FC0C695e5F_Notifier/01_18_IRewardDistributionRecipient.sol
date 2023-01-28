pragma solidity ^0.5.0;

import "../openzeppelin/Ownable.sol";

interface INotifier {
    function notifyStaked(address user, uint256 amount) external;
    function notifyWithdrawn(address user, uint256 amount) external;
}

contract IRewardDistributionRecipient is Ownable {
    INotifier public rewardDistribution;

    modifier onlyRewardDistribution() {
        require(_msgSender() == address(rewardDistribution), "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(INotifier _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}