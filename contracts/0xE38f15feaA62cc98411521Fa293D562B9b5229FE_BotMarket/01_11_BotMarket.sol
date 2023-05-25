// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {Auth} from "src/Auth.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Multicallable} from "solady/utils/Multicallable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import "src/interfaces/IBalancerVault.sol";
import {IVotemarket} from "src/interfaces/IVM.sol";
import {ICurvePool} from "src/interfaces/ICurvePool.sol";

interface GPv2Settlement {
    function setPreSignature(bytes calldata, bool signed) external;
}

/// @title  BotMarket
/// @notice Helper contract to swap bribes rewards for distribution.
/// @author Stake DAO
contract BotMarket is Auth, Multicallable {
    function getVersion() external pure returns (string memory) {
        return "0.0.1";
    }

    ////////////////////////////////////////////////////////////////
    /// --- CONSTANTS
    ///////////////////////////////////////////////////////////////

    /// Common addresses.

    /// @notice WETH address.
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice ETH address.
    address public constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice AugustusSwapper contract address.
    address public constant AUGUSTUS = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    /// @notice Paraswap Token pull contract address.
    address public constant TOKEN_TRANSFER_PROXY = 0x216B4B4Ba9F3e719726886d34a177484278Bfcae;

    /// @notice GPv2Settlement contract address.
    address public constant GPV2_SETTLEMENT = 0x9008D19f58AAbD9eD0D60971565AA8510560ab41;

    /// Balancer addresses.

    /// @notice BAL token address.
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;

    /// @notice Address of Balancer contract.
    address public constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    /// @notice Helper address to fetch quotes.
    address public constant BALANCER_QUERIES = 0xE39B5e3B6D74016b2F6A9673D7d7493B6DF549d5;

    /// @notice Pool BAL/ETH token address.
    address public constant B_80BAL_20WETH = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;

    /// @notice Pool ID BAL/ETH token address.
    bytes32 public constant B_80BAL_20WETH_POOL_ID = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;

    /// @notice Pool ID SD_BALH token address.
    bytes32 public constant SD_BAL_80BAL_20WETH_POOL_ID =
        0x2d011adf89f0576c9b722c28269fcb5d50c2d17900020000000000000000024d;

    /// SD Tokens addresses.

    /// @notice SD FXS address.
    address public constant SD_FXS = 0x402F878BDd1f5C66FdAF0fabaBcF74741B68ac36;

    /// @notice SD CRV address.
    address public constant SD_CRV = 0xD1b5651E55D4CeeD36251c61c50C889B36F6abB5;

    /// @notice SD BAL address.
    address public constant SD_BAL = 0xF24d8651578a55b0C119B9910759a351A3458895;

    /// @notice SD ANGLE address.
    address public constant SD_ANGLE = 0x31429d1856aD1377A8A0079410B297e1a9e214c2;

    /// @notice Addresses of the pools for each market.
    mapping(address => address) public marketPools;

    address public immutable treasury;

    ////////////////////////////////////////////////////////////////
    /// --- ERRORS
    ///////////////////////////////////////////////////////////////

    /// @notice Throwed when a call fails.
    error CALL_FAILED();

    /// @notice Throwed when a swap fails.
    error SWAP_FAILED();

    /// @notice Throwed when
    error WRONG_MARKET();

    ////////////////////////////////////////////////////////////////
    /// --- EVENTS
    ///////////////////////////////////////////////////////////////

    /// @notice Emitted when a trade is executed.
    /// @param srcToken The token to exchange from.
    /// @param destToken The token to exchange to.
    /// @param srcAmount The amount of srcToken to exchange.
    /// @param destAmount The amount of destToken received.
    event ExchangeAggregator(
        address indexed srcToken, address indexed destToken, uint256 srcAmount, uint256 destAmount
    );

    ////////////////////////////////////////////////////////////////
    /// --- MODIFIERS
    ///////////////////////////////////////////////////////////////

    constructor(address _owner, address _treasury) Auth(_owner) {
        treasury = _treasury;
    }

    ////////////////////////////////////////////////////////////////
    /// --- EXTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////

    function claimAll(address platform, address locker, uint256[] calldata ids) external onlyAllowed {
        IVotemarket(platform).claimAllFor(locker, ids);
    }

    function setPresignature(address token, bytes calldata orderUid) external onlyAllowed {
        approveIfNeeded(token, GPV2_SETTLEMENT);
        GPv2Settlement(GPV2_SETTLEMENT).setPreSignature(orderUid, true);
    }

    function handleCurveMarket(address market, address token, uint256 amount, uint256 minAmountOut)
        external
        onlyAllowed
        returns (uint256 _received)
    {
        /// Swap to sdToken
        if (market == SD_BAL) {
            revert WRONG_MARKET();
        }
        _received = _swapForSdToken(market, token, amount, minAmountOut);
    }

    function handleBalancerMarket(uint256 amount, uint256 minAmountOut, uint256 minLiquidityAmount, uint256 deadline)
        external
        onlyAllowed
        returns (uint256 _received)
    {
        _received = _swapForSdBAL(amount, minLiquidityAmount, minAmountOut, deadline);
    }

    /// @notice Exchanges tokens using 0x.
    /// @param srcToken The token to exchange from.
    /// @param destToken The token to exchange to.
    /// @param underlyingAmount The amount of srcToken to exchange.
    /// @param callData The calldata to use for the exchange.
    function exchange(address srcToken, address destToken, uint256 underlyingAmount, bytes memory callData)
        external
        payable
        onlyAllowed
        returns (uint256 received)
    {
        return _handleAggregator(srcToken, destToken, underlyingAmount, callData);
    }

    /// @notice Used to withdraw tokens from the contract.
    /// @param _tokens The tokens to withdraw.
    /// @param _amounts The amounts to withdraw.
    function withdraw(address[] calldata _tokens, uint256[] calldata _amounts) external onlyAllowed {
        for (uint256 i = 0; i < _tokens.length; i++) {
            SafeTransferLib.safeTransfer(_tokens[i], treasury, _amounts[i]);
        }
    }

    ////////////////////////////////////////////////////////////////
    /// --- INTERNAL IMPLEMENTATION
    ///////////////////////////////////////////////////////////////

    /// @notice Swaps tokens to sdTokens.
    /// @param underlyingAmount The amount of srcToken to exchange.
    /// @param minAmountOut The minimum amount of sdToken to receive.
    function _swapForSdToken(address market, address token, uint256 underlyingAmount, uint256 minAmountOut)
        internal
        returns (uint256 _received)
    {
        address pool = marketPools[market];

        // Approve the pool to spend the underlying token
        approveIfNeeded(token, pool);

        _received = ERC20(market).balanceOf(address(this));

        if (underlyingAmount == type(uint256).max) {
            underlyingAmount = ERC20(token).balanceOf(address(this));
        }

        // Swap the underlying token for the sdToken
        ICurvePool(pool).exchange(0, 1, underlyingAmount, minAmountOut);

        // Calculate the amount of sdToken received
        _received = ERC20(market).balanceOf(address(this)) - _received;
    }

    /// @notice Swaps BAL for sdBAL.
    /// @param minAmountOut The minimum amount of sdBAL to receive.
    /// @param deadline The deadline for the swap.
    function _swapForSdBAL(uint256 underlyingAmount, uint256 minLiquidityAmount, uint256 minAmountOut, uint256 deadline)
        internal
        returns (uint256 _received)
    {
        if (underlyingAmount == type(uint256).max) {
            underlyingAmount = ERC20(BAL).balanceOf(address(this));
        }

        underlyingAmount = _joinBALPool(underlyingAmount, minLiquidityAmount);

        // Approve the pool to spend the underlying token
        SafeTransferLib.safeApprove(B_80BAL_20WETH, BALANCER_VAULT, underlyingAmount);

        SingleSwap memory singleSwap = SingleSwap({
            poolId: SD_BAL_80BAL_20WETH_POOL_ID,
            kind: SwapKind.GIVEN_IN,
            assetIn: B_80BAL_20WETH,
            assetOut: SD_BAL,
            amount: underlyingAmount,
            userData: ""
        });

        FundManagement memory fundManagement = FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        // Swap the underlying token for the sdToken
        _received = IBalancerVault(BALANCER_VAULT).swap(singleSwap, fundManagement, minAmountOut, deadline);
    }

    function _joinBALPool(uint256 underlyingAmount, uint256 minLiquidityAmount) internal returns (uint256 _received) {
        // Approve the pool to spend the underlying token
        approveIfNeeded(BAL, BALANCER_VAULT);

        address[] memory tokens = new address[](2);
        tokens[0] = BAL;
        tokens[1] = WETH;

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = underlyingAmount;
        maxAmountsIn[1] = 0;

        JoinPoolRequest memory joinRequest = JoinPoolRequest({
            assets: tokens,
            maxAmountsIn: maxAmountsIn,
            userData: abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, minLiquidityAmount),
            fromInternalBalance: false
        });

        IBalancerVault(BALANCER_VAULT).joinPool(B_80BAL_20WETH_POOL_ID, address(this), address(this), joinRequest);

        _received = ERC20(B_80BAL_20WETH).balanceOf(address(this));
    }

    /// @notice Swaps tokens using 0x.
    /// @param srcToken The token to exchange from.
    /// @param destToken The token to exchange to.
    /// @param underlyingAmount The amount of srcToken to exchange.
    /// @param callData The calldata to use for the exchange.
    function _handleAggregator(address srcToken, address destToken, uint256 underlyingAmount, bytes memory callData)
        internal
        returns (uint256 received)
    {
        bool success;
        /// Checkpoint the balance of the destination token before the swap.
        uint256 before = destToken == _ETH ? address(this).balance : ERC20(destToken).balanceOf(address(this));

        if (srcToken == _ETH) {
            (success,) = AUGUSTUS.call{value: underlyingAmount}(callData);
        } else {
            approveIfNeeded(srcToken, TOKEN_TRANSFER_PROXY);
            (success,) = AUGUSTUS.call(callData);
        }

        if (!success) revert SWAP_FAILED();

        /// Checkpoint the balance of the destination token after the swap.
        /// Get the amount of destination token received.
        if (destToken == _ETH) {
            received = address(this).balance - before;
        } else {
            received = ERC20(destToken).balanceOf(address(this)) - before;
        }

        emit ExchangeAggregator(srcToken, destToken, underlyingAmount, received);
    }

    function approveIfNeeded(address _token, address _spender) internal {
        if (ERC20(_token).allowance(address(this), _spender) == 0) {
            SafeTransferLib.safeApprove(_token, _spender, type(uint256).max);
        }
    }
    ////////////////////////////////////////////////////////////////
    /// --- VIEWS FUNCTIONS
    ///////////////////////////////////////////////////////////////

    function getBalancerLiquidityQuote(uint256 underlyingAmount) public returns (uint256 _liquidityQuote) {
        address[] memory tokens = new address[](2);
        tokens[0] = BAL;
        tokens[1] = WETH;

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[0] = underlyingAmount;
        maxAmountsIn[1] = 0;

        JoinPoolRequest memory joinRequest = JoinPoolRequest({
            assets: tokens,
            maxAmountsIn: maxAmountsIn,
            userData: abi.encode(JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, 0),
            fromInternalBalance: false
        });

        (_liquidityQuote,) = IBalancerVault(BALANCER_QUERIES).queryJoin(
            B_80BAL_20WETH_POOL_ID, address(this), address(this), joinRequest
        );
    }

    function getBalancerSwapQuote(uint256 underlyingAmount) public returns (uint256) {
        SingleSwap memory singleSwap = SingleSwap({
            poolId: SD_BAL_80BAL_20WETH_POOL_ID,
            kind: SwapKind.GIVEN_IN,
            assetIn: B_80BAL_20WETH,
            assetOut: SD_BAL,
            amount: underlyingAmount,
            userData: ""
        });

        FundManagement memory fundManagement = FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        return IBalancerVault(BALANCER_QUERIES).querySwap(singleSwap, fundManagement);
    }

    function getCurveQuote(address pool, int128 x, int128 y, uint256 amount) public view returns (uint256 _quote) {
        return ICurvePool(pool).get_dy(x, y, amount);
    }

    ////////////////////////////////////////////////////////////////
    /// --- AUTHORIZATION
    ///////////////////////////////////////////////////////////////

    function setMarketPool(address _market, address _pool) external onlyOwner {
        marketPools[_market] = _pool;
    }

    function resetAllowance(address _token, address _spender) external onlyOwner {
        SafeTransferLib.safeApprove(_token, _spender, 0);
    }

    receive() external payable {}
}