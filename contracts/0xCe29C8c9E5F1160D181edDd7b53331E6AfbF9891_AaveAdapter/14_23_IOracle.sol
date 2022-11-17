// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IOracle {
    function BASE_CURRENCY() external view returns (address);

    function BASE_CURRENCY_UNIT() external view returns (uint256);

    function getAssetPrice(address asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata assets)
        external
        view
        returns (uint256[] calldata);

    function getFallbackOracle() external view returns (address);

    function getSourceOfAsset(address asset) external view returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setAssetSources(
        address[] calldata assets,
        address[] calldata sources
    ) external;

    function setFallbackOracle(address fallbackOracle) external;

    function transferOwnership(address newOwner) external;
}