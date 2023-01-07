// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/external/curve/ICurveAddressProvider.sol";
import "../interfaces/external/IWETH.sol";
import "../interfaces/ICurveAdapter.sol";

contract CurveAdapter is ICurveAdapter {
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant SWAPS_ADDRESS_ID = 2;
    uint256 private constant METAPOOL_FACTORY_ADDRESS_ID = 3;

    IWETH public immutable nativeToken;
    ICurveSwaps public immutable override swaps;
    ICurveFactoryRegistry public immutable registry;

    constructor(IWETH nativeToken_) {
        nativeToken = nativeToken_;

        ICurveAddressProvider ADDRESS_PROVIDER = ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);
        registry = ICurveFactoryRegistry(ADDRESS_PROVIDER.get_address(METAPOOL_FACTORY_ADDRESS_ID));
        swaps = ICurveSwaps(ADDRESS_PROVIDER.get_address(SWAPS_ADDRESS_ID));
    }

    function swap(
        uint256 amountIn_,
        uint256 amountOutMin_,
        address[] memory path_
    ) external payable override returns (uint256 _amountOut) {
        address _tokenIn = path_[0];
        address _tokenOut = path_[1];
        uint256 _tokenInBalance = IERC20(_tokenIn).balanceOf(address(this));

        if (_tokenIn == address(nativeToken) && _tokenInBalance > 0) {
            // Withdraw ETH from WETH if any
            nativeToken.withdraw(_tokenInBalance);
        }

        if (amountIn_ == type(uint256).max) {
            amountIn_ = _tokenIn == address(nativeToken) ? address(this).balance : _tokenInBalance;
        }

        if (amountIn_ == 0) {
            // Doesn't revert
            return 0;
        }

        if (_tokenIn == address(nativeToken)) {
            _tokenIn = ETH_ADDRESS;
            return
                swaps.exchange{value: amountIn_}(
                    registry.find_pool_for_coins(_tokenIn, _tokenOut),
                    _tokenIn,
                    _tokenOut,
                    amountIn_,
                    amountOutMin_,
                    address(this)
                );
        }

        if (_tokenOut == address(nativeToken)) {
            _tokenOut = ETH_ADDRESS;
        }

        return
            swaps.exchange(
                registry.find_pool_for_coins(_tokenIn, _tokenOut),
                _tokenIn,
                _tokenOut,
                amountIn_,
                amountOutMin_,
                address(this)
            );
    }

    receive() external payable {}
}