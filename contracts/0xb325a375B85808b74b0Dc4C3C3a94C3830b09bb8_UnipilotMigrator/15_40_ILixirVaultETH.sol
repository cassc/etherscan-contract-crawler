// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "./ILixirVault.sol";

interface ILixirVaultETH is ILixirVault {
    enum TOKEN {
        ZERO,
        ONE
    }

    function WETH_TOKEN() external view returns (TOKEN);

    function depositETH(
        uint256 amountDesired,
        uint256 amountEthMin,
        uint256 amountMin,
        address recipient,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 shares,
            uint256 amountEthIn,
            uint256 amountIn
        );

    function withdrawETHFrom(
        address withdrawer,
        uint256 shares,
        uint256 amountEthMin,
        uint256 amountMin,
        address payable recipient,
        uint256 deadline
    ) external returns (uint256 amountEthOut, uint256 amountOut);

    function withdrawETH(
        uint256 shares,
        uint256 amountEthMin,
        uint256 amountMin,
        address payable recipient,
        uint256 deadline
    ) external returns (uint256 amountEthOut, uint256 amountOut);

    receive() external payable;
}