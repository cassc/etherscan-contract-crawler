pragma solidity 0.8.15;

import "IERC20Metadata.sol";


interface ICurvePool {
    function get_virtual_price() external view returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns(uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
}

interface ICurveMetapoolFactoryZap {
    function remove_liquidity_one_coin(
        address pool,
        uint256 token_amount,
        int128 index,
        uint256 min_amount
    ) external returns (uint256);
}

interface ICurveMetapoolZap {
    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 index,
        uint256 min_amount
    ) external returns (uint256);
}

interface ICurveMetapoolFactoryZap3Assets {
    function add_liquidity(
        address pool,
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

interface ICurveMetapoolZap3Assets {
    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

interface ICurveMetapoolFactoryZap4Assets {
    function add_liquidity(
        address pool,
        uint256[4] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

interface ICurveMetapoolZap4Assets {
    function add_liquidity(
        uint256[4] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

interface ICurveMetapoolFactoryZap5Assets {
    function add_liquidity(
        address pool,
        uint256[5] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

interface ICurveMetapoolZap5Assets {
    function add_liquidity(
        uint256[5] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

library CurveMetapoolLibrary {
    struct CurveMetapool {
        address zapAddress;
        address poolAddress;
        IERC20Metadata LPToken;
        IERC20Metadata depositToken;
        uint256 assetsCount;
        uint128 assetIndex;
        bool isFactoryZap;
    }

    function getVirtualPrice(CurveMetapool storage pool)
        internal
        view
        returns (uint256)
    {
        return ICurvePool(pool.poolAddress).get_virtual_price();
    }

    function addLiquidity(CurveMetapool storage pool, uint256 amount)
        internal
        returns (uint256 lpAmount)
    {
        if (pool.assetsCount == 3) {
            uint256[3] memory amounts;
            amounts[pool.assetIndex] = amount;
            if (pool.isFactoryZap) {
                lpAmount = ICurveMetapoolFactoryZap3Assets(pool.zapAddress).add_liquidity(
                    pool.poolAddress,
                    amounts,
                    0
                );
            } else {
                lpAmount = ICurveMetapoolZap3Assets(pool.zapAddress).add_liquidity(
                    amounts,
                    0
                );
            }
        } else if (pool.assetsCount == 4) {
            uint256[4] memory amounts;
            amounts[pool.assetIndex] = amount;
            if (pool.isFactoryZap) {
                lpAmount = ICurveMetapoolFactoryZap4Assets(pool.zapAddress).add_liquidity(
                    pool.poolAddress,
                    amounts,
                    0
                );
            } else {
                lpAmount = ICurveMetapoolZap4Assets(pool.zapAddress).add_liquidity(
                    amounts,
                    0
                );
            }
        } else if (pool.assetsCount == 5) {
            uint256[5] memory amounts;
            amounts[pool.assetIndex] = amount;
            if (pool.isFactoryZap) {
                lpAmount = ICurveMetapoolFactoryZap5Assets(pool.zapAddress).add_liquidity(
                    pool.poolAddress,
                    amounts,
                    0
                );
            } else {
                lpAmount = ICurveMetapoolZap5Assets(pool.zapAddress).add_liquidity(
                    amounts,
                    0
                );
            }
        }
    }

    function removeLiquidity(CurveMetapool storage pool, uint256 lpAmount)
        internal
        returns (uint256 amount)
    {
        if (ICurvePool(pool.poolAddress).calc_withdraw_one_coin(lpAmount, 1) == 0) {
            ICurvePool(pool.poolAddress).remove_liquidity_one_coin(lpAmount, 1, 0);
            return 0;
        }
        if (pool.isFactoryZap) {
            amount = ICurveMetapoolFactoryZap(pool.zapAddress).remove_liquidity_one_coin(
                pool.poolAddress,
                lpAmount,
                int128(pool.assetIndex),
                0
            );
        } else {
            amount = ICurveMetapoolZap(pool.zapAddress).remove_liquidity_one_coin(
                lpAmount,
                int128(pool.assetIndex),
                0
            );
        }
    }
}