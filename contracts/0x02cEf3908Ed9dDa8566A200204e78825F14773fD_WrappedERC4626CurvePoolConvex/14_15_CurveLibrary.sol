pragma solidity 0.8.15;

import "IERC20Metadata.sol";

interface ICurvePoolView {
    function get_virtual_price() external view returns (uint256);
}

interface ICurvePoolRemove {
    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 index,
        uint256 min_amount
    ) external;
}

interface ICurvePoolRemoveUseUnderlying {
    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 index,
        uint256 min_amount,
        bool _use_underlying
    ) external;
}

interface ICurvePoolAdd2Assets {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;
}

interface ICurvePoolAdd2AssetsUseUnderlying {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount, bool _use_underlying)
        external;
}

interface ICurvePoolAdd3Assets {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;
}

interface ICurvePoolAdd3AssetsUseUnderlying {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount, bool _use_underlying)
        external;
}

interface ICurvePoolAdd4Assets {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external;
}

interface ICurvePoolAdd4AssetsUseUnderlying {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount, bool _use_underlying)
        external;
}

library CurveLibrary {
    struct CurvePool {
        address poolAddress;
        IERC20Metadata LPToken;
        IERC20Metadata depositToken;
        uint256 assetsCount;
        uint128 assetIndex;
        bool useUnderlying;
    }

    function getVirtualPrice(CurvePool storage pool) internal view returns(uint256) {
        return ICurvePoolView(pool.poolAddress).get_virtual_price();
    }

    function addLiquidity(CurvePool storage pool, uint256 amount)
        internal
        returns (uint256 lpAmount)
    {
        uint256 previousBalanace = pool.LPToken.balanceOf(address(this));
        if (pool.assetsCount == 2) {
            uint256[2] memory amounts;
            amounts[pool.assetIndex] = amount;
            if (pool.useUnderlying) {
                ICurvePoolAdd2AssetsUseUnderlying(pool.poolAddress).add_liquidity(
                    amounts,
                    0,
                    true
                );
            } else {
                ICurvePoolAdd2Assets(pool.poolAddress).add_liquidity(
                    amounts,
                    0
                );
            }
        } else if (pool.assetsCount == 3) {
            uint256[3] memory amounts;
            amounts[pool.assetIndex] = amount;
            if (pool.useUnderlying) {
                ICurvePoolAdd3AssetsUseUnderlying(pool.poolAddress).add_liquidity(
                    amounts,
                    0,
                    true
                );
            } else {
                ICurvePoolAdd3Assets(pool.poolAddress).add_liquidity(
                    amounts,
                    0
                );
            }
        } else if (pool.assetsCount == 4) {
            uint256[4] memory amounts;
            amounts[pool.assetIndex] = amount;
            if (pool.useUnderlying) {
                ICurvePoolAdd4AssetsUseUnderlying(pool.poolAddress).add_liquidity(
                    amounts,
                    0,
                    true
                );
            } else {
                ICurvePoolAdd4Assets(pool.poolAddress).add_liquidity(
                    amounts,
                    0
                );
            }
        }
        lpAmount = pool.LPToken.balanceOf(address(this)) - previousBalanace;
    }

    function removeLiquidity(CurvePool storage pool, uint256 lpAmount)
        internal
        returns (uint256 amount)
    {
        uint256 previousBalanace = pool.depositToken.balanceOf(address(this));
        if (pool.useUnderlying) {
            ICurvePoolRemoveUseUnderlying(pool.poolAddress).remove_liquidity_one_coin(
                lpAmount,
                int128(pool.assetIndex),
                1,
                true
            );
        } else {
            ICurvePoolRemove(pool.poolAddress).remove_liquidity_one_coin(
                lpAmount,
                int128(pool.assetIndex),
                1
            );
        }
        amount = pool.depositToken.balanceOf(address(this)) - previousBalanace;
    }
}