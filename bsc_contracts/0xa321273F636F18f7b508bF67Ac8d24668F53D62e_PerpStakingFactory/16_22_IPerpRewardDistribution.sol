pragma solidity ^0.5.0;

import "../openzeppelin/Ownable.sol";

interface INotifier {
    function notifyStaked(address user, uint256 amount) external;
    function notifyWithdrawn(address user, uint256 amount) external;
}

contract IPerpRewardDistribution is Ownable {
    INotifier public notifier;
    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(_msgSender() == address(rewardDistribution), "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }

    function setNotifier(INotifier _notifier)
        external
        onlyOwner
    {
        notifier = _notifier;
    }
}