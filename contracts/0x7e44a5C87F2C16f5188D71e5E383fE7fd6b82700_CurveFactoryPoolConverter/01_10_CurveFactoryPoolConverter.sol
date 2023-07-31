pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ICurveFactoryPool} from "contracts/interfaces/ext/curve/ICurveFactoryPool.sol";
import {ICurvePool} from "contracts/interfaces/ext/curve/ICurvePool.sol";
import {IConverter} from "contracts/interfaces/IConverter.sol";

contract CurveFactoryPoolConverter is IConverter {
    using SafeERC20 for IERC20;

    ICurveFactoryPool public pool;

    mapping(address => int128) public indices; // int128 is 0 by default. It is need check in swap, what token is correct?

    constructor(ICurveFactoryPool curvePool, ICurvePool basePool, uint256 basePoolCoinsLength) {
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

    function swap(address source, address destination, uint256 value, address beneficiary) external returns (uint256) {
        int128 i = indices[source];
        int128 j = indices[destination];
        return pool.exchange_underlying(i, j, value, 0, beneficiary);
    }

    function previewSwap(address source, address destination, uint256 value) external view returns (uint256) {
        int128 i = indices[source];
        int128 j = indices[destination];
        return pool.get_dy_underlying(i, j, value);
    }
}