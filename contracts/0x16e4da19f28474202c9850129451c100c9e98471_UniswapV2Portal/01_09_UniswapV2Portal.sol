/// SPDX-License-Identifier: GPL-3.0

/// Copyright (C) 2023 Portals.fi

/// @author Portals.fi
/// @notice This contract adds or removes liquidity to/from Uniswap V2-like pools using any ERC20 token,
/// or the network token.
/// @note This contract is intended to be consumed via a multicall contract and as such omits various checks
/// including slippage and does not return the quantity of tokens acquired. These checks should be handled
/// by the caller

pragma solidity 0.8.19;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { Pausable } from
    "openzeppelin-contracts/security/Pausable.sol";
import { Babylonian } from "./lib/Babylonian.sol";
import { IUniswapV2Router02 } from "./interface/IUniswapV2Router.sol";
import { IUniswapV2Pair } from "./interface/IUniswapV2Pair.sol";

contract UniswapV2Portal is Owned, Pausable {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    constructor(address admin) Owned(admin) { }

    /// @notice Add liquidity to Uniswap V2-like pools with network tokens/ERC20 tokens
    /// @param inputToken The ERC20 token address to spend (address(0) if network token)
    /// @param inputAmount The quantity of inputToken to Portal in
    /// @param outputToken The pool (i.e. pair) address
    /// @param router The Uniswap V2-like router to be used for adding liquidity
    /// @param recipient The recipient of the liquidity tokens
    function portalIn(
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        IUniswapV2Router02 router,
        address recipient
    ) external payable whenNotPaused {
        uint256 amount = _transferFromCaller(inputToken, inputAmount);

        _deposit(inputToken, amount, outputToken, router, recipient);
    }

    /// @notice Sets up the correct token ratio and deposits into the pool
    /// @param inputToken The token address to swap from
    /// @param inputAmount The quantity of tokens to sell
    /// @param outputToken The pool (i.e. pair) address
    /// @param router The Uniswap V2-like router to be used for adding liquidity
    /// @param recipient The recipient of the liquidity tokens
    function _deposit(
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        IUniswapV2Router02 router,
        address recipient
    ) internal {
        IUniswapV2Pair pair = IUniswapV2Pair(outputToken);

        (uint256 res0, uint256 res1,) = pair.getReserves();

        address token0 = pair.token0();
        address token1 = pair.token1();
        uint256 token0Amount;
        uint256 token1Amount;

        if (inputToken == token0) {
            uint256 swapAmount = _getSwapAmount(res0, inputAmount);
            if (swapAmount == 0) swapAmount = inputAmount / 2;

            token1Amount =
                _intraSwap(inputToken, swapAmount, token1, router);

            token0Amount = inputAmount - swapAmount;
        } else {
            uint256 swapAmount = _getSwapAmount(res1, inputAmount);
            if (swapAmount == 0) swapAmount = inputAmount / 2;

            token0Amount =
                _intraSwap(inputToken, swapAmount, token0, router);

            token1Amount = inputAmount - swapAmount;
        }

        _approve(token0, address(router));
        _approve(token1, address(router));

        router.addLiquidity(
            token0,
            token1,
            token0Amount,
            token1Amount,
            0,
            0,
            recipient,
            0xf000000000000000000000000000000000000000000000000000000000000000
        );
    }

    /// @notice Returns the optimal intra-pool swap quantity such that
    /// that the proportion of both tokens held subsequent to the swap is
    /// equal to the proportion of the assets in the pool. Assumes typical
    /// Uniswap V2 fee.
    /// @param reserves The reserves of the inputToken
    /// @param amount The total quantity of tokens held
    /// @return The quantity of the sell token to swap
    function _getSwapAmount(uint256 reserves, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return (
            Babylonian.sqrt(
                reserves
                    * ((amount * 3_988_000) + (reserves * 3_988_009))
            ) - (reserves * 1997)
        ) / 1994;
    }

    /// @notice Used for intra-pool swaps of ERC20 assets
    /// @param inputToken The token address to swap from
    /// @param inputAmount The quantity of tokens to sell
    /// @param outputToken The token address to swap to
    /// @param router The Uniswap V2-like router to use for the swap
    /// @return tokenBought The quantity of tokens bought
    function _intraSwap(
        address inputToken,
        uint256 inputAmount,
        address outputToken,
        IUniswapV2Router02 router
    ) internal returns (uint256) {
        if (inputToken == outputToken) {
            return inputAmount;
        }

        _approve(inputToken, address(router));

        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;

        ERC20 _outputToken = ERC20(outputToken);

        uint256 beforeSwap = _outputToken.balanceOf(address(this));

        router.swapExactTokensForTokens(
            inputAmount,
            0,
            path,
            address(this),
            0xf000000000000000000000000000000000000000000000000000000000000000
        );

        return _outputToken.balanceOf(address(this)) - beforeSwap;
    }

    /// @notice Transfers tokens or the network token from the caller to this contract
    /// @param token The address of the token to transfer (address(0) if network token)
    /// @param quantity The quantity of tokens to transfer from the caller
    /// @return The quantity of tokens or network tokens transferred from the caller to this contract
    function _transferFromCaller(address token, uint256 quantity)
        internal
        virtual
        returns (uint256)
    {
        if (token == address(0)) {
            require(msg.value != 0, "Invalid msg.value");
            return msg.value;
        }

        require(
            quantity != 0 && msg.value == 0,
            "Invalid quantity or msg.value"
        );
        ERC20(token).safeTransferFrom(
            msg.sender, address(this), quantity
        );

        return quantity;
    }

    /// @notice Approve a token for spending with infinite allowance
    /// @param token The ERC20 token to approve
    /// @param spender The spender of the token
    function _approve(address token, address spender) internal {
        ERC20 _token = ERC20(token);
        if (_token.allowance(address(this), spender) == 0) {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    /// @dev Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Recovers stuck tokens
    /// @param tokenAddress The address of the token to recover (address(0) if ETH)
    /// @param tokenAmount The quantity of tokens to recover
    /// @param to The address to send the recovered tokens to
    function recoverToken(
        address tokenAddress,
        uint256 tokenAmount,
        address to
    ) external onlyOwner {
        if (tokenAddress == address(0)) {
            to.safeTransferETH(tokenAmount);
        } else {
            ERC20(tokenAddress).safeTransfer(to, tokenAmount);
        }
    }

    receive() external payable { }
}