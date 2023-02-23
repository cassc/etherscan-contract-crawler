pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

interface iDistributor {

    function payMyCurrentShare() external;

    function registerReceivedValue() external;

    function setReceiverAccount(uint8 _portionId, address payable _account) external;

    function getPortionsCount() external view returns(uint);
    
    function changeOwner(address payable _owner) external;

    function getOwner() external view returns(address);

}