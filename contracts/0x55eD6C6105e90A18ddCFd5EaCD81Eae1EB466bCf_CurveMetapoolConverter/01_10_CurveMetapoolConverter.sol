pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ICurvePoolMinimal} from "contracts/interfaces/ext/curve/ICurvePoolMinimal.sol";
import {ICurveMetapoolMinimal} from "contracts/interfaces/ext/curve/ICurveMetapoolMinimal.sol";
import {IConverter} from "contracts/interfaces/IConverter.sol";

contract CurveMetapoolConverter is IConverter {
    using SafeERC20 for IERC20;

    ICurveMetapoolMinimal public pool;

    mapping(address => int128) public indices; // int128 is 0 by default. It is need check in swap, what token is correct?

    constructor(ICurveMetapoolMinimal curvePool, ICurvePoolMinimal basePool, uint256 basePoolCoinsLength) {
        pool = curvePool;
        address token = pool.coins(0);
        indices[token] = 0;
        IERC20(token).safeIncreaseAllowance(address(curvePool), type(uint256).max);
        for (uint256 i = 0; i < basePoolCoinsLength; i++) {
            token = basePool.coins(i);
            IERC20(token).safeIncreaseAllowance(address(curvePool), type(uint256).max);
            indices[token] = int128(int256(i + 1));
        }
    }

    function swap(address source, address destination, uint256 value, address beneficiary)
        external
        returns (uint256 amountOut)
    {
        int128 i = indices[source];
        int128 j = indices[destination];
        pool.exchange_underlying(i, j, value, 0);
        amountOut = IERC20(destination).balanceOf(address(this));
        IERC20(destination).safeTransfer(beneficiary, amountOut);
    }

    function previewSwap(address source, address destination, uint256 value) external view returns (uint256) {
        int128 i = indices[source];
        int128 j = indices[destination];
        return pool.get_dy_underlying(i, j, value);
    }
}