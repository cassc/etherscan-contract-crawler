/**
 *Submitted for verification at BscScan.com on 2023-03-15
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0>=0.4.16 <0.9.0;

contract simplestorage { 
    uint storedData ;

    function set( uint x ) public {
        storedData=x;   }

        function get() public  view returns(uint) {
            return storedData;
        }





}