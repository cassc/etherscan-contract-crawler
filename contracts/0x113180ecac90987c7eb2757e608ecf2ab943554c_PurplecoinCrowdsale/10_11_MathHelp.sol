pragma solidity ^0.4.24;

contract MathHelp {
    function getPercentAmount(uint amount, uint percentage, uint precision) public
    constant returns (uint totalAmount){
        return ((amount * (percentage * power(10, precision +1)) / (1000 * power(10, precision))));
    }

    function power(uint256 A, uint256 B) public
    constant returns (uint result){
        return A ** B;
    }

}