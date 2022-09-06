pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IStaxStaking {
    function notifyRewardAmount(address token, uint256 reward) external;
    function rewardPeriodFinish(address _token) external view returns (uint40);
}

contract RewardsManager is Ownable {

    using SafeERC20 for IERC20;

    IStaxStaking public staking;
    address public operator; // keeper

    event RewardDistributed(address staking, address token, uint256 amount);

    constructor(
        address _staking
    ) {
        staking = IStaxStaking(_staking);
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    /// @dev notify staking contract about new rewards
    function distribute(address _token) external onlyOperator {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeIncreaseAllowance(address(staking), amount);
        staking.notifyRewardAmount(_token, amount);

        emit RewardDistributed(address(staking), _token, amount);
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "not operator");
        _;
    }
}