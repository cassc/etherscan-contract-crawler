pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVotingEscrow.sol";

contract VeDistStableAPY is Ownable {
    using SafeERC20 for IERC20;

    struct Reward {
        uint256 timestamp;
        uint256 amount;
        uint256 supply;
    }

    mapping(uint256 => Reward) public rewards;
    mapping(uint256 => uint256) public nextUserRewards; // TokenId => LastReward
    mapping(uint256 => uint256) public userTokenEpoch;
    uint256 public lastReward;

    address public immutable ve;
    address public immutable token;

    address rewardProvider;
    uint256 minRewardAmount;

    uint256 internal constant MAXTIME = 4 * 365 * 86400;

    event RewardDistributed(
        uint256 indexed index,
        uint256 indexed timestamp,
        uint256 amount,
        uint256 supply
    );
    event RewardClaimed(
        uint256 indexed tokenId,
        uint256 indexed index,
        uint256 amount
    );
    event RewardProviderSet(address rewardProvider);
    event MinRewardAmountSet(uint256 minRewardAmount);

    constructor(address _ve, address _rewardProvider, uint256 _minRewardAmount) {
        ve = _ve;
        _setRewardProvider(_rewardProvider);
        _setMinRewardAmount(_minRewardAmount);
        token = IVotingEscrow(ve).token();
        IERC20(token).approve(ve, type(uint256).max);
    }

    function setRewardProvider(address _rewardProvider) external onlyOwner {
        _setRewardProvider(_rewardProvider);
    }

    function setMinRewardAmount(uint256 _minRewardAmount) external onlyOwner {
        _setMinRewardAmount(_minRewardAmount);
    }

    /// @dev Transfer token to this contract as rewards
    function addReward(uint256 amount) external {
        require(amount > 0, "No tokens transfered");
        require(amount >= minRewardAmount, "Reward amount is too low");
        address provider = rewardProvider;
        require(provider == address(0) || provider == msg.sender, "You are not reward provider");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 index = lastReward++;
        uint256 supply = _getTotalLocked();
        Reward storage curReward = rewards[index];
        curReward.timestamp = block.timestamp;
        curReward.amount = amount;
        curReward.supply = supply;
        require(supply > 0, "No tokens locked. Reward is useless");
        emit RewardDistributed(index, block.timestamp, amount, supply);
    }

    /// @dev claim all allowed rewards for this tokenId
    function claim(uint256 tokenId) public returns (uint256 reward) {
        address tokenOwner = IVotingEscrow(ve).ownerOf(tokenId);
        require(msg.sender == tokenOwner, "Only owner can claim rewards");
        uint256 nextUserReward = nextUserRewards[tokenId];

        if (nextUserReward == 0) {
            nextUserReward = _skipRoundsBeforeCreation(tokenId);
        }

        uint256 tokenLocked;
        uint256 curUserTokenEpoch = userTokenEpoch[tokenId];
        bool expired;

        for (int i = 0; i < 50; i++) {
            if (nextUserReward >= lastReward) {
                break; // No paiments was done in this point
            }

            Reward memory curReward = rewards[nextUserReward];
            (tokenLocked, curUserTokenEpoch, expired) = _getTokenLocked(
                tokenId,
                curReward.timestamp,
                curUserTokenEpoch
            );

            if (expired) {
                break;
            }
            uint256 curRoundReward = (curReward.amount * tokenLocked) /
                curReward.supply;
            emit RewardClaimed(tokenId, nextUserReward, curRoundReward);

            reward += curRoundReward;
            nextUserReward++;
        }

        userTokenEpoch[tokenId] = curUserTokenEpoch;
        nextUserRewards[tokenId] = nextUserReward;

        if (reward > 0) {
            if (IVotingEscrow(ve).locked__end(tokenId) < block.timestamp) {
                IERC20(token).safeTransfer(tokenOwner, reward);
            } else {
                IVotingEscrow(ve).deposit_for(tokenId, reward);
            }
        }
    }

    function claimMany(
        uint256[] calldata tokensId
    ) external returns (uint256 totalRewards) {
        for (uint256 i = 0; i < tokensId.length; i++) {
            totalRewards += claim(tokensId[i]);
        }
    }

    /// @dev View version of claim function
    function claimable(uint256 tokenId) external view returns (uint256 reward) {
        uint256 nextUserReward = nextUserRewards[tokenId];

        if (nextUserReward == 0) {
            nextUserReward = _skipRoundsBeforeCreation(tokenId);
        }

        uint256 tokenLocked;
        uint256 curUserTokenEpoch = userTokenEpoch[tokenId];
        bool expired;

        for (int i = 0; i < 50; i++) {
            if (nextUserReward >= lastReward) {
                break; // No paiments was done in this point
            }

            Reward memory curReward = rewards[nextUserReward];
            (tokenLocked, curUserTokenEpoch, expired) = _getTokenLocked(
                tokenId,
                curReward.timestamp,
                curUserTokenEpoch
            );

            if (expired) {
                break;
            }

            reward += (curReward.amount * tokenLocked) / curReward.supply;
            nextUserReward++;
        }
    }

    /// @dev Get total amount of CHO locked in ve contract
    function _getTotalLocked() internal view returns (uint256) {
        return IVotingEscrow(ve).supply();
    }

    /// @dev Calculate how many token were locked in lock at the given time
    function _getTokenLocked(
        uint256 tokenId,
        uint256 timestamp,
        uint256 curUserTokenEpoch
    ) internal view returns (uint256, uint256, bool) {
        uint256 maxUserEpoch = IVotingEscrow(ve).user_point_epoch(tokenId);
        uint256 tokenLocked;
        bool finished;
        uint256 duration;

        if (maxUserEpoch == 0) {
            return (0, curUserTokenEpoch, true);
        }

        if (curUserTokenEpoch == 0) {
            curUserTokenEpoch = 1;
        }

        IVotingEscrow.Point memory prevPoint = IVotingEscrow(ve)
            .user_point_history(tokenId, curUserTokenEpoch);

        if (prevPoint.ts > timestamp) {
            return (0, curUserTokenEpoch, false);
        }

        while (curUserTokenEpoch < maxUserEpoch) {
            curUserTokenEpoch++;
            IVotingEscrow.Point memory nextPoint = IVotingEscrow(ve)
                .user_point_history(tokenId, curUserTokenEpoch);

            if (nextPoint.ts > timestamp) {
                curUserTokenEpoch--;
                (tokenLocked, duration) = _calcTokenLocked(
                    uint256(int256(prevPoint.bias)),
                    uint256(int256(prevPoint.slope))
                );
                break;
            } else {
                prevPoint = nextPoint;
            }
        }

        if (curUserTokenEpoch == maxUserEpoch) {
            (tokenLocked, duration) = _calcTokenLocked(
                uint256(int256(prevPoint.bias)),
                uint256(int256(prevPoint.slope))
            );
        }

        finished = prevPoint.ts + duration < timestamp;

        if (finished) {
            tokenLocked = 0;
        }

        return (tokenLocked, curUserTokenEpoch, finished);
    }

    /// @dev Calculate how many tokens was locked based on bias and slope
    ///			Ve contract dont store that information, but we know, that
    ///			if duration of lock was MAXTIME, than 1 locked CHO = 1 veCHO.
    ///			Knowing that and fact, that amount of veCHO decreasing due to
    ///			linear law, we can calculate locked amount using similarity of triangles
    function _calcTokenLocked(
        uint256 bias,
        uint256 slope
    ) internal pure returns (uint256 baseValue, uint256 duration) {
        duration = bias / slope;
        baseValue = (MAXTIME * bias) / duration;
    }

    function _setRewardProvider(address _rewardProvider) internal {
        rewardProvider = _rewardProvider;
        emit RewardProviderSet(_rewardProvider);
    }

    function _setMinRewardAmount(uint256 _minRewardAmount) internal {
        minRewardAmount = _minRewardAmount;
        emit MinRewardAmountSet(_minRewardAmount);
    }

    /// @dev Count what is first reward, that was given after lock creation
    function _skipRoundsBeforeCreation(
        uint256 tokenId
    ) internal view returns (uint256 newRound) {
        IVotingEscrow.Point memory firstPoint = IVotingEscrow(ve)
            .user_point_history(tokenId, 1);

        uint256 left = 0;
        uint256 right = lastReward;
        uint256 mid = (right + left) / 2;

        while (right - left > 1) {
            uint256 curTimestamp = rewards[mid].timestamp;
            if (firstPoint.ts > curTimestamp) {
                left = mid;
                mid = (right + left) / 2;
            } else {
                right = mid;
                mid = (right + left) / 2;
            }
        }

        return left;
    }
}