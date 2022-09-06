// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../utils/Interfaces.sol";
import "../BaseRewardPool.sol";
import "../VirtualBalanceRewardPool.sol";
import "../utils/MathUtil.sol";

/// @title RewardFactory contract
contract RewardFactory is IRewardFactory {
    using MathUtil for uint256;

    event ExtraRewardAdded(address reward, uint256 pid);
    event ExtraRewardRemoved(address reward, uint256 pid);
    event StashAccessGranted(address stash);
    event BaseRewardPoolCreated(address poolAddress);
    event VirtualBalanceRewardPoolCreated(address baseRewardPool, address poolAddress, address token);

    error Unauthorized();

    address public immutable bal;
    address public immutable operator;

    mapping(address => bool) private rewardAccess;
    mapping(address => uint256[]) public rewardActiveList;

    constructor(address _operator, address _bal) {
        operator = _operator;
        bal = _bal;
    }

    /// @notice Get active rewards count
    /// @return uint256 number of active rewards
    function activeRewardCount(address _reward) external view returns (uint256) {
        return rewardActiveList[_reward].length;
    }

    /// @notice Adds a new reward to the active list
    /// @return true on success
    function addActiveReward(address _reward, uint256 _pid) external returns (bool) {
        if (!rewardAccess[msg.sender]) {
            revert Unauthorized();
        }
        uint256 pid = _pid + 1; // offset by 1 so that we can use 0 as empty

        uint256[] memory activeListMemory = rewardActiveList[_reward];
        for (uint256 i = 0; i < activeListMemory.length; i = i.unsafeInc()) {
            if (activeListMemory[i] == pid) return true;
        }
        rewardActiveList[_reward].push(pid);
        emit ExtraRewardAdded(_reward, _pid);
        return true;
    }

    /// @notice Removes active reward
    /// @param _reward The address of the reward contract
    /// @param _pid The pid of the pool
    /// @return true on success
    function removeActiveReward(address _reward, uint256 _pid) external returns (bool) {
        if (!rewardAccess[msg.sender]) {
            revert Unauthorized();
        }
        uint256 pid = _pid + 1; //offset by 1 so that we can use 0 as empty

        uint256[] memory activeListMemory = rewardActiveList[_reward];
        for (uint256 i = 0; i < activeListMemory.length; i = i.unsafeInc()) {
            if (activeListMemory[i] == pid) {
                if (i != activeListMemory.length - 1) {
                    rewardActiveList[_reward][i] = rewardActiveList[_reward][activeListMemory.length - 1];
                }
                rewardActiveList[_reward].pop();
                emit ExtraRewardRemoved(_reward, _pid);
                break;
            }
        }
        return true;
    }

    /// @notice Grants rewardAccess to stash
    /// @dev Stash contracts need access to create new Virtual balance pools for extra gauge incentives(ex. snx)
    function grantRewardStashAccess(address _stash) external {
        if (msg.sender != operator) {
            revert Unauthorized();
        }
        rewardAccess[_stash] = true;
        emit StashAccessGranted(_stash);
    }

    //Create a Managed Reward Pool to handle distribution of all bal mined in a pool
    /// @notice Creates a new Reward pool
    /// @param _pid The pid of the pool
    /// @param _depositToken address of the token
    function createBalRewards(uint256 _pid, address _depositToken) external returns (address) {
        if (msg.sender != operator) {
            revert Unauthorized();
        }

        BaseRewardPool rewardPool = new BaseRewardPool(_pid, _depositToken, bal, msg.sender, address(this));
        emit BaseRewardPoolCreated(address(rewardPool));

        return address(rewardPool);
    }

    /// @notice Create a virtual balance reward pool that mimicks the balance of a pool's main reward contract
    /// @dev used for extra incentive tokens(ex. snx) as well as vebal fees
    /// @param _token address of the token
    /// @param _mainRewards address of the main reward pool contract
    /// @param _rewardPoolOwner address of the reward pool owner
    /// @return address of the new reward pool
    function createTokenRewards(
        address _token,
        address _mainRewards,
        address _rewardPoolOwner
    ) external returns (address) {
        if (msg.sender != operator && !rewardAccess[msg.sender]) {
            revert Unauthorized();
        }

        // create new pool, use main pool for balance lookup
        VirtualBalanceRewardPool rewardPool = new VirtualBalanceRewardPool(_mainRewards, _token, _rewardPoolOwner);
        emit VirtualBalanceRewardPoolCreated(_mainRewards, address(rewardPool), _token);

        address rAddress = address(rewardPool);
        // add the new pool to main pool's list of extra rewards, assuming this factory has "reward manager" role
        IRewards(_mainRewards).addExtraReward(rAddress);
        return rAddress;
    }
}