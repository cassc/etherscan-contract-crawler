// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";

library GasChecker {
    function GasCost(string memory name, 
        function() internal returns (bool) fun)
        internal returns (string memory)
    {
        uint u0 = gasleft();
        bool sm = fun();
        uint u1 = gasleft();
        uint diff = u0 - u1;
        return string(abi.encodePacked(name, " GasCost: ", Strings.toString(diff), " return(", sm, ")"));
    }

    function fun1() internal pure returns (bool){
        return true;
    }

    function fun2() internal pure returns (bool){
        return true;
    }

    function fun3() internal pure returns (bool){
        return true;
    }

    function CreateReport() public returns (string memory s) {
        s = string(abi.encodePacked(s, GasCost("fun1",fun1)));
        s = string(abi.encodePacked(s, GasCost("fun2",fun2)));
        s = string(abi.encodePacked(s, GasCost("fun3",fun3)));
    }
}