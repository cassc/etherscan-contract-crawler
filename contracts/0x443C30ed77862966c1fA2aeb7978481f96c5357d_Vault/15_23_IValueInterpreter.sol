// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IValueInterpreter {

    /// @notice Calculates the value of a given amount of one asset in terms of another asset
    /// @param _baseAsset The asset from which to convert
    /// @param _amount The amount of the _baseAsset to convert
    /// @param _quoteAsset The asset to which to convert
    /// @return _value The equivalent quantity in the _quoteAsset
    /// @dev Does not alter protocol state,
    /// but not a view because calls to price feeds can potentially update third party state
    function calcCanonicalAssetValue(
        address _baseAsset,
        uint256 _amount,
        address _quoteAsset
    ) external view returns (uint256);

    /// @notice Calculates the total value of given amounts of assets in a single quote asset
    /// @param _baseAssets The assets to convert
    /// @param _amounts The amounts of the _baseAssets to convert
    /// @param _quoteAsset The asset to which to convert
    /// @return _value The sum value of _baseAssets, denominated in the _quoteAsset
    /// @dev Does not alter protocol state,
    /// but not a view because calls to price feeds can potentially update third party state.
    /// Does not handle a derivative quote asset.
    function calcCanonicalAssetsTotalValue(
        address[] calldata _baseAssets,
        uint256[] calldata _amounts,
        address _quoteAsset
    ) external view returns (uint256);

    
    /// @dev Calculate the usd value of a specified number of assets
    /// @param _baseAsset Source token address
    /// @param _amount The amount of source token
    /// @return usd(1e18)
    function calcCanonicalAssetValueInUsd(
        address _baseAsset,
        uint256 _amount
    ) external view returns (uint256);

     
    /// @dev Calculate the usd value of baseUnit volume assets
    /// @param _baseAsset The ssset token address
    /// @return usd(1e18)
    function price(address _baseAsset) external view returns (uint256);
}