pragma solidity =0.5.16;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./interfaces/IMonolithRewardTokenHelper.sol";

contract MonolithRewardTokenHelper is Ownable, IMonolithRewardTokenHelper {
    address[] rewardTokenList;
    mapping(address => bool) rewardTokenEnabled;

    function rewardTokenListLength() external view returns (uint256) {
        return rewardTokenList.length;
    }

    function rewardTokenListItem(uint256 index) external view returns (address) {
        return rewardTokenList[index];
    }

    function isRewardTokenEnabled(address rewardToken) external view returns (bool) {
        return rewardTokenEnabled[rewardToken];
    }

    function _addRewardToken(address rewardToken) private {
        require(!rewardTokenEnabled[rewardToken], "RewardTokenHelper: REWARD_TOKEN_ENABLED");

        rewardTokenEnabled[rewardToken] = true;
        rewardTokenList.push(rewardToken);
    }

    function addRewardToken(address rewardToken) external onlyOwner {
        _addRewardToken(rewardToken);
    }

    function _indexOfRewardToken(address rewardToken) private view returns (uint256 index) {
        uint256 count = rewardTokenList.length;
        for (uint256 i = 0; i < count; i++) {
            if (rewardTokenList[i] == rewardToken) {
                return i;
            }
        }
        require(false, "RewardTokenHelper: REWARD_TOKEN_NOT_FOUND");
    }

    function removeRewardToken(address rewardToken) external onlyOwner {
        require(rewardTokenEnabled[rewardToken], "RewardTokenHelper: REWARD_TOKEN_NOT_ENABLED");

        uint256 index = _indexOfRewardToken(rewardToken);
        address last = rewardTokenList[rewardTokenList.length - 1];
        rewardTokenList[index] = last;
        rewardTokenList.pop();
        delete rewardTokenEnabled[rewardToken];
    }
}