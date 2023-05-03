// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { ERC4626 } from "solmate/mixins/ERC4626.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solmate/utils/FixedPointMathLib.sol";

import { Trust } from "sense-v1-utils/Trust.sol";

import { AutoRoller } from "./AutoRoller.sol";

import { IPermit2 } from "./interfaces/IPermit2.sol";

interface AdapterLike {
    function scale() external view returns (uint256);
    function underlying() external view returns (address);
    function target() external view returns (address);
    function wrapUnderlying(uint256) external returns (uint256);
    function unwrapTarget(uint256) external returns (uint256);
}

// Inspired by https://github.com/fei-protocol/ERC4626/blob/main/src/ERC4626Router.sol
contract RollerPeriphery is Trust {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /* ========== PUBLIC CONSTANTS ========== */

    /// @notice ETH address
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ========== PUBLIC IMMUTABLES ========== */

    /// @notice Permit2 contract
    IPermit2 public immutable permit2;

    // 0x ExchangeProxy address. See https://docs.0x.org/developer-resources/contract-addresses
    address public immutable exchangeProxy;

    /* ========== DATA STRUCTURES ========== */

    struct PermitData {
        IPermit2.PermitTransferFrom msg;
        bytes sig;
    }

    struct SwapQuote {
        ERC20 sellToken;
        ERC20 buyToken;
        address spender;
        address payable swapTarget;
        bytes swapCallData;
    }

    /* ========== ERRORS ========== */

    /// @notice thrown when amount of assets received is below the min set by caller.
    error MinAssetError();

    /// @notice thrown when amount of underlying received is below the min set by caller.
    error MinUnderlyingError();

    /// @notice thrown when amount of shares received is below the min set by caller.
    error MinSharesError();

    /// @notice thrown when amount of assets received is above the max set by caller.
    error MaxAssetError();

    /// @notice thrown when amount of underlying received is above the max set by caller.
    error MaxUnderlyingError();

    /// @notice thrown when amount of shares received is above the max set by caller.
    error MaxSharesError();

    /// @notice thrown when amount of assets or excess received is below the max set by caller.
    error MinAssetsOrExcessError();

    /// @notice thrown when amount out received is below the min set by caller.
    error MinAmountOutError();

    /// @notice thrown when swap on 0x returns false.
    error ZeroExSwapFailed(bytes res);

    /// @notice thrown when swap on 0x succeeds but either the sellAmount or they buyAmount are zero.
    error ZeroSwapAmt();

    /// @notice thrown if swapTarget is not the exchange proxy.
    error InvalidExchangeProxy();

    /// @notice thrown if ETH `call` returns false.
    error TransferFailed();

    constructor(IPermit2 _permit2, address _exchangeProxy) Trust(msg.sender) {
        permit2 = _permit2;
        exchangeProxy = _exchangeProxy;
    }

    /// @notice Redeem vault shares to any token, with slippage protection
    /// @param roller AutoRoller vault
    /// @param shares Number of shares to redeem
    /// @param receiver Destination address for the returned assets
    /// @param minAmountOut Minimum amount of tokens returned
    /// @param permit Permit message to pull shares from caller
    /// @param quote Swap quote for converting underlying to token
    /// @return amtOut Amount of tokens redeemed by the given number of shares
    function redeem(AutoRoller roller, uint256 shares, address receiver, uint256 minAmountOut, PermitData calldata permit, SwapQuote calldata quote) external payable returns (uint256 amtOut) {
        _transferFrom(permit, address(roller), shares);

        if ((amtOut = _fromTarget(roller, address(roller.adapter()), roller.redeem(shares, address(this), address(this)), receiver, quote)) < minAmountOut) {
            revert MinAmountOutError();
        }
        // transfer bought tokens to receiver
        if (address(quote.buyToken) == ETH) {
            (bool sent, ) = receiver.call{ value: amtOut }("");
            if (!sent) revert TransferFailed();
        } else {
            ERC20(address(quote.buyToken)).safeTransfer(receiver, amtOut); 
        }
    }

    /// @notice Withdraw asset from vault with slippage protection
    /// @param roller AutoRoller vault
    /// @param assets Amount of asset requested for withdrawal
    /// @param receiver Destination address for the returned assets
    /// @param maxSharesOut Maximum amount of shares burned
    /// @param permit Permit message to pull shares from caller
    /// @return shares Number of shares to redeem
    function withdrawTarget(AutoRoller roller, uint256 assets, address receiver, uint256 maxSharesOut, PermitData calldata permit) external returns (uint256 shares) {
        _transferFrom(permit, address(roller), roller.previewWithdraw(assets));
        
        if ((shares = roller.withdraw(assets, receiver, address(this))) > maxSharesOut) {
            revert MaxSharesError();
        }
    }

    /// @notice Withdraw asset from vault and convert to underlying, with slippage protection
    /// @param roller AutoRoller vault
    /// @param underlyingOut Amount of underlying requested for withdrawal
    /// @param receiver Destination address for the returned underlying
    /// @param maxSharesOut Maximum amount of shared burned
    /// @param permit Permit message to pull shares from caller
    /// @return shares Number of shares to redeem
    function withdrawUnderlying(AutoRoller roller, uint256 underlyingOut, address receiver, uint256 maxSharesOut, PermitData calldata permit) external returns (uint256 shares) {
        AdapterLike adapter = AdapterLike(address(roller.adapter()));

        // asset converted from underlying (round down)
        uint256 assetOut = underlyingOut.divWadDown(adapter.scale());

        _transferFrom(permit, address(roller), roller.previewWithdraw(assetOut));

        if ((shares = roller.withdraw(assetOut, address(this), address(this))) > maxSharesOut) {
            revert MaxSharesError();
        }

        uint256 underlyingOut = adapter.unwrapTarget(roller.asset().balanceOf(address(this)));
        ERC20(adapter.underlying()).safeTransfer(receiver, underlyingOut);
    }

    /// @notice Mint vault shares with slippage protection
    /// @param roller AutoRoller vault
    /// @param shares Number of shares to mint
    /// @param receiver Destination address for the returned shares
    /// @param maxAmountIn Maximum amount of assets pulled from msg.sender
    /// @return assets Amount of asset pulled from msg.sender and used to mint vault shares
    function mintFromTarget(AutoRoller roller, uint256 shares, address receiver, uint256 maxAmountIn, PermitData calldata permit) external returns (uint256 assets) {
        _transferFrom(permit, address(roller.asset()), roller.previewMint(shares));

        if ((assets = roller.mint(shares, receiver)) > maxAmountIn) {
            revert MaxAssetError();
        }
    }

    /// @notice Convert underlying to asset and mint vault shares with slippage protection
    /// @param roller AutoRoller vault
    /// @param shares Number of shares to mint
    /// @param receiver Destination address for the returned shares
    /// @param maxAmountIn Maximum amount of underlying pulled from msg.sender
    /// @return underlyingIn Amount of underlying pulled from msg.sender and used to mint vault shares
    function mintFromUnderlying(AutoRoller roller, uint256 shares, address receiver, uint256 maxAmountIn, PermitData calldata permit) external returns (uint256 underlyingIn) {
        AdapterLike adapter = AdapterLike(address(roller.adapter()));

        _transferFrom(permit, adapter.underlying(), underlyingIn = roller.previewMint(shares).mulWadUp(adapter.scale()));

        adapter.wrapUnderlying(underlyingIn); // convert underlying to asset

        uint256 assetIn = roller.mint(shares, receiver);
        if ((underlyingIn = assetIn.mulWadDown(adapter.scale())) > maxAmountIn) {
            revert MaxUnderlyingError();
        }
    }

    /// @notice Convert token to asset and deposit into vault with slippage protection
    /// @param roller AutoRoller vault
    /// @param tokenIn Amount of token pulled from msg.sender and used to mint vault shares
    /// @param receiver Destination address for the returned shares
    /// @param minSharesOut Minimum amount of returned shares
    /// @param permit Permit message to pull token from caller
    /// @param quote Swap quote for converting token to underlying
    /// @return shares Number of shares minted by the vault and returned to msg.sender
    function deposit(AutoRoller roller, uint256 tokenIn, address receiver, uint256 minSharesOut, PermitData calldata permit, SwapQuote calldata quote) external payable returns (uint256 shares) {
        AdapterLike adapter = AdapterLike(address(roller.adapter()));

        if (address(quote.sellToken) != ETH) _transferFrom(permit, address(quote.sellToken), tokenIn);
        uint256 toTarget = _toTarget(roller, address(adapter), tokenIn, receiver, quote);
        if ((shares = roller.deposit(toTarget, receiver)) < minSharesOut) {
            revert MinSharesError();
        }
    }

    /// @notice Quick exit into the constituent assets with slippage protection
    /// @param roller AutoRoller vault.
    /// @param shares Number of shares to eject with.
    /// @param receiver Destination address for the constituent assets.
    /// @param minAssetsOut Minimum amount of assets returned
    /// @param minExcessOut Minimum excess PT/YT returned
    /// @return assets Amount of asset redeemable by the given number of shares.
    /// @return excessBal Amount of excess PT or YT redeemable by the given number of shares.
    /// @return isExcessPTs Whether the excess token is a YT or PT.
    function eject(AutoRoller roller, uint256 shares, address receiver, uint256 minAssetsOut, uint256 minExcessOut)
        external returns (uint256 assets, uint256 excessBal, bool isExcessPTs)
    {
        (assets, excessBal, isExcessPTs) = roller.eject(shares, receiver, msg.sender);

        if (assets < minAssetsOut || excessBal < minExcessOut) {
            revert MinAssetsOrExcessError();
        }
    }

    function approve(ERC20 token, address to) public payable requiresTrust {
        token.safeApprove(to, type(uint256).max);
    }

    /* ========== INTERNAL UTILS ========== */

    // @dev Swaps ETH->ERC20, ERC20->ERC20 or ERC20->ETH held by this contract using a 0x-API quote
    function _fillQuote(SwapQuote calldata quote) internal returns (uint256 boughtAmount) {
        if (quote.sellToken == quote.buyToken) return 0; // No swap if the tokens are the same.
        if (quote.swapTarget != exchangeProxy) revert InvalidExchangeProxy();

        // Give `spender` an infinite allowance to spend this contract's `sellToken`.
        if (address(quote.sellToken) != ETH)
            ERC20(address(quote.sellToken)).safeApprove(quote.spender, type(uint256).max);

        uint256 sellAmount = address(quote.sellToken) == ETH
            ? address(this).balance
            : quote.sellToken.balanceOf(address(this));

        // Call the encoded swap function call on the contract at `swapTarget`,
        // passing along any ETH attached to this function call to cover protocol fees.
        (bool success, bytes memory res) = quote.swapTarget.call{ value: msg.value }(quote.swapCallData);
        // if (!success) revert(_getRevertMsg(res));
        if (!success) revert ZeroExSwapFailed(res);

        // We assume the Periphery does not hold tokens so boughtAmount is always it's balance
        boughtAmount = address(quote.buyToken) == ETH ? address(this).balance : quote.buyToken.balanceOf(address(this));
        sellAmount =
            sellAmount -
            (address(quote.sellToken) == ETH ? address(this).balance : quote.sellToken.balanceOf(address(this)));
        if (boughtAmount == 0 || sellAmount == 0) revert ZeroSwapAmt();

        emit BoughtTokens(address(quote.sellToken), address(quote.buyToken), sellAmount, boughtAmount);
    }

    /// @notice Given an amount and a quote, decides whether it needs to wrap and make a swap on 0x,
    /// simply wrap tokens or do nothing
    function _toTarget(
        AutoRoller roller,
        address adapter,
        uint256 _amt,
        address receiver,
        SwapQuote calldata quote
    ) internal returns (uint256 amt) {
        if (address(quote.sellToken) == AdapterLike(adapter).underlying()) {
            amt = AdapterLike(adapter).wrapUnderlying(_amt);
        } else if (address(quote.sellToken) != AdapterLike(adapter).target()) {
            // sell tokens for underlying and wrap into target
            amt = AdapterLike(adapter).wrapUnderlying(_fillQuote(quote));
            // refund any remaining quote.sellToken to receiver
            _refundExcess(roller, quote.sellToken, receiver, address(quote.sellToken) == ETH ? address(this).balance : quote.sellToken.balanceOf(address(this)));
        } else {
            amt = _amt;
        }
    }

    /// @notice Given an amount and a quote, decides whether it needs to unwrap and make a swap on 0x,
    /// simply unwrap tokens or do nothing
    /// @dev when using zaps, the amount of underlying to swap for quote.buyToken (on 0x) is calculated off-chain
    function _fromTarget(
        AutoRoller roller,
        address adapter,
        uint256 _amt,
        address receiver,
        SwapQuote calldata quote
    ) internal returns (uint256 amt) {
        if (address(quote.buyToken) == AdapterLike(adapter).underlying()) {
            amt = AdapterLike(adapter).unwrapTarget(_amt);
        } else if (address(quote.buyToken) != AdapterLike(adapter).target()) {
            AdapterLike(adapter).unwrapTarget(_amt);
            // sell underlying for quote.buyToken
            amt = _fillQuote(quote);
            // transfer any remaining underlying to receiver
            _refundExcess(roller, quote.sellToken, receiver, quote.sellToken.balanceOf(address(this)));
        } else {
            amt = _amt;
        }
    }
    
    function _transferFrom(
        PermitData calldata permit,
        address token,
        uint256 amt
    ) internal {
        // Generate calldata for a standard safeTransferFrom call.
        bytes memory inputData = abi.encodeCall(ERC20.transferFrom, (msg.sender, address(this), amt));

        bool success; // Call the token contract as normal, capturing whether it succeeded.
        assembly {
            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(eq(mload(0), 1), iszero(returndatasize())),
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                // We use 0 and 32 to copy up to 32 bytes of return data into the first slot of scratch space.
                call(gas(), token, 0, add(inputData, 32), mload(inputData), 0, 32)
            )
        }

        // We'll fall back to using Permit2 if calling transferFrom on the token directly reverted.
        if (!success)
            permit2.permitTransferFrom(
                permit.msg,
                IPermit2.SignatureTransferDetails({ to: address(this), requestedAmount: amt }),
                msg.sender,
                permit.sig
            );
    }

    function _refundExcess(AutoRoller roller, ERC20 token, address receiver, uint256 amt) internal {
        if (amt > 0) {
            if (address(token) == ETH) {
                (bool sent, ) = receiver.call{ value: amt }("");
                if (!sent) revert TransferFailed();
            } else {
                token.safeTransfer(receiver, amt);
            }
        }
    }

    // required for refunds
    receive() external payable {}

    /* ========== LOGS ========== */

    event BoughtTokens(
        address indexed sellToken,
        address indexed buyToken,
        uint256 sellAmount,
        uint256 indexed boughtAmount
    );
}