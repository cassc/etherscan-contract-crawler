pragma solidity 0.8.15;

import "IERC20Metadata.sol";

interface ICurvePoolView {
    function calc_withdraw_one_coin(uint256 token_amount, int128 index)
        external
        view
        returns (uint256);

    function get_virtual_price() external view returns (uint256);
}

interface ICurvePoolRemoveReturns {
    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 index,
        uint256 min_amount
    ) external returns (uint256);
}

interface ICurvePoolRemoveNotReturns {
    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 index,
        uint256 min_amount
    ) external;
}

interface ICurvePoolCalc2Assets {
    function calc_token_amount(uint256[2] memory amounts, bool is_deposit)
        external
        view
        returns (uint256);
}

interface ICurvePoolAdd2AssetsReturns {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);
}

interface ICurvePoolAdd2AssetsNotReturns {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external;
}

interface ICurvePoolCalc3Assets {
    function calc_token_amount(uint256[3] memory amounts, bool is_deposit)
        external
        view
        returns (uint256);
}

interface ICurvePoolAdd3AssetsReturns {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);
}

interface ICurvePoolAdd3AssetsNotReturns {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external;
}

interface ICurvePoolCalc4Assets is ICurvePoolView {
    function calc_token_amount(uint256[4] memory amounts, bool is_deposit)
        external
        view
        returns (uint256);
}

interface ICurvePoolAdd4AssetsReturns {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);
}

interface ICurvePoolAdd4AssetsNotReturns {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount)
        external;
}

library CurveLibrary {
    struct CurvePool {
        address poolAddress;
        IERC20Metadata LPToken;
        IERC20Metadata depositToken;
        uint256 assetsCount;
        uint128 assetIndex;
        bool returnsLPAmount;
    }

    function getVirtualPrice(CurvePool storage pool) internal view returns(uint256) {
        return ICurvePoolView(pool.poolAddress).get_virtual_price();
    }

    function addLiquidity(CurvePool storage pool, uint256 amount)
        internal
        returns (uint256 lpAmount)
    {
        if (pool.assetsCount == 2) {
            uint256[2] memory amounts;
            amounts[pool.assetIndex] = amount;
            if (pool.returnsLPAmount) {
                lpAmount = ICurvePoolAdd2AssetsReturns(pool.poolAddress).add_liquidity(
                    amounts,
                    0
                );
            } else {
                uint256 previousBalanace = pool.LPToken.balanceOf(address(this));
                ICurvePoolAdd2AssetsNotReturns(pool.poolAddress).add_liquidity(
                    amounts,
                    0
                );
                lpAmount = pool.LPToken.balanceOf(address(this)) - previousBalanace;
            }
        } else if (pool.assetsCount == 3) {
            uint256[3] memory amounts;
            amounts[pool.assetIndex] = amount;
            if (pool.returnsLPAmount) {
                lpAmount = ICurvePoolAdd3AssetsReturns(pool.poolAddress).add_liquidity(
                    amounts,
                    0
                );
            } else {
                uint256 previousBalanace = pool.LPToken.balanceOf(address(this));
                ICurvePoolAdd3AssetsNotReturns(pool.poolAddress).add_liquidity(
                    amounts,
                    0
                );
                lpAmount = pool.LPToken.balanceOf(address(this)) - previousBalanace;
            }
        } else if (pool.assetsCount == 4) {
            uint256[4] memory amounts;
            amounts[pool.assetIndex] = amount;
            if (pool.returnsLPAmount) {
                lpAmount = ICurvePoolAdd4AssetsReturns(pool.poolAddress).add_liquidity(
                    amounts,
                    0
                );
            } else {
                uint256 previousBalanace = pool.LPToken.balanceOf(address(this));
                ICurvePoolAdd4AssetsNotReturns(pool.poolAddress).add_liquidity(
                    amounts,
                    0
                );
                lpAmount = pool.LPToken.balanceOf(address(this)) - previousBalanace;
            }
        }
    }

    function calcTokenAmount(
        CurvePool storage pool,
        uint256 amount,
        bool isDeposit
    ) internal view returns (uint256 lpAmount) {
        if (pool.assetsCount == 2) {
            uint256[2] memory amounts;
            amounts[pool.assetIndex] = amount;
            lpAmount = ICurvePoolCalc2Assets(pool.poolAddress).calc_token_amount(
                amounts,
                isDeposit
            );
        } else if (pool.assetsCount == 3) {
            uint256[3] memory amounts;
            amounts[pool.assetIndex] = amount;
            lpAmount = ICurvePoolCalc3Assets(pool.poolAddress).calc_token_amount(
                amounts,
                isDeposit
            );
        } else if (pool.assetsCount == 4) {
            uint256[4] memory amounts;
            amounts[pool.assetIndex] = amount;
            lpAmount = ICurvePoolCalc4Assets(pool.poolAddress).calc_token_amount(
                amounts,
                isDeposit
            );
        }
    }

    function calcWithdrawOneCoin(CurvePool storage pool, uint256 lpAmount)
        internal
        view
        returns (uint256 amount)
    {
        amount = ICurvePoolView(pool.poolAddress).calc_withdraw_one_coin(
            lpAmount,
            int128(pool.assetIndex)
        );
    }

    function removeLiquidity(CurvePool storage pool, uint256 lpAmount)
        internal
        returns (uint256 amount)
    {
        if (pool.returnsLPAmount) {
            amount = ICurvePoolRemoveReturns(pool.poolAddress).remove_liquidity_one_coin(
                lpAmount,
                int128(pool.assetIndex),
                1
            );
        }
        else {
            uint256 previousBalanace = pool.depositToken.balanceOf(address(this));
            ICurvePoolRemoveNotReturns(pool.poolAddress).remove_liquidity_one_coin(
                lpAmount,
                int128(pool.assetIndex),
                1
            );
            amount = previousBalanace - pool.depositToken.balanceOf(address(this));
        }
    }
}