// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


interface ISubscriptionManager   {

    
    function checkUserSubscription(
        address _userer, 
        uint256 _serviceCode
    ) external view returns (bool);

    function checkAndFixUserSubscription(
        address _userer, 
        uint256 _serviceCode
    ) external returns (bool); 

    function fixUserSubscription(
        address _user, 
        uint256 _tariffIndex
    ) external;
}