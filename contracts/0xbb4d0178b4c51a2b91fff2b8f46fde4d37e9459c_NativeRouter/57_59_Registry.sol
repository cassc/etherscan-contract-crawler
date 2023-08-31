// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPricer.sol";
import "./interfaces/INativeTreasury.sol";

contract Registry is Ownable {
    mapping(uint256 => address) public pricer;

    // constructor
    constructor(address[] memory pricers) Ownable() {
        for (uint256 i = 0; i < pricers.length; ) {
            pricer[i] = pricers[i];
            unchecked {
                i++;
            }
        }
    }

    // public methods
    function registerPricer(uint256 id, address addr) public onlyOwner {
        require(pricer[id] == address(0), "pricer already set for this id");
        pricer[id] = addr;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 fee,
        uint256 id,
        address treasury,
        address tokenIn,
        address tokenOut,
        bool isTreasuryContract
    ) public view returns (uint amountOut) {
        require(amountIn > 0, "Non-zero amount required");

        uint reserveIn;
        uint reserveOut;
        if (isTreasuryContract) {
            (uint reserve0, uint reserve1) = INativeTreasury(treasury).getReserves();
            if (tokenIn == INativeTreasury(treasury).token0()) {
                reserveIn = reserve0;
                reserveOut = reserve1;
            } else {
                reserveIn = reserve1;
                reserveOut = reserve0;
            }
        } else {
            reserveIn = IERC20(tokenIn).balanceOf(address(treasury));
            reserveOut = IERC20(tokenOut).balanceOf(address(treasury));
        }
        amountOut = _getAmountOut(amountIn, reserveIn, reserveOut, fee, id);
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 fee,
        uint256 id
    ) internal view returns (uint amountOut) {
        require(reserveIn > 0 && reserveOut > 0, "Registry: INSUFFICIENT_LIQUIDITY");

        amountOut = IPricer(pricer[id]).getAmountOut(amountIn, reserveIn, reserveOut, fee);
    }
}