// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../interfaces/IBribe.sol';
import '../rewarders/MultiRewarderPerSec.sol';

interface IVoter {
    struct GaugeWeight {
        uint128 allocPoint;
        uint128 voteWeight; // total amount of votes for an LP-token
    }

    // lpToken => weight, equals to sum of votes for a LP token
    function weights(address _lpToken) external view returns (GaugeWeight memory);

    // user address => lpToken => votes
    function votes(address _user, address _lpToken) external view returns (uint256);
}

/**
 * Simple bribe per sec. Distribute bribe rewards to voters
 * Bribe.onVote->updateReward() is a bit different from SimpleRewarder.
 * Here we reduce the original total amount of share
 */
contract Bribe is IBribe, MultiRewarderPerSec {
    using SafeERC20 for IERC20;

    constructor(
        address _master,
        IERC20 _lpToken,
        uint256 _startTimestamp,
        IERC20 _rewardToken,
        uint96 _tokenPerSec
    ) MultiRewarderPerSec(_master, _lpToken, _startTimestamp, _rewardToken, _tokenPerSec) {}

    function onVote(
        address user,
        uint256 newVote,
        uint256 originalTotalVotes
    ) external override onlyMaster nonReentrant returns (uint256[] memory rewards) {
        _updateReward(originalTotalVotes);
        return _onReward(user, newVote);
    }

    function onReward(
        address _user,
        uint256 _lpAmount
    ) external override onlyMaster nonReentrant returns (uint256[] memory rewards) {
        revert('Call onVote instead');
    }

    function _getTotalShare() internal view override returns (uint256) {
        return IVoter(master).weights(address(lpToken)).voteWeight;
    }

    function rewardLength() external view override(IBribe, MultiRewarderPerSec) returns (uint256) {
        return _rewardLength();
    }

    function rewardTokens() external view override(IBribe, MultiRewarderPerSec) returns (IERC20[] memory tokens) {
        return _rewardTokens();
    }

    function pendingTokens(
        address _user
    ) external view override(IBribe, MultiRewarderPerSec) returns (uint256[] memory tokens) {
        return _pendingTokens(_user);
    }
}