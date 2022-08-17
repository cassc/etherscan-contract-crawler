pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later
// STAX (investments/frax-gauge/temple-frax/RewardsManager.sol)

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../../interfaces/investments/frax-gauge/temple-frax/IStaxLPStaking.sol";
import "../../../interfaces/investments/frax-gauge/temple-frax/IRewardsManager.sol";

import "../../../common/access/Operators.sol";
import "../../../common/CommonEventsAndErrors.sol";

/// @notice Contract used to distribute rewards to staking contract on a periodic basis.
contract RewardsManager is IRewardsManager, Ownable, Operators {
    using SafeERC20 for IERC20;

    /// @notice The contract used to stake xLP and distribute proportional rewards to users
    IStaxLPStaking public staking;

    event RewardDistributed(address staking, address token, uint256 amount);

    constructor(address _staking) {
        staking = IStaxLPStaking(_staking);
    }

    function addOperator(address _address) external override onlyOwner {
        _addOperator(_address);
    }

    function removeOperator(address _address) external override onlyOwner {
        _removeOperator(_address);
    }

    /// @notice notify staking contract about new rewards
    function distribute(address _token) external override onlyOperators {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeIncreaseAllowance(address(staking), amount);
        staking.notifyRewardAmount(_token, amount);

        emit RewardDistributed(address(staking), _token, amount);
    }

    /// @notice Owner can recover non-staking/reward tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        address[] memory stakingRewardTokens = staking.rewardTokensList();
        for (uint i=0; i<stakingRewardTokens.length;) {
            if (_token == stakingRewardTokens[i]) revert CommonEventsAndErrors.InvalidToken(_token);
            unchecked { i++; }
        }
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenRecovered(_to, _token, _amount);
    }
}