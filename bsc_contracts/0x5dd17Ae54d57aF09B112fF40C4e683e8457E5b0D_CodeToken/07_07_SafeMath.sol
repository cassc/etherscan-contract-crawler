// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


library SafeMath {

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "Sao");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "Sso");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;
        return c;
    }

    // function mul(uint a, uint b) internal pure returns (uint) {
    //     if (a == 0) {
    //         return 0;
    //     }
    //     uint c = a * b;
    //     require(c / a == b, "SafeMath: multiplication overflow");

    //     return c;
    // }
    // function div(uint a, uint b) internal pure returns (uint) {
    //     return div(a, b, "SafeMath: division by zero");
    // }
    // function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
    //     // Solidity only automatically asserts when dividing by 0
    //     require(b > 0, errorMessage);
    //     uint c = a / b;

    //     return c;
    // }
}