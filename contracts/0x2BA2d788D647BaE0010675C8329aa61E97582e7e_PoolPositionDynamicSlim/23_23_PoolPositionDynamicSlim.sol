// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IPool} from "@maverickprotocol/maverick-v1-interfaces/contracts/interfaces/IPool.sol";

import {PoolPositionBaseSlim} from "./PoolPositionBaseSlim.sol";

contract PoolPositionDynamicSlim is PoolPositionBaseSlim {
    using SafeERC20 for IERC20;

    constructor(IPool _pool, uint128[] memory _binIds, uint128[] memory _ratios, uint256 factoryCount) PoolPositionBaseSlim(_pool, _binIds, _ratios, factoryCount, false) {}

    function addLiquidityCallback(uint256 amountA, uint256 amountB, bytes calldata) external {
        // no permission needed as this contract does not hold assets unless we
        // are migrating liquidity

        if (amountA != 0) {
            tokenA.safeTransfer(address(pool), amountA);
        }
        if (amountB != 0) {
            tokenB.safeTransfer(address(pool), amountB);
        }
    }

    function migrateBinLiquidity() external override nonReentrant {
        if (isStatic) return;

        uint128 currentBinId = binIds[0];
        IPool.BinState memory bin = pool.getBin(currentBinId);
        if (bin.mergeId == 0) return;

        /////////////////////
        // our bin has merged; need to move our liquidity to the new active bin
        /////////////////////
        // migrate first
        pool.migrateBinUpStack(binIds[0], 0);
        bin = pool.getBin(currentBinId);

        uint128 newBinId = bin.mergeId;

        // remove liquidity
        IPool.RemoveLiquidityParams[] memory params = new IPool.RemoveLiquidityParams[](1);
        params[0].binId = currentBinId;
        params[0].amount = type(uint128).max;

        (uint256 tokenAAmount, uint256 tokenBAmount, ) = pool.removeLiquidity(address(this), tokenId, params);

        if (tokenAAmount != 0 || tokenBAmount != 0) {
            IPool.BinState memory activeBin = pool.getBin(newBinId);

            // if there was anything to remove; add it back to new active bin
            IPool.AddLiquidityParams[] memory addParams = new IPool.AddLiquidityParams[](1);
            addParams[0] = IPool.AddLiquidityParams({
                kind: activeBin.kind,
                pos: activeBin.lowerTick,
                isDelta: false,
                deltaA: tokenAAmount == 0 ? 0 : SafeCast.toUint128(tokenAAmount),
                deltaB: tokenBAmount == 0 ? 0 : SafeCast.toUint128(tokenBAmount)
            });
            bytes memory empty;
            pool.addLiquidity(tokenId, addParams, empty);
        }

        emit MigrateBinLiquidity(currentBinId, newBinId);
        // binId changed; update it for contract
        binIds[0] = newBinId;
    }
}