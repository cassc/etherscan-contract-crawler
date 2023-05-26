// SPDX-License-Identifier: GPL-3.0

/***
 *      ______             _______   __
 *     /      \           |       \ |  \
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *
 *
 *
 */

pragma solidity ^0.8.4;

import {SafeERC20v2} from "./utils/SafeERC20v2.sol";

import {
    IERC20,
    IHyperLPool,
    IHyperLPoolStorage,
    HyperLPRouter
} from "./HyperLPRouter.sol";

contract HyperDexLPRouter is HyperLPRouter {
    using SafeERC20v2 for IERC20;

    constructor(address hyperlpfactory, address weth)
        HyperLPRouter(hyperlpfactory, weth)
    {} // solhint-disable-line no-empty-blocks

    /**
     * @notice mint fungible `hyperpool` tokens with callData related to various DEX's
     * to `hyperpool` tokens
     * when current tick is outside of [lowerTick, upperTick]
     * @dev see HyperLPool.mint method
     * @param hyperpool HyperLPool address
     * @param paymentToken token to pay
     * @param paymentAmount amount of token to pay
     * @return amount0 amount of token0 transferred from msg.sender to mint `mintAmount`
     * @return amount1 amount of token1 transferred from msg.sender to mint `mintAmount`
     * @return mintAmount The number of HyperLP tokens to mint
     * @return liquidityMinted amount of liquidity added to the underlying Uniswap V3 position
     */
    // solhint-disable-next-line function-max-lines, code-complexity
    function mintHyper(
        address hyperpool,
        address paymentToken,
        uint256 paymentAmount,
        address hyperDex,
        bytes memory callData1,
        bytes memory callData2
    )
        external
        payable
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount,
            uint128 liquidityMinted
        )
    {
        require(lpfactory.isTrustedPool(hyperpool), "!pool");

        if (paymentToken == _ETH) {
            require(msg.value == paymentAmount, "Insufficient value");
        } else {
            IERC20(paymentToken).safeTransferFrom(
                _msgSender(),
                address(this),
                paymentAmount
            );
            IERC20(paymentToken).approve(hyperDex, 0);
            IERC20(paymentToken).approve(hyperDex, paymentAmount);
        }

        address token0;
        address token1;

        (, , token0, token1, amount0, amount1) = getMintAmounts(
            hyperpool,
            paymentToken,
            paymentAmount
        );

        if (paymentToken != token0) {
            uint256 preAmount0 = IERC20(token0).balanceOf(address(this));
            (bool success, bytes memory resultData) =
                hyperDex.call{value: msg.value}(callData1);
            if (!success) {
                _revertWithData(resultData);
            }
            amount0 = IERC20(token0).balanceOf(address(this)) - preAmount0;
        }

        if (paymentToken != token1) {
            uint256 preAmount1 = IERC20(token1).balanceOf(address(this));
            (bool success, bytes memory resultData) =
                hyperDex.call{value: msg.value}(callData2);
            if (!success) {
                _revertWithData(resultData);
            }
            amount1 = IERC20(token0).balanceOf(address(this)) - preAmount1;
        }

        IERC20(token0).approve(hyperpool, amount0);
        IERC20(token1).approve(hyperpool, amount1);

        (amount0, amount1, mintAmount, liquidityMinted) = IHyperLPool(hyperpool)
            .mint(amount0, amount1, _msgSender());

        emit Minted(
            _msgSender(),
            mintAmount,
            amount0,
            amount1,
            liquidityMinted
        );

        amount0 = IERC20(token0).balanceOf(address(this));
        amount1 = IERC20(token1).balanceOf(address(this));

        if (amount0 > 0) {
            IERC20(token0).safeTransfer(_msgSender(), amount0);
        }
        if (amount1 > 0) {
            IERC20(token1).safeTransfer(_msgSender(), amount1);
        }
    }
}