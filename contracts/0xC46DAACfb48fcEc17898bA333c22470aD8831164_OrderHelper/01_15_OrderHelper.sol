// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./libraries/FixedPoint112.sol";
import "./libraries/FullMath.sol";

import "./interfaces/IIndex.sol";
import "./interfaces/IvTokenFactory.sol";
import "./interfaces/IvToken.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IOrderer.sol";

contract OrderHelper {
    using FullMath for uint;

    /// @notice Role for asset
    bytes32 internal constant ASSET_ROLE = keccak256("ASSET_ROLE");

    struct Order {
        uint shares;
        uint amountInAsset;
        uint amountInBase;
        uint assetPrice;
        address asset;
        uint8 decimals;
        bool isInactive;
        IOrderer.OrderSide side;
    }

    function orderOf(address _index) external returns (Order[] memory _orders) {
        IvTokenFactory vTokenFactory = IvTokenFactory(IIndex(_index).vTokenFactory());
        IIndexRegistry registry = IIndexRegistry(IIndex(_index).registry());
        IOrderer orderer = IOrderer(registry.orderer());
        IPriceOracle priceOracle = IPriceOracle(registry.priceOracle());

        IOrderer.Order memory order = orderer.orderOf(_index);
        _orders = new Order[](order.assets.length);

        for (uint i; i < order.assets.length; ++i) {
            IOrderer.OrderAsset memory asset = order.assets[i];
            IvToken vToken = IvToken(vTokenFactory.vTokenOf(asset.asset));
            uint vTokenBalance = vToken.balanceOf(_index);
            uint amountInAsset = vToken.assetBalanceForShares(asset.shares);
            uint assetPrice = priceOracle.refreshedAssetPerBaseInUQ(asset.asset);
            uint amountInBase = amountInAsset.mulDiv(FixedPoint112.Q112, assetPrice);

            _orders[i] = Order({
                assetPrice: assetPrice,
                shares: asset.shares,
                amountInAsset: amountInAsset,
                amountInBase: amountInBase,
                asset: asset.asset,
                decimals: IERC20Metadata(asset.asset).decimals(),
                // @notice if selling all shares, asset is inactive
                isInactive: asset.shares >= vTokenBalance,
                side: asset.side
            });
        }
    }
}