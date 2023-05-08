/**
 *Submitted for verification on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// A library for performing arithmetic operations with overflow and underflow protection.
library SafeMath {
    
    // Adds two unsigned integers with overflow protection.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        // If the result is smaller than one of the operands, overflow occurred.
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    // Subtracts two unsigned integers with underflow protection.
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // If the second operand is greater than the first, underflow occurred.
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    // Multiplies two unsigned integers with overflow protection.
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // If either operand is zero, the result is zero.
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        // If the result divided by the first operand is not equal to the second operand, overflow occurred.
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    // Divides two unsigned integers with zero division protection.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // If the second operand is zero, division by zero occurred.
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}