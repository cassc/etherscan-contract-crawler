// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAggregationRouterV5.sol";
import "./IOracleStruct.sol";

interface IYsDistributor {
    function getTokensDepositedAtTde(uint256 _tdeId) external view returns (address[] memory);

    function tokenOracleParams(address _token) external view returns (IOracleStruct.OracleParams memory);

    function claimRewards(
        uint256 tokenId,
        uint256 tdeId,
        address receiver,
        address operator,
        IAggregationRouterV5.SwapTransaction[] calldata _swapTransactions,
        IERC20 destinationToken
    ) external;

    function getTokenRewardAmountForTde(IERC20 _token, uint256 tdeId, uint256 share) external view returns (uint256);

    function rewardsClaimedForToken(uint256 tokenId, uint256 tdeId) external view returns (bool);
}