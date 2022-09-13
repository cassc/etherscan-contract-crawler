// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libraries/FixedPoint112.sol";
import "./libraries/FullMath.sol";

import "./interfaces/IIndex.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IvToken.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IPriceOracle.sol";

contract IndexNAV {
    using FullMath for uint;

    function getNAV(address _index) external view returns (uint _nav, uint _totalSupply) {
        IIndex index = IIndex(_index);
        _totalSupply = IERC20(_index).totalSupply();
        (address[] memory assets, ) = index.anatomy();
        IvTokenFactory vTokenFactory = IvTokenFactory(index.vTokenFactory());
        IIndexRegistry registry = IIndexRegistry(index.registry());
        IPriceOracle priceOracle = IPriceOracle(registry.priceOracle());
        for (uint i; i < assets.length; ++i) {
            uint assetValue = IvToken(vTokenFactory.vTokenOf(assets[i])).assetBalanceOf(_index);
            _nav += assetValue.mulDiv(FixedPoint112.Q112, priceOracle.lastAssetPerBaseInUQ(assets[i]));
        }
    }
}