// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Base.sol";

/*
For solidity, if you don't add modifier payable, compiler will add a piece of assembly code to make sure the
transaction or internal transaction get 0 value and will prevent use msg.value.

For named-function(which means all function except the sysSaveSlotData function), solidity generate perfect code.

However, if a proxy forward a
*/
contract Delegate is Base {
    constructor () {

    }

    /*
    THE FOLLOWING IS FIRST WRITTEN IN 0.3.X AND LAST UPDATED IN 0.4.X
    AND NOW IT IS OUT OF DATE IN 0.8.X
    */
    //Note that nonpayable is a term opposite to payable in solidity and solc
    //nonPayable with big letter P is a modifier in this framework
    //delegateCall will keep msg.sender and msg.value
    //function sig : 44409a82e623ed8da60bc4cd88253f204a87ae1a7e8937c1a0f9ec92fa753c71
    //function(), the fallback function, doesn't allow args and returns, and is nonpayable
    //but you can access calldata and set returndata by assembly by yourself :)
    //without modifier 'payable', you can't refer msg.value in public and external.that's a compiler protection;
    //but you can use msg.value freely in internal function
    //or you can access msg.value by assembly by yourself too :)
    //because defaultFallback is only called by function(), which is fallback, so it is payable.
    //thus if you wan't reject receiving ETH, just add nonPayable
    function defaultFallback() /*nonPayable*/ virtual internal {
        returnAsm(false, notFoundMark);
    }

    receive() payable external {
        //target function doesn't hit normal functions
        defaultFallback();
    }

    fallback() payable external {
        //target function doesn't hit normal functions
        defaultFallback();
    }

    /*function() payable external {
        //target function doesn't hit normal functions
        //check if it's sig is 0x00000000 to call sysSaveSlotData
        if (msg.sig == bytes4(0x00000000)) {
            defaultFallback();
        } else {
            //if goes here, the target function must not be found;
            returnAsm(false, notFoundMark);
        }
    }*/
}