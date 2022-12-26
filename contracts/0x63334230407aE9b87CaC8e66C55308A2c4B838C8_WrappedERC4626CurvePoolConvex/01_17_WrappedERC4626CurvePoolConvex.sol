pragma solidity 0.8.15;

import "IERC20Metadata.sol";
import "SafeERC20.sol";
import "CurveLibrary.sol";
import "WrappedERC4626CurveConvex.sol";

contract WrappedERC4626CurvePoolConvex is WrappedERC4626CurveConvex {
    using CurveLibrary for CurveLibrary.CurvePool;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    CurveLibrary.CurvePool public curvePool;

    struct ConstructorParameters {
        CurveLibrary.CurvePool curvePool;
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
            params.curvePool.depositToken,
            params.curvePool.LPToken,
            params.assetConverter,
            params.convexPoolId,
            params.name,
            params.symbol
        )
    {
        require(
            params.curvePool.poolAddress != address(0),
            "Zero address provided"
        );

        curvePool = params.curvePool;

        curvePool.LPToken.safeIncreaseAllowance(
            curvePool.poolAddress,
            type(uint256).max
        );
        curvePool.depositToken.safeIncreaseAllowance(curvePool.poolAddress, type(uint256).max);
    }

    function _addLiquidity(uint256 assets)
        internal
        override
        returns (uint256 lpAmount)
    {
        return curvePool.addLiquidity(assets);
    }

    function _removeLiquidity(uint256 lpAmount)
        internal
        override
        returns (uint256 assets)
    {
        return curvePool.removeLiquidity(lpAmount);
    }

    function _getVirtualPrice() internal override view returns(uint256) {
        return curvePool.getVirtualPrice();
    }
}