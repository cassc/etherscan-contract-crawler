// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./libraries/FullMath.sol";
import "./libraries/FixedPoint112.sol";

import "./interfaces/IUniswapPathPriceOracle.sol";

/// @title Uniswap path price oracle
/// @notice Contains logic for price calculation of asset which doesn't have a pair with a base asset
contract UniswapPathPriceOracle is IUniswapPathPriceOracle, ERC165 {
    using FullMath for uint;

    /// @notice List of assets to compose exchange pairs, where first element is input asset
    address[] internal path;
    /// @notice List of corresponding price oracles for provided path
    address[] internal oracles;

    constructor(address[] memory _path, address[] memory _oracles) {
        uint pathsCount = _path.length;
        require(pathsCount >= 2, "UniswapPathPriceOracle: PATH");
        require(_oracles.length == pathsCount - 1, "UniswapPathPriceOracle: ORACLES");

        path = _path;
        oracles = _oracles;
    }

    /// @inheritdoc IPriceOracle
    function refreshedAssetPerBaseInUQ(address _asset) external override returns (uint currentAssetPerBaseInUQ) {
        require(_asset == path[path.length - 1], "UniswapPathPriceOracle: INVALID");

        currentAssetPerBaseInUQ = FixedPoint112.Q112;

        uint oraclesCount = oracles.length;
        for (uint i; i < oraclesCount; ) {
            currentAssetPerBaseInUQ = currentAssetPerBaseInUQ.mulDiv(
                IPriceOracle(oracles[i]).refreshedAssetPerBaseInUQ(path[i + 1]),
                FixedPoint112.Q112
            );

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IUniswapPathPriceOracle
    function anatomy() external view override returns (address[] memory _path, address[] memory _oracles) {
        _path = path;
        _oracles = oracles;
    }

    /// @inheritdoc IPriceOracle
    function lastAssetPerBaseInUQ(address _asset) external view override returns (uint currentAssetPerBaseInUQ) {
        require(_asset == path[path.length - 1], "UniswapPathPriceOracle: INVALID");

        currentAssetPerBaseInUQ = FixedPoint112.Q112;

        uint oraclesCount = oracles.length;
        for (uint i; i < oraclesCount; ) {
            currentAssetPerBaseInUQ = currentAssetPerBaseInUQ.mulDiv(
                IPriceOracle(oracles[i]).lastAssetPerBaseInUQ(path[i + 1]),
                FixedPoint112.Q112
            );

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IUniswapPathPriceOracle).interfaceId ||
            _interfaceId == type(IPriceOracle).interfaceId ||
            super.supportsInterface(_interfaceId);
    }
}