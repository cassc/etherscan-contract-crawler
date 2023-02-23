// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISwapRouterOneBit {
    function swapTokensWithTrust(
        IERC20 srcToken,
        IERC20 destToken,
        uint256 srcAmount,
        uint256 destAmountMin,
        address to
    ) external returns (uint256 destAmount);
}