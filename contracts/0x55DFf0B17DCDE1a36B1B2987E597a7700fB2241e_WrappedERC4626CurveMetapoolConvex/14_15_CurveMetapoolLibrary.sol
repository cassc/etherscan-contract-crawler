pragma solidity 0.8.15;

import "IERC20Metadata.sol";

interface ICurvePool {
    function get_virtual_price() external view returns (uint256);
}

interface ICurveMetapoolFactoryZap {
    function calc_withdraw_one_coin(
        address pool,
        uint256 token_amount,
        int128 index
    ) external view returns (uint256);

    function remove_liquidity_one_coin(
        address pool,
        uint256 token_amount,
        int128 index,
        uint256 min_amount
    ) external returns (uint256);
}

interface ICurveMetapoolZap {
    function calc_withdraw_one_coin(
        uint256 token_amount,
        int128 index
    ) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 index,
        uint256 min_amount
    ) external returns (uint256);
}

interface ICurveMetapoolFactoryZap3Assets {
    function calc_token_amount(
        address pool,
        uint256[3] memory amounts,
        bool is_deposit
    ) external view returns (uint256);

    function add_liquidity(
        address pool,
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

interface ICurveMetapoolZap3Assets {
    function calc_token_amount(
        uint256[3] memory amounts,
        bool is_deposit
    ) external view returns (uint256);

    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

interface ICurveMetapoolFactoryZap4Assets {
    function calc_token_amount(
        address pool,
        uint256[4] memory amounts,
        bool is_deposit
    ) external view returns (uint256);

    function add_liquidity(
        address pool,
        uint256[4] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

interface ICurveMetapoolZap4Assets {
    function calc_token_amount(
        uint256[4] memory amounts,
        bool is_deposit
    ) external view returns (uint256);

    function add_liquidity(
        uint256[4] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

interface ICurveMetapoolFactoryZap5Assets {
    function calc_token_amount(
        address pool,
        uint256[5] memory amounts,
        bool is_deposit
    ) external view returns (uint256);

    function add_liquidity(
        address pool,
        uint256[5] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

interface ICurveMetapoolZap5Assets {
    function calc_token_amount(
        uint256[5] memory amounts,
        bool is_deposit
    ) external view returns (uint256);

    function add_liquidity(
        uint256[5] memory amounts,
        uint256 min_mint_amount
    ) external returns (uint256);
}

library CurveMetapoolLibrary {
    struct CurveMetapool {
        address zapAddress;
        address poolAddress;
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

    function calcTokenAmount(
        CurveMetapool storage pool,
        uint256 amount,
        bool isDeposit
    ) internal view returns (uint256 lpAmount) {
        if (pool.assetsCount == 3) {
            uint256[3] memory amounts;
            amounts[pool.assetIndex] = amount;
            if (pool.isFactoryZap) {
                lpAmount = ICurveMetapoolFactoryZap3Assets(pool.zapAddress)
                    .calc_token_amount(pool.poolAddress, amounts, isDeposit);
            } else {
                lpAmount = ICurveMetapoolZap3Assets(pool.zapAddress)
                    .calc_token_amount(amounts, isDeposit);
            }
        } else if (pool.assetsCount == 4) {
            uint256[4] memory amounts;
            amounts[pool.assetIndex] = amount;
            if (pool.isFactoryZap) {
                lpAmount = ICurveMetapoolFactoryZap4Assets(pool.zapAddress)
                    .calc_token_amount(pool.poolAddress, amounts, isDeposit);
            } else {
                lpAmount = ICurveMetapoolZap4Assets(pool.zapAddress)
                    .calc_token_amount(amounts, isDeposit);
            }
        } else if (pool.assetsCount == 5) {
            uint256[5] memory amounts;
            amounts[pool.assetIndex] = amount;
            if (pool.isFactoryZap) {
                lpAmount = ICurveMetapoolFactoryZap5Assets(pool.zapAddress)
                    .calc_token_amount(pool.poolAddress, amounts, isDeposit);
            } else {
                lpAmount = ICurveMetapoolZap5Assets(pool.zapAddress)
                    .calc_token_amount(amounts, isDeposit);
            }
        }
    }

    function calcWithdrawOneCoin(CurveMetapool storage pool, uint256 lpAmount)
        internal
        view
        returns (uint256 amount)
    {
        if (pool.isFactoryZap) {
            amount = ICurveMetapoolFactoryZap(pool.zapAddress).calc_withdraw_one_coin(
                pool.poolAddress,
                lpAmount,
                int128(pool.assetIndex)
            );
        } else {
            amount = ICurveMetapoolZap(pool.zapAddress).calc_withdraw_one_coin(
                lpAmount,
                int128(pool.assetIndex)
            );
        }
    }

    function removeLiquidity(CurveMetapool storage pool, uint256 lpAmount)
        internal
        returns (uint256 amount)
    {
        if (pool.isFactoryZap) {
            amount = ICurveMetapoolFactoryZap(pool.zapAddress).remove_liquidity_one_coin(
                pool.poolAddress,
                lpAmount,
                int128(pool.assetIndex),
                1
            );
        } else {
            amount = ICurveMetapoolZap(pool.zapAddress).remove_liquidity_one_coin(
                lpAmount,
                int128(pool.assetIndex),
                1
            );
        }
    }
}