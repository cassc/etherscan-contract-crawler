// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ICurve} from "../interfaces/curve/ICurve.sol";

/// Helper abstract contract to manage curve swaps
abstract contract CurveSwapper {
    using SafeERC20 for IERC20;

    //
    // Structs
    //

    struct Swapper {
        /// Curve pool instance
        ICurve pool;
        /// decimals in token
        uint8 tokenDecimals;
        /// decimals in underlying
        uint8 underlyingDecimals;
        /// index of the deposit token we want to exchange to/from underlying
        int128 tokenI;
        /// index of underlying used by the vault (presumably always UST)
        int128 underlyingI;
    }

    struct SwapPoolParam {
        address token;
        address pool;
        int128 tokenI;
        int128 underlyingI;
    }

    //
    // Events
    //

    /// Emitted when a new swap pool is added
    event CurveSwapPoolAdded(
        address indexed token,
        address indexed pool,
        int128 tokenI,
        int128 underlyingI
    );

    /// Emitted when a swap pool is removed
    event CurveSwapPoolRemoved(address indexed token);

    /// Emitted after every swap
    event Swap(
        address indexed fromToken,
        address indexed toToken,
        uint256 fromAmount,
        uint256 toAmount
    );

    error SwapperPoolAlreadyExists(address token);
    error SwapperPoolDoesNotExist(address token);
    error SwapperUnderlyingIndexMismatch(address token, address underlying);

    //
    // State
    //

    /// token => curve pool (for trading token/underlying)
    mapping(address => Swapper) public swappers;

    /// @return The address of the vault's main underlying token
    function getUnderlying() public view virtual returns (address);

    /// Swaps a given amount of
    /// Only works if the pool has previously been inserted into the contract
    ///
    /// @param _token The token we want to swap into
    /// @param _amount The amount of underlying we want to swap
    /// @param _amountOutMin The minimum amount of tokens we want to receive
    function _swapIntoUnderlying(
        address _token,
        uint256 _amount,
        uint256 _amountOutMin
    ) internal returns (uint256 amount) {
        address underlyingToken = getUnderlying();
        if (_token == underlyingToken) {
            // same token, nothing to do
            return _amount;
        }

        Swapper storage swapper = swappers[_token];

        if (address(swapper.pool) == address(0x0)) {
            // pool does not exist
            revert SwapperPoolDoesNotExist(_token);
        }

        amount = swapper.pool.exchange_underlying(
            swapper.tokenI,
            swapper.underlyingI,
            _amount,
            _amountOutMin
        );

        emit Swap(_token, underlyingToken, _amount, amount);
    }

    /// Swaps a given amount of Underlying into a given token
    /// Only works if the pool has previously been inserted into the contract
    ///
    /// @param _token The token we want to swap into
    /// @param _amount The amount of underlying we want to swap
    /// @param _amountOutMin The minimum amount of tokens we want to receive
    function _swapFromUnderlying(
        address _token,
        uint256 _amount,
        uint256 _amountOutMin
    ) internal returns (uint256 amount) {
        // same token, nothing to do
        if (_token == getUnderlying()) return _amount;

        Swapper storage swapper = swappers[_token];

        if (address(swapper.pool) == address(0x0))
            revert SwapperPoolDoesNotExist(_token);

        amount = swapper.pool.exchange_underlying(
            swapper.underlyingI,
            swapper.tokenI,
            _amount,
            _amountOutMin
        );

        emit Swap(getUnderlying(), _token, _amount, amount);
    }

    /// This is necessary because some tokens (USDT) force you to approve(0)
    /// before approving a new amount meaning if we always approved blindly,
    /// then we could get random failures on the second attempt
    function _approveIfNecessary(address _token, address _pool) internal {
        uint256 allowance = IERC20(_token).allowance(address(this), _pool);

        if (allowance == 0) {
            IERC20(_token).safeApprove(_pool, type(uint256).max);
        }
    }

    /// @param _swapPools configs for each swap pool
    function _addPools(SwapPoolParam[] memory _swapPools) internal {
        uint256 length = _swapPools.length;
        for (uint256 i = 0; i < length; ++i) {
            _addPool(_swapPools[i]);
        }
    }

    function _addPool(SwapPoolParam memory _param) internal {
        if (address(swappers[_param.token].pool) != address(0))
            revert SwapperPoolAlreadyExists(_param.token);

        // _underlyingI does not match underlying token
        if (
            getUnderlying() !=
            ICurve(_param.pool).coins(uint256(uint128(_param.underlyingI)))
        ) revert SwapperUnderlyingIndexMismatch(_param.token, getUnderlying());

        uint256 tokenDecimals = IERC20Metadata(_param.token).decimals();
        uint256 underlyingDecimals = IERC20Metadata(getUnderlying()).decimals();

        swappers[_param.token] = Swapper(
            ICurve(_param.pool),
            uint8(tokenDecimals),
            uint8(underlyingDecimals),
            _param.tokenI,
            _param.underlyingI
        );

        _approveIfNecessary(getUnderlying(), address(_param.pool));
        _approveIfNecessary(_param.token, address(_param.pool));

        emit CurveSwapPoolAdded(
            _param.token,
            _param.pool,
            _param.tokenI,
            _param.underlyingI
        );
    }

    function _removePool(address _inputToken) internal {
        if (address(swappers[_inputToken].pool) == address(0))
            revert SwapperPoolDoesNotExist(_inputToken);

        delete swappers[_inputToken];

        emit CurveSwapPoolRemoved(_inputToken);
    }
}