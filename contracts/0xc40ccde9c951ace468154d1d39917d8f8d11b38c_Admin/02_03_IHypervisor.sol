// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IHypervisor {

    /* user functions */

    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address _feeRecipient,
        int256 swapQuantity
    ) external;

    function setMaxTotalSupply(uint256 _maxTotalSupply) external;

    function setDepositMax(uint256 _deposit0Max, uint256 _deposit1Max) external;

    function appendList(address[] memory listed) external;

    function toggleWhitelist() external;

    function emergencyWithdraw(IERC20 token, uint256 amount) external;

    function emergencyBurn(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external;

    function transferOwnership(address newOwner) external;
}