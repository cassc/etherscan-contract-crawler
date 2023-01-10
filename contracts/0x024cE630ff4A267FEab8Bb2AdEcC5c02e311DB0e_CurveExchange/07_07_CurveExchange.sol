// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

    uint256 private constant SWAPS_ADDRESS_ID = 2;

    ICurveAddressProvider public immutable addressProvider;

    constructor(address addressProvider_) {
        require(addressProvider_ != address(0), "addressProvider-is-null");
        addressProvider = ICurveAddressProvider(addressProvider_);
    }

    /// @inheritdoc IExchange
    function getAmountsOut(uint256 amountIn_, bytes memory path_) external view override returns (uint256 _amountOut) {
        (address[9] memory _route, uint256[3][4] memory _params) = abi.decode(path_, (address[9], uint256[3][4]));
        _amountOut = _getSwaps().get_exchange_multiple_amount(_route, _params, amountIn_);
    }

    /// @inheritdoc IExchange
    function swapExactInput(
        bytes calldata path_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        address outReceiver_
    ) external override returns (uint256 _amountOut) {
        (address[9] memory _route, uint256[3][4] memory _params) = abi.decode(path_, (address[9], uint256[3][4]));

        IERC20 _tokenIn = IERC20(_route[0]);
        ICurveSwaps _swaps = _getSwaps();

        if (_tokenIn.allowance(address(this), address(_swaps)) < amountIn_) {
            _tokenIn.approve(address(_swaps), type(uint256).max);
        }

        // Array of pools for swaps via zap contracts. This parameter is only needed for Polygon meta-factories underlying swaps.
        address[4] memory _pools;
        _pools[0] = address(0);
        _pools[1] = address(0);
        _pools[2] = address(0);
        _pools[3] = address(0);

        _amountOut = _swaps.exchange_multiple(_route, _params, amountIn_, amountOutMin_, _pools, outReceiver_);
    }

    /// @inheritdoc IExchange
    /// @dev Not properly supported by curve
    function getAmountsIn(
        uint256 /*amountOut_*/,
        bytes memory /*path_*/
    ) external pure override returns (uint256 /*_amountIn*/) {
        revert("not-supported");
    }

    /// @inheritdoc IExchange
    /// @dev Not properly supported by curve
    function swapExactOutput(
        bytes calldata /*path_*/,
        uint256 /*amountOut_*/,
        uint256 /*amountInMax_*/,
        address /*remainingReceiver_*/,
        address /*outReceiver_*/
    ) external pure override returns (uint256 /*_amountIn*/) {
        revert("not-supported");
    }

    function _getSwaps() private view returns (ICurveSwaps) {
        return ICurveSwaps(addressProvider.get_address(SWAPS_ADDRESS_ID));
    }
}