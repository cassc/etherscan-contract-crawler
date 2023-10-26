// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract PriceFormula {

    function getSumFixedPoint(uint256 x, uint256 y, uint256 A) public pure returns(uint) {
        if(x == 0 && y == 0) return 0;

        uint256 sum = x + y;

        for(uint256 i = 0 ; i < 255 ; i++) {
            uint256 dP = sum;
            dP = dP * sum / ((x * 2) + 1);
            dP = dP * sum / ((y * 2) + 1);

            uint256 prevSum = sum;

            uint256 n = (A * 2 * (x + y) + (dP * 2)) * sum;
            uint256 d = (A * 2 - 1) * sum;
            sum = n / (d + dP * 3);

            if(sum <= prevSum + 1 && prevSum <= sum + 1) break;
        }

        return sum;
    }

    function getReturn(uint256 xQty, uint256 xBalance, uint256 yBalance, uint256 A) public pure returns(uint256) {
        uint256 sum = getSumFixedPoint(xBalance, yBalance, A);

        uint256 c = sum * sum / ((xQty + xBalance) * 2);
        c = c * sum / (A * 4);
        uint256 b = (xQty + xBalance) + (sum / (A * 2));
        uint256 yPrev = 0;
        uint256 y = sum;

        for(uint256 i = 0 ; i < 255 ; i++) {
            yPrev = y;
            uint256 n = y * y + c;
            uint256 d = y * 2 + b - sum; 
            y = n / d;

            if(y <= yPrev + 1 && yPrev <= y + 1) break;
        }

        return yBalance - y - 1;
    }
}