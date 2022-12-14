// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/swapper/IExchange.sol";
import "../interfaces/external/curve/ICurveAddressProvider.sol";
import "../interfaces/external/curve/ICurveSwaps.sol";

/**
 * @title CurveExchange Exchange.
 * @notice Implemented as per https://curve.readthedocs.io/registry-exchanges.html
 */
contract CurveExchange is IExchange {
    using SafeERC20 for IERC20;
    ICurveAddressProvider public immutable addressProvider;
    uint256 private constant SWAPS_ADDRESS_ID = 2;

    constructor(address addressProvider_) {
        require(addressProvider_ != address(0), "addressProvider-is-null");
        addressProvider = ICurveAddressProvider(addressProvider_);
    }

    /// @inheritdoc IExchange
    /// @dev It iterates through all the curve pools which support `tokenIn_` and `tokenOut_` pair and would consume more gas.
    /// @notice Wraps `swaps.get_best_rate()` function
    function getBestAmountOut(
        address tokenIn_,
        address tokenOut_,
        uint256 amountIn_
    ) external view override returns (uint256 _amountOut, bytes memory _path) {
        address _curvePool;
        (_curvePool, _amountOut) = getSwaps().get_best_rate(tokenIn_, tokenOut_, amountIn_);
        _path = abi.encode(_curvePool, tokenIn_, tokenOut_);
    }

    /// @inheritdoc IExchange
    /// @notice Wraps `swaps.get_exchange_amount()` function
    function getAmountsOut(uint256 amountIn_, bytes memory path_) external view override returns (uint256 _amountOut) {
        (address _curvePool, address _tokenIn, address _tokenOut) = abi.decode(path_, (address, address, address));
        _amountOut = getSwaps().get_exchange_amount(_curvePool, _tokenIn, _tokenOut, amountIn_);
    }

    /// @inheritdoc IExchange
    /// @notice Wraps `swaps.exchange()` function
    function swapExactInput(
        bytes calldata path_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address outReceiver_
    ) external override returns (uint256 _amountOut) {
        (address _curvePool, address _tokenIn, address _tokenOut) = abi.decode(path_, (address, address, address));
        IERC20 _tokenInContract = IERC20(_tokenIn);
        ICurveSwaps _swaps = getSwaps();
        if (_tokenInContract.allowance(address(this), address(_swaps)) < amountIn_) {
            _tokenInContract.approve(address(_swaps), type(uint256).max);
        }
        _amountOut = _swaps.exchange(_curvePool, _tokenIn, _tokenOut, amountIn_, amountOutMin_, outReceiver_);
    }

    // @dev Not supported by curve
    /**  solhint-disable */

    function getBestAmountIn(
        address tokenIn_,
        address tokenOut_,
        uint256 amountOut_
    ) external pure override returns (uint256 _amountIn, bytes memory _path) {
        revert("not-supported");
    }

    /**
     * @dev Not supported by curve
     */
    function getAmountsIn(uint256 amountOut_, bytes memory path_) external pure override returns (uint256 _amountIn) {
        revert("not-supported");
    }

    /**
     * @dev Not supported by curve
     */
    function swapExactOutput(
        bytes calldata path_,
        uint256 amountOut_,
        uint256 amountInMax_,
        address remainingReceiver_,
        address outReceiver_
    ) external pure override returns (uint256 _amountIn) {
        revert("not-supported");
    }

    /** solhint-enable */

    /**  private methods */

    // Get curve swaps address from address provider
    function getSwaps() private view returns (ICurveSwaps) {
        return ICurveSwaps(addressProvider.get_address(SWAPS_ADDRESS_ID));
    }
}