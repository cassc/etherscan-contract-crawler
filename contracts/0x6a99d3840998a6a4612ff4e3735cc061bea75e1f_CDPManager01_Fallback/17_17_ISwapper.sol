// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;


interface ISwapper {

    /**
     * @notice Predict asset amount after usdp swap
     */
    function predictAssetOut(address _asset, uint256 _usdpAmountIn) external view returns (uint predictedAssetAmount);

    /**
     * @notice Predict USDP amount after asset swap
     */
    function predictUsdpOut(address _asset, uint256 _assetAmountIn) external view returns (uint predictedUsdpAmount);

    /**
     * @notice usdp must be approved to swapper
     * @dev asset must be sent to user after swap
     */
    function swapUsdpToAsset(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount) external returns (uint swappedAssetAmount);

    /**
     * @notice asset must be approved to swapper
     * @dev usdp must be sent to user after swap
     */
    function swapAssetToUsdp(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount) external returns (uint swappedUsdpAmount);

    /**
     * @notice DO NOT SEND tokens to contract manually. For usage in contracts only.
     * @dev for gas saving with usage in contracts tokens must be send directly to contract instead
     * @dev asset must be sent to user after swap
     */
    function swapUsdpToAssetWithDirectSending(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount) external returns (uint swappedAssetAmount);

    /**
     * @notice DO NOT SEND tokens to contract manually. For usage in contracts only.
     * @dev for gas saving with usage in contracts tokens must be send directly to contract instead
     * @dev usdp must be sent to user after swap
     */
    function swapAssetToUsdpWithDirectSending(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount) external returns (uint swappedUsdpAmount);
}