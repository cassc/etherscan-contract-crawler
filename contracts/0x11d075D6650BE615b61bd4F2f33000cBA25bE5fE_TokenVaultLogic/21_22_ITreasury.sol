// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/openzeppelin/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ITreasury {
    function isEnded() external view returns (bool);

    function shareTreasuryRewardToken() external;

    function epochDuration() external view returns (uint256);

    function getPoolBalanceToken(IERC20 _token) external view returns (uint256);

    function getBalanceVeToken() external view returns (uint256);

    function getNewSharedToken(IERC20 _token)
        external
        view
        returns (
            uint256 poolSharedAmt,
            uint256 incomeSharedAmt,
            uint256 incomePoolAmt
        );

    function stakingInitialize(uint256 _epochTotal) external;

    function addRewardToken(address _rewardToken) external;

    function end() external;

    function initializeGovernorToken() external;
}