pragma solidity 0.8.15;

import "CurveMetapoolLibrary.sol";
import "WrappedERC4626CurveConvex.sol";

contract WrappedERC4626CurveMetapoolConvex is WrappedERC4626CurveConvex {
    using CurveMetapoolLibrary for CurveMetapoolLibrary.CurveMetapool;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    CurveMetapoolLibrary.CurveMetapool public curveMetapool;

    struct ConstructorParameters {
        CurveMetapoolLibrary.CurveMetapool curveMetapool;
        IERC20 crv;
        IERC20 cvx;
        bool stakeInYCRV;
        WrappedERC4626YearnCRV ycrvVault;
        IConvexBooster convexBooster;
        IConvexReward convexReward;
        AssetConverter assetConverter;
        uint256 convexPoolId;
        string name;
        string symbol;
    }

    constructor(ConstructorParameters memory params)
        WrappedERC4626CurveConvex(
            params.crv,
            params.cvx,
            params.stakeInYCRV,
            params.ycrvVault,
            params.convexBooster,
            params.convexReward,
            params.curveMetapool.depositToken,
            params.curveMetapool.LPToken,
            params.assetConverter,
            params.convexPoolId,
            params.name,
            params.symbol
        )
    {
        require(
            params.curveMetapool.zapAddress != address(0),
            "Zero address provided"
        );
        require(
            params.curveMetapool.poolAddress != address(0),
            "Zero address provided"
        );

        curveMetapool = params.curveMetapool;

        curveMetapool.LPToken.safeIncreaseAllowance(
            curveMetapool.zapAddress,
            type(uint256).max
        );
        curveMetapool.depositToken.safeIncreaseAllowance(curveMetapool.zapAddress, type(uint256).max);
    }

    function _addLiquidity(uint256 assets)
        internal
        override
        returns (uint256 lpAmount)
    {
        return curveMetapool.addLiquidity(assets);
    }

    function _removeLiquidity(uint256 lpAmount)
        internal
        override
        returns (uint256 assets)
    {
        return curveMetapool.removeLiquidity(lpAmount);
    }

    function _getVirtualPrice() internal override view returns(uint256) {
        return curveMetapool.getVirtualPrice();
    }
}