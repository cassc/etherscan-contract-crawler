// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../Constants.sol";
import "./PoolGetters.sol";
import "../external/UniswapV2Library.sol";
import "../external/IMetaPool.sol";

contract Liquidity is PoolGetters {
    using SafeMath for uint256;

    address private constant UNISWAP_FACTORY =
        address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    function usdcAmountDesired(uint256 dollarAmount) public view returns(uint256){
        (address dollar, address usdc) = (address(dollar()), usdc());
        (uint256 reserveA, uint256 reserveB) = getUNIReserves(dollar, usdc);

        uint256 usdcAmount = (reserveA == 0 && reserveB == 0)
            ? dollarAmount
            : UniswapV2Library.quote(dollarAmount, reserveA, reserveB);

        return usdcAmount;   
    }

    function addLiquidity(uint256 dollarAmount, uint256 usdcDesired, uint256 poolID)
        internal
        returns (uint256, uint256)
    {
        PoolStorage.LPType t = lpType(poolID);
        if (t == PoolStorage.LPType.univ2) {
            return addUNILiquidity(dollarAmount, usdcDesired, poolID);
        } else if (t == PoolStorage.LPType.crv3) {
            return addCRV3Liquidity(dollarAmount, poolID);
        }
        return (0, 0);
    }

    function addUNILiquidity(uint256 dollarAmount, uint256 usdcDesired, uint256 poolID)
        internal
        returns (uint256, uint256)
    {
        (address dollar, address usdc) = (address(dollar()), usdc());
        (uint256 reserveA, uint256 reserveB) = getUNIReserves(dollar, usdc);

        uint256 usdcAmount = (reserveA == 0 && reserveB == 0)
            ? dollarAmount
            : UniswapV2Library.quote(dollarAmount, reserveA, reserveB);

        require(usdcAmount <= usdcDesired, "insufficient usdc amount");

        address pair = address(lpToken(poolID));
        IERC20(dollar).transfer(pair, dollarAmount);
        IERC20(usdc).transferFrom(msg.sender, pair, usdcAmount);
        return (usdcAmount, IUniswapV2Pair(pair).mint(address(this)));
    }

    function addCRV3Liquidity(uint256 dollarAmount, uint256 poolID)
        internal
        returns (uint256, uint256)
    {
        IERC20 crv3Token = lpToken(poolID);
        address lpAddress = address(lpToken(poolID));
        uint256 balanceWas = lpToken(poolID).balanceOf(address(this));

        crv3Token.transferFrom(msg.sender, address(this), dollarAmount);

        if (crv3Token.allowance(address(this), lpAddress) < dollarAmount)
            dollar().approve(lpAddress, 2**256 - 1);

        uint256 crv3Allowed = crv3Token.allowance(address(this), lpAddress);

        if (crv3Allowed > 0 && crv3Allowed < dollarAmount)
            crv3Token.approve(lpAddress, 0);

        if (crv3Allowed == 0 || crv3Allowed < dollarAmount)
            crv3Token.approve(lpAddress, 2**256 - 1);

        IMetaPool(lpAddress).add_liquidity([dollarAmount, dollarAmount], 0);

        return (
            dollarAmount,
            lpToken(poolID).balanceOf(address(this)).sub(balanceWas)
        );
    }

    // overridable for testing
    function getUNIReserves(address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            UniswapV2Library.pairFor(UNISWAP_FACTORY, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }
}