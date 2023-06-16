// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {ZeroAddressException} from "@gearbox-protocol/core-v2/contracts/interfaces/IErrors.sol";
import {RAY} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

import {AbstractAdapter} from "../AbstractAdapter.sol";
import {AdapterType} from "../../interfaces/IAdapter.sol";

import {ICurvePool} from "../../integrations/curve/ICurvePool.sol";
import {ICurvePool2Assets} from "../../integrations/curve/ICurvePool_2.sol";
import {ICurvePool3Assets} from "../../integrations/curve/ICurvePool_3.sol";
import {ICurvePool4Assets} from "../../integrations/curve/ICurvePool_4.sol";

import {ICurveV1Adapter} from "../../interfaces/curve/ICurveV1Adapter.sol";

uint256 constant ZERO = 0;

/// @title Curve V1 base adapter
/// @notice Implements logic allowing to interact with all Curve pools, regardless of number of coins
contract CurveV1AdapterBase is AbstractAdapter, ICurveV1Adapter {
    using SafeCast for uint256;
    using SafeCast for int256;

    uint16 public constant override _gearboxAdapterVersion = 2;

    function _gearboxAdapterType() external pure virtual override returns (AdapterType) {
        return AdapterType.CURVE_V1_EXCHANGE_ONLY;
    }

    /// @inheritdoc ICurveV1Adapter
    address public immutable override token;

    /// @inheritdoc ICurveV1Adapter
    address public immutable override lp_token;

    /// @inheritdoc ICurveV1Adapter
    uint256 public immutable override lpTokenMask;

    /// @inheritdoc ICurveV1Adapter
    address public immutable override metapoolBase;

    /// @inheritdoc ICurveV1Adapter
    uint256 public immutable override nCoins;

    /// @inheritdoc ICurveV1Adapter
    bool public immutable override use256;

    /// @inheritdoc ICurveV1Adapter
    address public immutable token0;
    /// @inheritdoc ICurveV1Adapter
    address public immutable token1;
    /// @inheritdoc ICurveV1Adapter
    address public immutable token2;
    /// @inheritdoc ICurveV1Adapter
    address public immutable token3;

    /// @inheritdoc ICurveV1Adapter
    uint256 public immutable override token0Mask;
    /// @inheritdoc ICurveV1Adapter
    uint256 public immutable override token1Mask;
    /// @inheritdoc ICurveV1Adapter
    uint256 public immutable override token2Mask;
    /// @inheritdoc ICurveV1Adapter
    uint256 public immutable override token3Mask;

    /// @inheritdoc ICurveV1Adapter
    address public immutable override underlying0;
    /// @inheritdoc ICurveV1Adapter
    address public immutable override underlying1;
    /// @inheritdoc ICurveV1Adapter
    address public immutable override underlying2;
    /// @inheritdoc ICurveV1Adapter
    address public immutable override underlying3;

    /// @inheritdoc ICurveV1Adapter
    uint256 public immutable override underlying0Mask;
    /// @inheritdoc ICurveV1Adapter
    uint256 public immutable override underlying1Mask;
    /// @inheritdoc ICurveV1Adapter
    uint256 public immutable override underlying2Mask;
    /// @inheritdoc ICurveV1Adapter
    uint256 public immutable override underlying3Mask;

    /// @notice Constructor
    /// @param _creditManager Credit manager address
    /// @param _curvePool Target Curve pool address
    /// @param _lp_token Pool LP token address
    /// @param _metapoolBase Base pool address (for metapools only) or zero address
    /// @param _nCoins Number of coins in the pool
    constructor(address _creditManager, address _curvePool, address _lp_token, address _metapoolBase, uint256 _nCoins)
        AbstractAdapter(_creditManager, _curvePool)
    {
        if (_lp_token == address(0)) revert ZeroAddressException(); // F: [ACV1-1]

        lpTokenMask = _getMaskOrRevert(_lp_token); // F: [ACV1-2]

        token = _lp_token; // F: [ACV1-2]
        lp_token = _lp_token; // F: [ACV1-2]
        metapoolBase = _metapoolBase; // F: [ACV1-2]
        nCoins = _nCoins; // F: [ACV1-2]

        {
            bool _use256;

            /// Only Curve v2 pools have mid_fee, so it can be used to determine
            /// whether to use int128 or uint256 function signatures
            try ICurvePool(targetContract).mid_fee() returns (uint256) {
                _use256 = true;
            } catch {
                _use256 = false;
            }

            use256 = _use256;
        }

        address[4] memory tokens;
        uint256[4] memory tokenMasks;
        for (uint256 i = 0; i < nCoins;) {
            address currentCoin;
            try ICurvePool(targetContract).coins(i) returns (address tokenAddress) {
                currentCoin = tokenAddress;
            } catch {
                try ICurvePool(targetContract).coins(i.toInt256().toInt128()) returns (address tokenAddress) {
                    currentCoin = tokenAddress;
                } catch {}
            }

            if (currentCoin == address(0)) revert ZeroAddressException(); // F: [ACV1-1]
            uint256 currentMask = _getMaskOrRevert(currentCoin);

            tokens[i] = currentCoin;
            tokenMasks[i] = currentMask;

            unchecked {
                ++i;
            }
        }

        token0 = tokens[0]; // F: [ACV1-2]
        token1 = tokens[1]; // F: [ACV1-2]
        token2 = tokens[2]; // F: [ACV1-2]
        token3 = tokens[3]; // F: [ACV1-2]

        token0Mask = tokenMasks[0]; // F: [ACV1-2]
        token1Mask = tokenMasks[1]; // F: [ACV1-2]
        token2Mask = tokenMasks[2]; // F: [ACV1-2]
        token3Mask = tokenMasks[3]; // F: [ACV1-2]

        tokens = [address(0), address(0), address(0), address(0)];
        tokenMasks = [ZERO, ZERO, ZERO, ZERO];

        for (uint256 i = 0; i < 4;) {
            address currentCoin;
            uint256 currentMask;

            if (metapoolBase != address(0)) {
                if (i == 0) {
                    currentCoin = token0;
                } else {
                    try ICurvePool(metapoolBase).coins(i - 1) returns (address tokenAddress) {
                        currentCoin = tokenAddress;
                    } catch {}
                }
            } else {
                try ICurvePool(targetContract).underlying_coins(i) returns (address tokenAddress) {
                    currentCoin = tokenAddress;
                } catch {
                    try ICurvePool(targetContract).underlying_coins(i.toInt256().toInt128()) returns (
                        address tokenAddress
                    ) {
                        currentCoin = tokenAddress;
                    } catch {}
                }
            }

            if (currentCoin != address(0)) {
                currentMask = _getMaskOrRevert(currentCoin); // F: [ACV1-1]
            }

            tokens[i] = currentCoin;
            tokenMasks[i] = currentMask;

            unchecked {
                ++i;
            }
        }

        underlying0 = tokens[0]; // F: [ACV1-2]
        underlying1 = tokens[1]; // F: [ACV1-2]
        underlying2 = tokens[2]; // F: [ACV1-2]
        underlying3 = tokens[3]; // F: [ACV1-2]

        underlying0Mask = tokenMasks[0]; // F: [ACV1-2]
        underlying1Mask = tokenMasks[1]; // F: [ACV1-2]
        underlying2Mask = tokenMasks[2]; // F: [ACV1-2]
        underlying3Mask = tokenMasks[3]; // F: [ACV1-2]
    }

    /// -------- ///
    /// EXCHANGE ///
    /// -------- ///

    /// @inheritdoc ICurveV1Adapter
    function exchange(int128 i, int128 j, uint256, uint256) external override creditFacadeOnly {
        _exchange(i, j);
    }

    /// @inheritdoc ICurveV1Adapter
    function exchange(uint256 i, uint256 j, uint256, uint256) external override creditFacadeOnly {
        _exchange(i.toInt256().toInt128(), j.toInt256().toInt128());
    }

    /// @dev Internal implementation of `exchange`
    function _exchange(int128 i, int128 j) internal {
        _exchange_impl(i, j, msg.data, false, false); // F: [ACV1-4]
    }

    /// @inheritdoc ICurveV1Adapter
    function exchange_all(int128 i, int128 j, uint256 rateMinRAY) external override creditFacadeOnly {
        _exchange_all(i, j, rateMinRAY);
    }

    /// @inheritdoc ICurveV1Adapter
    function exchange_all(uint256 i, uint256 j, uint256 rateMinRAY) external override creditFacadeOnly {
        _exchange_all(i.toInt256().toInt128(), j.toInt256().toInt128(), rateMinRAY);
    }

    /// @dev Internal implementation of `exchange_all`
    function _exchange_all(int128 i, int128 j, uint256 rateMinRAY) internal {
        address creditAccount = _creditAccount(); // F: [ACV1-3]

        address tokenIn = _get_token(i, false); // F: [ACV1-5]
        uint256 dx = IERC20(tokenIn).balanceOf(creditAccount); // F: [ACV1-5]
        if (dx <= 1) return;

        unchecked {
            dx--;
        }
        uint256 min_dy = (dx * rateMinRAY) / RAY; // F: [ACV1-5]
        _exchange_impl(i, j, _getExchangeCallData(i, j, dx, min_dy, false), false, true); // F: [ACV1-5]
    }

    /// @inheritdoc ICurveV1Adapter
    function exchange_underlying(int128 i, int128 j, uint256, uint256) external override creditFacadeOnly {
        _exchange_underlying(i, j);
    }

    /// @inheritdoc ICurveV1Adapter
    function exchange_underlying(uint256 i, uint256 j, uint256, uint256) external override creditFacadeOnly {
        _exchange_underlying(i.toInt256().toInt128(), j.toInt256().toInt128());
    }

    /// @dev Internal implementation of `exchange_underlying`
    function _exchange_underlying(int128 i, int128 j) internal {
        _exchange_impl(i, j, msg.data, true, false); // F: [ACV1-6]
    }

    /// @inheritdoc ICurveV1Adapter
    function exchange_all_underlying(int128 i, int128 j, uint256 rateMinRAY) external override creditFacadeOnly {
        _exchange_all_underlying(i, j, rateMinRAY);
    }

    /// @inheritdoc ICurveV1Adapter
    function exchange_all_underlying(uint256 i, uint256 j, uint256 rateMinRAY) external override creditFacadeOnly {
        _exchange_all_underlying(i.toInt256().toInt128(), j.toInt256().toInt128(), rateMinRAY);
    }

    /// @dev Internal implementation of `exchange_all_underlying`
    function _exchange_all_underlying(int128 i, int128 j, uint256 rateMinRAY) internal {
        address creditAccount = _creditAccount(); //F: [ACV1-3]

        address tokenIn = _get_token(i, true); // F: [ACV1-7]
        uint256 dx = IERC20(tokenIn).balanceOf(creditAccount); // F: [ACV1-7]
        if (dx <= 1) return;

        unchecked {
            dx--; // F: [ACV1-7]
        }
        uint256 min_dy = (dx * rateMinRAY) / RAY; // F: [ACV1-7]
        _exchange_impl(i, j, _getExchangeCallData(i, j, dx, min_dy, true), true, true); // F: [ACV1-7]
    }

    /// @dev Internal implementation of exchange functions
    ///      - passes calldata to the target contract
    ///      - sets max approval for the input token before the call and resets it to 1 after
    ///      - enables output asset after the call
    ///      - disables input asset only when exchanging the entire balance
    function _exchange_impl(int128 i, int128 j, bytes memory callData, bool underlying, bool disableTokenIn) internal {
        _approve_token(i, underlying, type(uint256).max);
        _execute(callData);
        _approve_token(i, underlying, 1);
        _changeEnabledTokens(_get_token_mask(j, underlying), disableTokenIn ? _get_token_mask(i, underlying) : 0);
    }

    /// @dev Returns calldata for `ICurvePool.exchange` and `ICurvePool.exchange_underlying` calls
    function _getExchangeCallData(int128 i, int128 j, uint256 dx, uint256 min_dy, bool underlying)
        internal
        view
        returns (bytes memory)
    {
        if (use256) {
            return underlying
                ? abi.encodeWithSignature(
                    "exchange_underlying(uint256,uint256,uint256,uint256)",
                    uint256(int256(i)),
                    uint256(int256(j)),
                    dx,
                    min_dy
                )
                : abi.encodeWithSignature(
                    "exchange(uint256,uint256,uint256,uint256)", uint256(int256(i)), uint256(int256(j)), dx, min_dy
                );
        } else {
            return underlying
                ? abi.encodeWithSignature("exchange_underlying(int128,int128,uint256,uint256)", i, j, dx, min_dy)
                : abi.encodeWithSignature("exchange(int128,int128,uint256,uint256)", i, j, dx, min_dy);
        }
    }

    /// ------------- ///
    /// ADD LIQUIDITY ///
    /// ------------- ///

    /// @dev Internal implementation of `add_liquidity`
    ///      - passes calldata to the target contract
    ///      - sets max approvals for the specified tokens before the call and resets them to 1 after
    ///      - enables LP token
    function _add_liquidity(bool t0Approve, bool t1Approve, bool t2Approve, bool t3Approve) internal {
        _approve_tokens(t0Approve, t1Approve, t2Approve, t3Approve, type(uint256).max);
        _execute(msg.data);
        _approve_tokens(t0Approve, t1Approve, t2Approve, t3Approve, 1);
        _changeEnabledTokens(lpTokenMask, 0);
    }

    /// @inheritdoc ICurveV1Adapter
    function add_liquidity_one_coin(uint256 amount, int128 i, uint256 minAmount) external override creditFacadeOnly {
        _add_liquidity_one_coin(amount, i, minAmount);
    }

    /// @inheritdoc ICurveV1Adapter
    function add_liquidity_one_coin(uint256 amount, uint256 i, uint256 minAmount) external override creditFacadeOnly {
        _add_liquidity_one_coin(amount, i.toInt256().toInt128(), minAmount);
    }

    /// @dev Internal implementation of `add_liquidity_one_coin`
    function _add_liquidity_one_coin(uint256 amount, int128 i, uint256 minAmount) internal {
        _add_liquidity_one_coin_impl(i, _getAddLiquidityOneCoinCallData(i, amount, minAmount), false); // F: [ACV1-8]
    }

    /// @inheritdoc ICurveV1Adapter
    function add_all_liquidity_one_coin(int128 i, uint256 rateMinRAY) external override creditFacadeOnly {
        _add_all_liquidity_one_coin(i, rateMinRAY);
    }

    /// @inheritdoc ICurveV1Adapter
    function add_all_liquidity_one_coin(uint256 i, uint256 rateMinRAY) external override creditFacadeOnly {
        _add_all_liquidity_one_coin(i.toInt256().toInt128(), rateMinRAY);
    }

    /// @dev Internal implementation of `add_all_liquidity_one_coin`
    function _add_all_liquidity_one_coin(int128 i, uint256 rateMinRAY) internal {
        address creditAccount = _creditAccount();

        address tokenIn = _get_token(i, false);
        uint256 amount = IERC20(tokenIn).balanceOf(creditAccount); // F: [ACV1-9]
        if (amount <= 1) return;

        unchecked {
            amount--; // F: [ACV1-9]
        }
        uint256 minAmount = (amount * rateMinRAY) / RAY; // F: [ACV1-9]
        _add_liquidity_one_coin_impl(i, _getAddLiquidityOneCoinCallData(i, amount, minAmount), true); // F: [ACV1-9]
    }

    /// @dev Internal implementation of `add_liquidity_one_coin` and `add_all_liquidity_one_coin`
    ///      - passes calldata to the target contract
    ///      - sets max approval for the input token before the call and resets it to 1 after
    ///      - enables LP token
    ///      - disables input token only when adding the entire balance
    function _add_liquidity_one_coin_impl(int128 i, bytes memory callData, bool disableTokenIn) internal {
        _approve_token(i, false, type(uint256).max);
        _execute(callData);
        _approve_token(i, false, 1);
        _changeEnabledTokens(lpTokenMask, disableTokenIn ? _get_token_mask(i, false) : 0);
    }

    /// @dev Returns calldata for `ICurvePool.add_liquidity` with one input asset
    function _getAddLiquidityOneCoinCallData(int128 i, uint256 amount, uint256 minAmount)
        internal
        view
        returns (bytes memory)
    {
        if (nCoins == 2) {
            uint256[2] memory amounts;
            if (i > 1) revert IncorrectIndexException();
            amounts[uint256(uint128(i))] = amount;
            return abi.encodeCall(ICurvePool2Assets.add_liquidity, (amounts, minAmount)); // F: [ACV1-8, ACV1-9]
        }
        if (nCoins == 3) {
            uint256[3] memory amounts;
            if (i > 2) revert IncorrectIndexException();
            amounts[uint256(uint128(i))] = amount;
            return abi.encodeCall(ICurvePool3Assets.add_liquidity, (amounts, minAmount)); // F: [ACV1-8, ACV1-9]
        }
        if (nCoins == 4) {
            uint256[4] memory amounts;
            if (i > 3) revert IncorrectIndexException();
            amounts[uint256(uint128(i))] = amount;
            return abi.encodeCall(ICurvePool4Assets.add_liquidity, (amounts, minAmount)); // F: [ACV1-8, ACV1-9]
        }
        revert("Incorrect nCoins");
    }

    /// ---------------- ///
    /// REMOVE LIQUIDITY ///
    /// ---------------- ///

    /// @dev Internal implementation of `remove_liquidity`
    ///      - passes calldata to the target contract
    ///      - enables all pool tokens
    function _remove_liquidity() internal {
        _execute(msg.data);
        _changeEnabledTokens(token0Mask | token1Mask | token2Mask | token3Mask, 0); // F: [ACV1_2-5, ACV1_3-5, ACV1_4-5]
    }

    /// @dev Internal implementation of `remove_liquidity_imbalance`
    ///      - passes calldata to the target contract
    ///      - enables specified pool tokens
    function _remove_liquidity_imbalance(bool t0Enable, bool t1Enable, bool t2Enable, bool t3Enable) internal {
        _execute(msg.data);

        uint256 tokensMask;
        if (t0Enable) tokensMask |= _get_token_mask(0, false); // F: [ACV1_2-6, ACV1_3-6, ACV1_4-6]
        if (t1Enable) tokensMask |= _get_token_mask(1, false); // F: [ACV1_2-6, ACV1_3-6, ACV1_4-6]
        if (t2Enable) tokensMask |= _get_token_mask(2, false); // F: [ACV1_3-6, ACV1_4-6]
        if (t3Enable) tokensMask |= _get_token_mask(3, false); // F: [ACV1_4-6]
        _changeEnabledTokens(tokensMask, 0); // F: [ACV1_2-6, ACV1_3-6, ACV1_4-6]
    }

    /// @inheritdoc ICurveV1Adapter
    function remove_liquidity_one_coin(uint256, int128 i, uint256) external virtual override creditFacadeOnly {
        _remove_liquidity_one_coin(i);
    }

    /// @inheritdoc ICurveV1Adapter
    function remove_liquidity_one_coin(uint256, uint256 i, uint256) external override creditFacadeOnly {
        _remove_liquidity_one_coin(i.toInt256().toInt128());
    }

    /// @dev Internal implementation of `remove_liquidity_one_coin`
    function _remove_liquidity_one_coin(int128 i) internal {
        _remove_liquidity_one_coin_impl(i, msg.data, false); // F: [ACV1-10]
    }

    /// @inheritdoc ICurveV1Adapter
    function remove_all_liquidity_one_coin(int128 i, uint256 rateMinRAY) external virtual override creditFacadeOnly {
        _remove_all_liquidity_one_coin(i, rateMinRAY);
    }

    /// @inheritdoc ICurveV1Adapter
    function remove_all_liquidity_one_coin(uint256 i, uint256 rateMinRAY) external override creditFacadeOnly {
        _remove_all_liquidity_one_coin(i.toInt256().toInt128(), rateMinRAY);
    }

    /// @dev Internal implementation of `remove_all_liquidity_one_coin`
    function _remove_all_liquidity_one_coin(int128 i, uint256 rateMinRAY) internal {
        address creditAccount = _creditAccount();

        uint256 amount = IERC20(lp_token).balanceOf(creditAccount); // F: [ACV1-11]
        if (amount <= 1) return;

        unchecked {
            amount--; // F: [ACV1-11]
        }
        uint256 minAmount = (amount * rateMinRAY) / RAY; // F: [ACV1-11]
        _remove_liquidity_one_coin_impl(i, _getRemoveLiquidityOneCoinCallData(i, amount, minAmount), true); // F: [ACV1-11]
    }

    /// @dev Internal implementation of `remove_liquidity_one_coin` and `remove_all_liquidity_one_coin`
    ///      - passes calldata to the targe contract
    ///      - enables received asset
    ///      - disables LP token only when removing all liquidity
    function _remove_liquidity_one_coin_impl(int128 i, bytes memory callData, bool disableLP) internal {
        _execute(callData);
        _changeEnabledTokens(_get_token_mask(i, false), disableLP ? lpTokenMask : 0);
    }

    /// @dev Returns calldata for `ICurvePool.remove_liquidity_one_coin` call
    function _getRemoveLiquidityOneCoinCallData(int128 i, uint256 amount, uint256 minAmount)
        internal
        view
        returns (bytes memory)
    {
        if (use256) {
            return abi.encodeWithSignature(
                "remove_liquidity_one_coin(uint256,uint256,uint256)", amount, uint256(int256(i)), minAmount
            );
        } else {
            return abi.encodeWithSignature("remove_liquidity_one_coin(uint256,int128,uint256)", amount, i, minAmount);
        }
    }

    /// ------- ///
    /// HELPERS ///
    /// ------- ///

    /// @dev Returns token `i`'s address
    function _get_token(int128 i, bool underlying) internal view returns (address addr) {
        if (i == 0) {
            addr = underlying ? underlying0 : token0;
        } else if (i == 1) {
            addr = underlying ? underlying1 : token1;
        } else if (i == 2) {
            addr = underlying ? underlying2 : token2;
        } else if (i == 3) {
            addr = underlying ? underlying3 : token3;
        }

        if (addr == address(0)) revert IncorrectIndexException();
    }

    /// @dev Returns token `i`'s mask
    function _get_token_mask(int128 i, bool underlying) internal view returns (uint256 mask) {
        if (i == 0) {
            mask = underlying ? underlying0Mask : token0Mask;
        } else if (i == 1) {
            mask = underlying ? underlying1Mask : token1Mask;
        } else if (i == 2) {
            mask = underlying ? underlying2Mask : token2Mask;
        } else if (i == 3) {
            mask = underlying ? underlying3Mask : token3Mask;
        }

        if (mask == 0) revert IncorrectIndexException();
    }

    /// @dev Sets target contract's approval for token `i` to `amount`
    function _approve_token(int128 i, bool underlying, uint256 amount) internal {
        _approveToken(_get_token(i, underlying), amount);
    }

    /// @dev Sets target contract's approval for specified tokens to `amount`
    function _approve_tokens(bool t0Approve, bool t1Approve, bool t2Approve, bool t3Approve, uint256 amount) internal {
        if (t0Approve) _approveToken(token0, amount); // F: [ACV1_2-4, ACV1_3-4, ACV1_4-4]
        if (t1Approve) _approveToken(token1, amount); // F: [ACV1_2-4, ACV1_3-4, ACV1_4-4]
        if (t2Approve) _approveToken(token2, amount); // F: [ACV1_3-4, ACV1_4-4]
        if (t3Approve) _approveToken(token3, amount); // F: [ACV1_4-4]
    }

    /// @inheritdoc ICurveV1Adapter
    function calc_add_one_coin(uint256 amount, int128 i) public view returns (uint256) {
        if (nCoins == 2) {
            return i == 0
                ? ICurvePool2Assets(targetContract).calc_token_amount([amount, 0], true)
                : ICurvePool2Assets(targetContract).calc_token_amount([0, amount], true);
        } else if (nCoins == 3) {
            return i == 0
                ? ICurvePool3Assets(targetContract).calc_token_amount([amount, 0, 0], true)
                : i == 1
                    ? ICurvePool3Assets(targetContract).calc_token_amount([0, amount, 0], true)
                    : ICurvePool3Assets(targetContract).calc_token_amount([0, 0, amount], true);
        } else if (nCoins == 4) {
            return i == 0
                ? ICurvePool4Assets(targetContract).calc_token_amount([amount, 0, 0, 0], true)
                : i == 1
                    ? ICurvePool4Assets(targetContract).calc_token_amount([0, amount, 0, 0], true)
                    : i == 2
                        ? ICurvePool4Assets(targetContract).calc_token_amount([0, 0, amount, 0], true)
                        : ICurvePool4Assets(targetContract).calc_token_amount([0, 0, 0, amount], true);
        } else {
            revert("Incorrect nCoins");
        }
    }

    /// @inheritdoc ICurveV1Adapter
    function calc_add_one_coin(uint256 amount, uint256 i) external view returns (uint256) {
        return calc_add_one_coin(amount, i.toInt256().toInt128());
    }
}