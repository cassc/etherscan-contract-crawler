// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./IOracle.sol";

abstract contract AssetOracleAdapter is IOracle {
    string public assetName;
    /// @dev asset symbol
    string public assetSymbol;
    /// @dev admin allowed to update price oracle
    /// @notice the asset with the price oracle
    address public immutable asset;

    constructor(
        string memory _assetName,
        string memory _assetSymbol,
        address _asset
    ) {
        require(_asset != address(0), "invalid asset");
        assetName = _assetName;
        assetSymbol = _assetSymbol;
        asset = _asset;
    }
}
