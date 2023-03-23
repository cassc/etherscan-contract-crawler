// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOracleGetter.sol";

/**
 * @title NFTOracle
 * @author NFTCall
 * @notice Smart contract to get the price of an asset from a price source, with BenDAO
 *          smart contracts as primary option
 *  - If the returned price by BenDAO is <= 0, the call is forwarded to a fallbackOracle
 *  - Owner allowed to add sources for assets, replace them and change the fallbackOracle
 */
contract NFTOracle is IOracleGetter, Ownable {
    struct Source {
        address addr;
        bytes4 selector;
    }
    mapping(address => Source) private assetsSources;
    IOracleGetter private _fallbackOracle;

    event AssetSourceUpdated(
        address indexed asset,
        address indexed source,
        bytes4 selector
    );
    event FallbackOracleUpdated(address indexed fallbackOracle);

    /**
     * @dev Constructor
     * @param assets The addresses of the assets
     * @param sources The Source of the source of each asset
     * @param fallbackOracle The address of the fallback oracle to use
     */
    constructor(
        address[] memory assets,
        Source[] memory sources,
        address fallbackOracle
    ) {
        _setFallbackOracle(fallbackOracle);
        _setAssetsSources(assets, sources);
    }

    /**
     * @dev External function called by the owner to set or replace sources of assets
     * @param assets The addresses of the assets
     * @param sources The Source of the source of each asset
     */
    function setAssetSources(
        address[] memory assets,
        Source[] memory sources
    ) external onlyOwner {
        _setAssetsSources(assets, sources);
    }

    /**
     * @dev Sets the fallbackOracle
     * - Callable only by the owner
     * @param fallbackOracle The address of the fallbackOracle
     */
    function setFallbackOracle(address fallbackOracle) external onlyOwner {
        _setFallbackOracle(fallbackOracle);
    }

    /**
     * @dev Internal function to set the sources for each asset
     * @param assets The addresses of the assets
     * @param sources The Source of the source of each asset
     */
    function _setAssetsSources(
        address[] memory assets,
        Source[] memory sources
    ) internal {
        require(assets.length == sources.length, "INCONSISTENT_PARAMS_LENGTH");
        for (uint256 i = 0; i < assets.length; i++) {
            Source memory source = sources[i];
            assetsSources[assets[i]] = source;
            emit AssetSourceUpdated(assets[i], source.addr, source.selector);
        }
    }

    /**
     * @dev Internal function to set the fallbackOracle
     * @param fallbackOracle The address of the fallbackOracle
     */
    function _setFallbackOracle(address fallbackOracle) internal {
        _fallbackOracle = IOracleGetter(fallbackOracle);
        emit FallbackOracleUpdated(fallbackOracle);
    }

    /**
     * @dev Get an asset price by address
     * @param asset The asset address
     */
    function getAssetPrice(
        address asset
    ) public view override returns (uint256) {
        Source memory source = assetsSources[asset];

        uint256 price;
        if (address(source.addr) != address(0)) {
            (bool success, bytes memory returnedData) = source.addr.staticcall(
                abi.encodeWithSelector(source.selector, asset)
            );
            require(success);
            price = abi.decode(returnedData, (uint256));
        }
        if (price > 0) {
            return price;
        } else {
            return _fallbackOracle.getAssetPrice(asset);
        }
    }

    /**
     * @dev Get volatility by address
     * @param asset The asset address
     */
    function getAssetVol(address asset) public view override returns (uint256) {
        return _fallbackOracle.getAssetVol(asset);
    }

    function getAssets(
        address[] memory assets
    ) external view returns (uint256[2][] memory prices) {
        prices = new uint256[2][](assets.length);
        uint256 price;
        uint256 vol;
        for (uint256 i = 0; i < assets.length; i++) {
            price = getAssetPrice(assets[i]);
            vol = getAssetVol(assets[i]);
            prices[i] = [price, vol];
        }
        return prices;
    }

    /**
     * @dev Gets the address of the source for an asset address
     * @param asset The address of the asset
     * @return address The Source of the source
     */
    function getSourceOfAsset(
        address asset
    ) external view returns (Source memory) {
        return assetsSources[asset];
    }

    /**
     * @dev Gets the address of the fallback oracle
     * @return address The addres of the fallback oracle
     */
    function getFallbackOracle() external view returns (address) {
        return address(_fallbackOracle);
    }
}