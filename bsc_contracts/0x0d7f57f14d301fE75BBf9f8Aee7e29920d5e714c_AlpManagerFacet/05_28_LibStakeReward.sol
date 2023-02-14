// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibApxReward} from  "../libraries/LibApxReward.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LibStakeReward {

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bytes32 constant STAKE_REWARD_POSITION = keccak256("apollox.stake.reward.storage.v2");

    /* ========== STATE VARIABLES ========== */
    struct StakeRewardStorage {
        IERC20 stakingToken;
        uint256 totalStaked;
        mapping(address => uint256) userStaked;
        mapping(address => uint256) lastBlockNumberCalled;
    }

    /* ========== EVENTS ========== */
    event Stake(address indexed account, uint256 amount);
    event UnStake(address indexed account, uint256 amount);

    function stakeRewardStorage() internal pure returns (StakeRewardStorage storage st) {
        bytes32 position = STAKE_REWARD_POSITION;
        assembly {
            st.slot := position
        }
    }

    function initialize(address _stakingToken) internal {
        StakeRewardStorage storage st = stakeRewardStorage();
        require(address(st.stakingToken) == address(0), "Already initialized!");
        st.stakingToken = IERC20(_stakingToken);
    }

    /* ========== VIEWS ========== */
    function totalStaked() internal view returns (uint256) {
        StakeRewardStorage storage st = stakeRewardStorage();
        return st.totalStaked;
    }

    function stakeOf(address _user) internal view returns (uint256) {
        StakeRewardStorage storage st = stakeRewardStorage();
        return st.userStaked[_user];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function checkOncePerBlock(address user) internal {
        StakeRewardStorage storage st = stakeRewardStorage();
        require(st.lastBlockNumberCalled[user] < block.number, "once per block");
        st.lastBlockNumberCalled[user] = block.number;
    }

    function stake(uint256 _amount) internal {
        require(_amount > 0, 'Invalid amount');

        StakeRewardStorage storage st = stakeRewardStorage();
        st.stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        st.userStaked[msg.sender] = st.userStaked[msg.sender].add(_amount);
        st.totalStaked = st.totalStaked.add(_amount);
        LibApxReward.stake(_amount);
        emit Stake(msg.sender, _amount);
    }

    function unStake(uint256 _amount) internal {
        require(_amount > 0, "Invalid withdraw amount");

        StakeRewardStorage storage st = stakeRewardStorage();
        uint256 old = st.userStaked[msg.sender];
        require(old >= _amount, "Insufficient balance");
        st.userStaked[msg.sender] = old.sub(_amount);
        st.totalStaked = st.totalStaked.sub(_amount);
        LibApxReward.unStake(_amount);
        st.stakingToken.safeTransfer(address(msg.sender), _amount);

        emit UnStake(msg.sender, _amount);
    }

    function claimAllReward() internal {
        LibApxReward.claimApxReward(msg.sender);
    }
}