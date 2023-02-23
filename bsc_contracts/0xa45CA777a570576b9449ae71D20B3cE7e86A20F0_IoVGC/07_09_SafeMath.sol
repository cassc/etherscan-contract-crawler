pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow error.");
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "Subtraction overflow error.");
        uint256 c = a - b;
        return c;
    }

    function inc(uint a) internal pure returns(uint) {
        return(add(a, 1));
    }

    function dec(uint a) internal pure returns(uint) {
        return(sub(a, 1));
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        require(b != 0,"Divide by zero.");
        return(a/b);
    }

    function mod(uint a, uint b) internal pure returns(uint) {
        require(b != 0,"Divide by zero.");
        return(a % b);
    }

    function min(uint a, uint b) internal pure returns (uint) {
        if (a > b)
            return(b);
        return(a);
    }

    function max(uint a, uint b) internal pure returns (uint) {
        if (a < b)
            return(b);
        return(a);
    }

    function addPercent(uint a, uint p, uint r) internal pure returns(uint) {
        return(div(mul(a,add(r,p)),r));
    }
}
