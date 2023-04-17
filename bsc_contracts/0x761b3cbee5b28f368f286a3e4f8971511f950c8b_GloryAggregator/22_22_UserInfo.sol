pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library UserInfo {
    using SafeMath for uint256;
    struct Data {
        uint256 amount;
        uint256 rewards;
        uint256 rewardPerTokenPaid;
    }

    function deposit(UserInfo.Data storage data, uint256 amount) internal {
        data.amount = data.amount.add(amount);
    }

    function withdraw(UserInfo.Data storage data, uint256 amount) internal {
        data.amount = data.amount.sub(amount);
    }

    function updateReward(
        UserInfo.Data storage data,
        uint256 rewards,
        uint256 rewardPerTokenPaid
    ) internal {
        data.rewards = rewards;
        data.rewardPerTokenPaid = rewardPerTokenPaid;
    }
}