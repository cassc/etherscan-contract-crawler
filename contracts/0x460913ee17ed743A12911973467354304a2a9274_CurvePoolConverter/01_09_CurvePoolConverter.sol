pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IConverter} from "contracts/interfaces/IConverter.sol";
import {ICurvePoolMinimal} from "contracts/interfaces/ext/curve/ICurvePoolMinimal.sol";

contract CurvePoolConverter is IConverter {
    using SafeERC20 for IERC20;

    ICurvePoolMinimal public pool;

    mapping(address => int128) public indices; // int128 is 0 by default. It is need check in swap, what token is correct?

    constructor(ICurvePoolMinimal curvePool, uint256 coinsLength) {
        pool = curvePool;
        for (uint256 i = 0; i < coinsLength; i++) {
            address token = pool.coins(i);
            IERC20(token).safeIncreaseAllowance(address(pool), type(uint256).max);
            indices[token] = int128(int256(i));
        }
    }

    function swap(address source, address destination, uint256 value, address beneficiary)
        external
        returns (uint256 amountOut)
    {
        int128 i = indices[source];
        int128 j = indices[destination];
        pool.exchange(i, j, value, 0);
        amountOut = IERC20(destination).balanceOf(address(this));
        IERC20(destination).safeTransfer(beneficiary, amountOut);
    }

    function previewSwap(address source, address destination, uint256 value) external view returns (uint256) {
        int128 i = indices[source];
        int128 j = indices[destination];
        return pool.get_dy(i, j, value);
    }
}