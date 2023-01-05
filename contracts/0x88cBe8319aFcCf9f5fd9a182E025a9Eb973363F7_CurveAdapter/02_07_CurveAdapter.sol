// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/external/curve/ICurveAddressProvider.sol";
import "../interfaces/external/IWETH.sol";
import "../interfaces/ICurveAdapter.sol";

contract CurveAdapter is ICurveAdapter {
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
        if (amountIn_ == type(uint256).max) {
            amountIn_ = _tokenIn == address(nativeToken)
                ? address(this).balance
                : IERC20(_tokenIn).balanceOf(address(this));
        }

        if (amountIn_ == 0) return 0;

        if (_tokenIn == address(nativeToken) && address(this).balance > 0) {
            // Note: Assuming msAsset/WETH Curve pool, if we use msAsset/ETH instead we'll have to change this
            nativeToken.deposit{value: address(this).balance}();
        }

        address _tokenOut = path_[1];
        _amountOut = swaps.exchange(
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