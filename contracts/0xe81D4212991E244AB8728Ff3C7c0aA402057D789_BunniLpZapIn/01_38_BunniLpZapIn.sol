// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import "bunni/interfaces/IBunniHub.sol";

import {ILiquidityGauge} from "gauge-foundry/interfaces/ILiquidityGauge.sol";

import {WETH} from "solmate/tokens/WETH.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Gate, IxPYT} from "timeless/Gate.sol";

import {Multicall} from "./lib/Multicall.sol";
import {SelfPermit} from "./lib/SelfPermit.sol";

contract BunniLpZapIn is Multicall, SelfPermit {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error BunniLpZapIn__SameToken();
    error BunniLpZapIn__PastDeadline();
    error BunniLpZapIn__ZeroExSwapFailed();
    error BunniLpZapIn__InsufficientOutput();

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The 0x proxy contract used for 0x swaps
    address public immutable zeroExProxy;

    /// @notice The Wrapped Ethereum contract
    WETH public immutable weth;

    /// @notice BunniHub for managing Uniswap v3 liquidity
    IBunniHub public immutable bunniHub;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address zeroExProxy_, WETH weth_, IBunniHub bunniHub_) {
        zeroExProxy = zeroExProxy_;
        weth = weth_;
        bunniHub = bunniHub_;
    }

    /// -----------------------------------------------------------------------
    /// Zaps
    /// -----------------------------------------------------------------------

    /// @notice Deposits tokens into a Bunni LP position and then stakes it in a gauge. Any leftover tokens
    /// are refunded to the recipient address.
    /// @dev depositParams.recipient is always overridden to address(this) so can just make it 0,
    /// depositParams.amount0Desired and depositParams.amount1Desired are overridden to the balances
    /// of address(this) if the corresponding useContractBalance flag is set to true.
    /// @param depositParams The deposit params passed to BunniHub
    /// @param gauge The gauge contract to stake the LP tokens into. Make sure it isn't malicious!
    /// @param token0 The token0 of the Uniswap pair to LP into
    /// @param token1 The token1 of the Uniswap pair to LP into
    /// @param recipient The recipient of the staked gauge position
    /// @param sharesMin The minimum acceptable amount of shares received. Used for controlling slippage.
    /// @param useContractBalance0 Set to true to use the token0 balance of address(this) instead of msg.sender
    /// @param useContractBalance1 Set to true to use the token1 balance of address(this) instead of msg.sender
    /// @param compound Set to true to compound the Bunni pool before depositing
    /// @return shares The new share tokens minted to the sender
    /// @return addedLiquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function zapIn(
        IBunniHub.DepositParams memory depositParams,
        ILiquidityGauge gauge,
        ERC20 token0,
        ERC20 token1,
        address recipient,
        uint256 sharesMin,
        bool useContractBalance0,
        bool useContractBalance1,
        bool compound
    ) external payable virtual returns (uint256 shares, uint128 addedLiquidity, uint256 amount0, uint256 amount1) {
        // transfer tokens in and modify deposit params
        if (!useContractBalance0) {
            if (depositParams.amount0Desired != 0) {
                token0.safeTransferFrom(msg.sender, address(this), depositParams.amount0Desired);
            }
        } else {
            depositParams.amount0Desired = token0.balanceOf(address(this));
        }
        if (!useContractBalance1) {
            if (depositParams.amount1Desired != 0) {
                token1.safeTransferFrom(msg.sender, address(this), depositParams.amount1Desired);
            }
        } else {
            depositParams.amount1Desired = token1.balanceOf(address(this));
        }
        depositParams.recipient = address(this);

        // compound if requested
        if (compound) {
            bunniHub.compound(depositParams.key);
        }

        // approve tokens to Bunni
        if (depositParams.amount0Desired != 0) {
            token0.safeApprove(address(bunniHub), depositParams.amount0Desired);
        }
        if (depositParams.amount1Desired != 0) {
            token1.safeApprove(address(bunniHub), depositParams.amount1Desired);
        }

        // deposit tokens into Bunni
        (shares, addedLiquidity, amount0, amount1) = bunniHub.deposit(depositParams);
        if (shares < sharesMin) {
            revert BunniLpZapIn__InsufficientOutput();
        }

        // reset approvals
        if (depositParams.amount0Desired != 0 && token0.allowance(address(this), address(bunniHub)) != 0) {
            token0.safeApprove(address(bunniHub), 0);
        }
        if (depositParams.amount1Desired != 0 && token1.allowance(address(this), address(bunniHub)) != 0) {
            token1.safeApprove(address(bunniHub), 0);
        }

        // stake Bunni shares into gauge
        ERC20 bunniToken = ERC20(address(bunniHub.getBunniToken(depositParams.key)));
        bunniToken.safeApprove(address(gauge), shares);
        gauge.deposit(shares, recipient);

        // reset approvals
        if (bunniToken.allowance(address(this), address(gauge)) != 0) {
            bunniToken.safeApprove(address(gauge), 0);
        }

        // refund tokens
        uint256 balance = token0.balanceOf(address(this));
        if (balance != 0) {
            token0.safeTransfer(recipient, balance);
        }
        balance = token1.balanceOf(address(this));
        if (balance != 0) {
            token1.safeTransfer(recipient, balance);
        }
    }

    /// @notice Deposits tokens into a Bunni LP position. Any leftover tokens
    /// are refunded to the recipient address.
    /// @dev depositParams.recipient will receive the Bunni LP tokens.
    /// depositParams.amount0Desired and depositParams.amount1Desired are overridden to the balances
    /// of address(this) if the corresponding useContractBalance flag is set to true.
    /// @param depositParams The deposit params passed to BunniHub
    /// @param token0 The token0 of the Uniswap pair to LP into
    /// @param token1 The token1 of the Uniswap pair to LP into
    /// @param recipient The recipient of the staked gauge position
    /// @param sharesMin The minimum acceptable amount of shares received. Used for controlling slippage.
    /// @param useContractBalance0 Set to true to use the token0 balance of address(this) instead of msg.sender
    /// @param useContractBalance1 Set to true to use the token1 balance of address(this) instead of msg.sender
    /// @param compound Set to true to compound the Bunni pool before depositing
    /// @return shares The new share tokens minted to the sender
    /// @return addedLiquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function zapInNoStake(
        IBunniHub.DepositParams memory depositParams,
        ERC20 token0,
        ERC20 token1,
        address recipient,
        uint256 sharesMin,
        bool useContractBalance0,
        bool useContractBalance1,
        bool compound
    ) external payable virtual returns (uint256 shares, uint128 addedLiquidity, uint256 amount0, uint256 amount1) {
        // transfer tokens in and modify deposit params
        if (!useContractBalance0) {
            if (depositParams.amount0Desired != 0) {
                token0.safeTransferFrom(msg.sender, address(this), depositParams.amount0Desired);
            }
        } else {
            depositParams.amount0Desired = token0.balanceOf(address(this));
        }
        if (!useContractBalance1) {
            if (depositParams.amount1Desired != 0) {
                token1.safeTransferFrom(msg.sender, address(this), depositParams.amount1Desired);
            }
        } else {
            depositParams.amount1Desired = token1.balanceOf(address(this));
        }

        // compound if requested
        if (compound) {
            bunniHub.compound(depositParams.key);
        }

        // approve tokens to Bunni
        token0.safeApprove(address(bunniHub), depositParams.amount0Desired);
        token1.safeApprove(address(bunniHub), depositParams.amount1Desired);

        // deposit tokens into Bunni
        (shares, addedLiquidity, amount0, amount1) = bunniHub.deposit(depositParams);
        if (shares < sharesMin) {
            revert BunniLpZapIn__InsufficientOutput();
        }

        // reset approvals
        if (token0.allowance(address(this), address(bunniHub)) != 0) {
            token0.safeApprove(address(bunniHub), 0);
        }
        if (token1.allowance(address(this), address(bunniHub)) != 0) {
            token1.safeApprove(address(bunniHub), 0);
        }

        // refund tokens
        uint256 balance = token0.balanceOf(address(this));
        if (balance != 0) {
            token0.safeTransfer(recipient, balance);
        }
        balance = token1.balanceOf(address(this));
        if (balance != 0) {
            token1.safeTransfer(recipient, balance);
        }
    }

    /// -----------------------------------------------------------------------
    /// Timeless yield tokens support
    /// -----------------------------------------------------------------------

    /// @notice Mints Timeless yield tokens using the underlying asset.
    /// @param gate The Gate contract to use for minting the yield tokens
    /// @param nytRecipient The recipient of the minted NYT
    /// @param pytRecipient The recipient of the minted PYT
    /// @param vault The vault to mint NYT and PYT for
    /// @param xPYT The xPYT contract to deposit the minted PYT into. Set to 0 to receive raw PYT instead.
    /// @param underlyingAmount The amount of underlying tokens to use
    /// @param useContractBalance Set to true to use the contract's token balance as token input
    /// @return mintAmount The amount of NYT and PYT minted (the amounts are equal)
    function enterWithUnderlying(
        Gate gate,
        address nytRecipient,
        address pytRecipient,
        address vault,
        IxPYT xPYT,
        uint256 underlyingAmount,
        bool useContractBalance
    ) external payable returns (uint256 mintAmount) {
        // transfer tokens in
        ERC20 underlying = gate.getUnderlyingOfVault(vault);
        if (!useContractBalance) {
            underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);
        }

        // mint yield tokens
        underlying.safeApprove(address(gate), underlyingAmount);
        mintAmount = gate.enterWithUnderlying(nytRecipient, pytRecipient, vault, xPYT, underlyingAmount);

        // reset allowance
        if (underlying.allowance(address(this), address(gate)) != 0) {
            underlying.safeApprove(address(gate), 0);
        }
    }

    /// @notice Mints Timeless yield tokens using the vault token.
    /// @param gate The Gate contract to use for minting the yield tokens
    /// @param nytRecipient The recipient of the minted NYT
    /// @param pytRecipient The recipient of the minted PYT
    /// @param vault The vault to mint NYT and PYT for
    /// @param xPYT The xPYT contract to deposit the minted PYT into. Set to 0 to receive raw PYT instead.
    /// @param vaultSharesAmount The amount of vault share tokens to use
    /// @param useContractBalance Set to true to use the contract's token balance as token input
    /// @return mintAmount The amount of NYT and PYT minted (the amounts are equal)
    function enterWithVaultShares(
        Gate gate,
        address nytRecipient,
        address pytRecipient,
        address vault,
        IxPYT xPYT,
        uint256 vaultSharesAmount,
        bool useContractBalance
    ) external payable returns (uint256 mintAmount) {
        // transfer tokens in
        ERC20 vaultToken = ERC20(vault);
        if (!useContractBalance) {
            vaultToken.safeTransferFrom(msg.sender, address(this), vaultSharesAmount);
        }

        // mint yield tokens
        vaultToken.safeApprove(address(gate), vaultSharesAmount);
        mintAmount = gate.enterWithVaultShares(nytRecipient, pytRecipient, vault, xPYT, vaultSharesAmount);

        // reset allowance
        if (vaultToken.allowance(address(this), address(gate)) != 0) {
            vaultToken.safeApprove(address(gate), 0);
        }
    }

    /// -----------------------------------------------------------------------
    /// WETH support
    /// -----------------------------------------------------------------------

    /// @notice Wraps the user's ETH input into WETH
    /// @dev Should be used as part of a multicall to convert the user's ETH input into WETH
    /// so that it can be swapped into other tokens.
    function wrapEthInput() external payable {
        weth.deposit{value: msg.value}();
    }

    /// -----------------------------------------------------------------------
    /// 0x support
    /// -----------------------------------------------------------------------

    /// @notice Swaps between two regular tokens using 0x. Leftover input tokens are refunded
    /// to refundRecipient.
    /// @dev Used in conjuction with the 0x API https://www.0x.org/docs/api
    /// @param tokenIn The input token
    /// @param tokenAmountIn The amount of token input
    /// @param tokenOut The output token
    /// @param minAmountOut The minimum acceptable token output amount, used for slippage checking.
    /// @param recipient The recipient of the token output
    /// @param refundRecipient The recipient of refunded input tokens
    /// @param useContractBalance Set to true to use the contract's token balance as token input
    /// @param deadline The Unix timestamp (in seconds) after which the call will be reverted
    /// @param swapData The call data to zeroExProxy to execute the swap, obtained from
    /// the https://api.0x.org/swap/v1/quote endpoint
    /// @return tokenAmountOut The amount of token output
    function doZeroExSwap(
        ERC20 tokenIn,
        uint256 tokenAmountIn,
        ERC20 tokenOut,
        uint256 minAmountOut,
        address recipient,
        address refundRecipient,
        bool useContractBalance,
        uint256 deadline,
        bytes calldata swapData
    ) external payable virtual returns (uint256 tokenAmountOut) {
        // check if input token equals output
        if (tokenIn == tokenOut) {
            revert BunniLpZapIn__SameToken();
        }

        // check deadline
        if (block.timestamp > deadline) {
            revert BunniLpZapIn__PastDeadline();
        }

        // transfer in input tokens
        if (!useContractBalance) {
            tokenIn.safeTransferFrom(msg.sender, address(this), tokenAmountIn);
        }

        // approve zeroExProxy
        tokenIn.safeApprove(zeroExProxy, tokenAmountIn);

        // do swap via zeroExProxy
        (bool success,) = zeroExProxy.call(swapData);
        if (!success) {
            revert BunniLpZapIn__ZeroExSwapFailed();
        }

        // reset approvals
        if (tokenIn.allowance(address(this), address(zeroExProxy)) != 0) {
            tokenIn.safeApprove(address(zeroExProxy), 0);
        }

        // check slippage
        tokenAmountOut = tokenOut.balanceOf(address(this));
        if (tokenAmountOut < minAmountOut) {
            revert BunniLpZapIn__InsufficientOutput();
        }

        // transfer output tokens to recipient
        if (recipient != address(this)) {
            tokenOut.safeTransfer(recipient, tokenAmountOut);
        }

        // refund input tokens
        uint256 balance = tokenIn.balanceOf(address(this));
        if (balance != 0) {
            tokenIn.safeTransfer(refundRecipient, balance);
        }
    }

    /// -----------------------------------------------------------------------
    /// Uniswap support
    /// -----------------------------------------------------------------------

    /// @notice Returns the state of a Uniswap v3 pool. Used by the frontend
    /// as part of a static multicall to help determine 0x swap amount
    /// that optimizes the amount of liquidity added.
    /// @param pool The Uniswap v3 pool
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return liquidity The liquidity at the current price of the pool
    function uniswapV3PoolState(IUniswapV3Pool pool)
        external
        payable
        returns (uint160 sqrtPriceX96, int24 tick, uint128 liquidity)
    {
        (sqrtPriceX96, tick,,,,,) = pool.slot0();
        liquidity = pool.liquidity();
    }
}