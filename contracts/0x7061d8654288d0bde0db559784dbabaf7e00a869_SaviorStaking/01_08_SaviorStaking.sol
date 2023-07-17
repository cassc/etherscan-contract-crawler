pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ISucker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SaviorStaking is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    struct UserStake {
        EnumerableSet.UintSet saviors;
        uint256 lastRewardUpdate;
        uint256 rewardsAccumulated;
    }

    mapping(address => UserStake) private saviorUsers;

    IERC721 saviorNft;
    ISucker suckerToken;

    uint256 public REWARD_PER_SAVIOR = 208333330000000000000;

    modifier updateRewards(address user) {
        UserStake storage stakerUser = saviorUsers[user];
        uint256 rewardBlocks = block.timestamp - stakerUser.lastRewardUpdate;
        uint256 saviorRewards = (rewardBlocks * REWARD_PER_SAVIOR) * stakerUser.saviors.length();
        stakerUser.lastRewardUpdate = block.timestamp;
        stakerUser.rewardsAccumulated += saviorRewards;
        _;
    }

    constructor(IERC721 _savior, ISucker _suckerToken) {
        saviorNft = _savior;
        suckerToken = _suckerToken;
    }

    function stakeSaviors(uint256[] memory saviorIds) external updateRewards(msg.sender) {
        UserStake storage user = saviorUsers[msg.sender];
        
        for(uint256 i; i < saviorIds.length;) {
            uint256 saviorId = saviorIds[i];
            require(saviorNft.ownerOf(saviorId) == msg.sender, "NOT_OWNER");
            user.saviors.add(saviorId);
            saviorNft.transferFrom(msg.sender, address(this), saviorId);
            unchecked {
                ++i;
            }
        }
    }

    function unstakeSaviors(uint256[] memory saviorIds) external updateRewards(msg.sender) {
        UserStake storage user = saviorUsers[msg.sender];

        for(uint256 i; i < saviorIds.length;) {
            uint256 saviorId = saviorIds[i];
            require(user.saviors.contains(saviorId), "NOT_OWNER");
            saviorUsers[msg.sender].saviors.remove(saviorId);
            saviorNft.transferFrom(address(this), msg.sender, saviorId);
            unchecked {
                ++i;
            }
        }
    }

    function claimRewards() external updateRewards(msg.sender) {
        UserStake storage user = saviorUsers[msg.sender];
        uint256 userRewards = user.rewardsAccumulated;
        require(userRewards > 0, "NO_REWARDS");
        user.rewardsAccumulated = 0;
        suckerToken.mint(msg.sender, userRewards);
    }

    function editTokenEmissions(uint256 amount) external onlyOwner {
        REWARD_PER_SAVIOR = amount;
    }

    function getUser(address userAddress) view external returns(uint[] memory, uint, uint) {
        UserStake storage user = saviorUsers[userAddress];
        uint[] memory saviorStaked = user.saviors.values();
        uint256 rewardBlocks = block.timestamp - user.lastRewardUpdate;
        uint256 saviorRewards = ((rewardBlocks * REWARD_PER_SAVIOR) * user.saviors.length()) + user.rewardsAccumulated;
        return (saviorStaked, user.lastRewardUpdate, saviorRewards);
    }

}