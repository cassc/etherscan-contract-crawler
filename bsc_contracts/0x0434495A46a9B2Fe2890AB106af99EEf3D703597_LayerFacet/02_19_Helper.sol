/*
 SPDX-License-Identifier: MIT
*/
pragma solidity 0.8.17;

import "../ReentrancyGuard.sol";
import "../../libraries/LibDiamond.sol";
import "../../libraries/LibMath.sol";
import "../../interfaces/ITopcornProtocol.sol";
import "../../interfaces/pancake/IPancakePair.sol";
import "../../interfaces/pancake/IPancakeRouter02.sol";
import "../../interfaces/IDLP.sol";
import "../../interfaces/IWBNB.sol";

/// @title The helper contract.
contract Helper is ReentrancyGuard {
    /// @notice Optimal One-sided Supply. (invest only one token (CORN) in liquidity)
    /// @param amountCORN Total amount CORN for invest.
    /// @return countTokens Part of tokens CORN for invest.
    /// @return bnbReserve reserve BNB in pool.
    /// @return cornReserve reserve CORN in pool.
    function getCountTokenFromCorn(uint256 amountCORN)
        public
        view
        returns (
            uint256[] memory countTokens,
            uint256 bnbReserve,
            uint256 cornReserve
        )
    {
        (bnbReserve, cornReserve) = getReserves();
        uint256 cornPerBNB = calculateSwapInAmount(cornReserve, amountCORN);
        (countTokens, ) = getAmounts(s.c.topcorn, s.c.wbnb, cornPerBNB);
    }

    /// @notice Optimal One-sided Supply. (invest only one token (LP) in liquidity)
    /// @param amountBNB Total amount LP for invest.
    /// @return countTokens Part of tokens LP for invest.
    /// @return bnbReserve reserve BNB in pool.
    /// @return cornReserve reserve CORN in pool.
    function getCountTokenFromBNB(uint256 amountBNB)
        public
        view
        returns (
            uint256[] memory countTokens,
            uint256 bnbReserve,
            uint256 cornReserve
        )
    {
        (bnbReserve, cornReserve) = getReserves();
        uint256 bnbPerCorn = calculateSwapInAmount(bnbReserve, amountBNB);
        (countTokens, ) = getAmounts(s.c.wbnb, s.c.topcorn, bnbPerCorn);
    }

    function getAmounts(
        address token0,
        address token1,
        uint256 amount
    ) internal view returns (uint256[] memory countTokens, address[] memory path) {
        path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        countTokens = IPancakeRouter02(s.c.router).getAmountsOut(amount, path);
    }

    function countLP() internal view returns (uint256 lpBegin) {
        lpBegin = IERC20(s.c.pair).balanceOf(s.c.topcornProtocol);
    }

    // (bnb, corn)
    function getReserves() internal view returns (uint256 reserveA, uint256 reserveB) {
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(s.c.pair).getReserves();
        (reserveA, reserveB) = s.c.topcorn == IPancakePair(s.c.pair).token0() ? (reserve1, reserve0) : (reserve0, reserve1);
    }

    function checkLiq(uint256 liquidity, uint256[] calldata amounts) internal view returns (uint256 balance) {
        require(dlp().balanceOf(msg.sender) >= liquidity, "Insufficient DLP balance");
        balance = calcBalance(liquidity, IDLP(s.c.dlp).totalSupply(), s.reserveLP);
        uint256 lpRemoved;
        for (uint256 i; i < amounts.length; i++) lpRemoved = lpRemoved + amounts[i];
        require(balance == lpRemoved, "ReserveLP do not equal RemoveLP");
    }

    // slippage in 0.00-100.00 percent (0-10000)
    function calcSlippage(uint32 slippage, uint256 countToken) internal pure returns (uint256 checkToken) {
        uint32 decimal = 10000; //0.01%
        require(slippage <= decimal, "Slippage must be from 0 to 10000");
        checkToken = (countToken * (decimal - slippage)) / decimal;
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 amountIn) private pure returns (uint256) {
        return (LibMath.sqrt(reserveIn * (amountIn * 399000000 + reserveIn * 399000625)) - (reserveIn * 19975)) / 19950;
    }

    function calculateLpRemove(
        uint256 amountToken0,
        uint256 reserveToken0,
        uint256 amountToken1,
        uint256 reserveToken1
    ) internal view returns (uint256 minLP) {
        uint256 totalSuply = IERC20(s.c.pair).totalSupply();
        if ((amountToken0 * totalSuply) / reserveToken0 < (amountToken1 * totalSuply) / reserveToken1) {
            minLP = (amountToken0 * totalSuply) / reserveToken0;
        } else {
            minLP = (amountToken1 * totalSuply) / reserveToken1;
        }
    }

    function calcDLP(
        uint256 amount,
        uint256 totalSupply,
        uint256 reserve
    ) public pure returns (uint256) {
        if ((totalSupply == 0) || (reserve == 0)) return amount;
        return (amount * totalSupply) / reserve;
    }

    function calcBalance(
        uint256 liq,
        uint256 totalSupply,
        uint256 reserve
    ) public pure returns (uint256) {
        if ((totalSupply == 0) || (reserve == 0)) return 0;
        return (liq * reserve) / totalSupply;
    }

    function dlp() public view returns (IDLP) {
        return IDLP(s.c.dlp);
    }

    function getReservesLP() public view returns (uint256 amounts) {
        return s.reserveLP;
    }

    function getContracts() public view returns (address[] memory amounts) {
        amounts = new address[](7);
        amounts[0] = s.c.topcorn;
        amounts[1] = s.c.pair;
        amounts[2] = s.c.pegPair;
        amounts[3] = s.c.wbnb;
        amounts[4] = s.c.router;
        amounts[5] = s.c.topcornProtocol;
        amounts[6] = s.c.dlp;
    }

    function DLPtoBNB(uint256 liqDLP) public view returns (uint256 amountLP, uint256 amountWBNB) {
        amountLP = calcBalance(liqDLP, IDLP(s.c.dlp).totalSupply(), s.reserveLP);
        (uint256 balanceBnb, uint256 balanceCorn) = getReserves();
        uint256 supplyLP = IERC20(s.c.pair).totalSupply();
        uint256 getCORN = (amountLP * balanceCorn) / supplyLP;
        uint256 getBNB = (amountLP * balanceBnb) / supplyLP;
        (uint256[] memory countTokens, ) = getAmounts(s.c.topcorn, s.c.wbnb, getCORN);
        amountWBNB = getBNB + countTokens[1];
    }

    function DLPtoLP(uint256 liqDLP) public view returns (uint256 amountLP) {
        amountLP = calcBalance(liqDLP, IDLP(s.c.dlp).totalSupply(), s.reserveLP);
    }

    function LPtpDLP(uint256 liqLP) public view returns (uint256 amountDLP) {
        amountDLP = calcDLP(liqLP, IDLP(s.c.dlp).totalSupply(), s.reserveLP);
    }
}