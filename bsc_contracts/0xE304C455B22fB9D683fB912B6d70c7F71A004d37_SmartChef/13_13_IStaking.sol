// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
}