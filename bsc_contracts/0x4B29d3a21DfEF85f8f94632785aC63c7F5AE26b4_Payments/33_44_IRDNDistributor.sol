// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


interface IRDNDistributor {
    
    function distribute(address _initAddress, uint _amount) external;

    function getToken() external view returns(address);
}