/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

pragma solidity >=0.8.0 <0.9.0;

contract A {
    function Q()public pure{
        revert("abc");
    }
}

contract TEST{

    A a;
    constructor(){
        a = new A();
    }

    event ee(string reason);

    function dd()public{

        try a.Q(){}
        catch Error(string memory revertReason) {
            emit ee(revertReason);
        } 
    }

}