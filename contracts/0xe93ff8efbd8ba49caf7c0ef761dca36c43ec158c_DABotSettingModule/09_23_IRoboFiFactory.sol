// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRoboFiFactory {
    function deploy(address masterContract, 
                    bytes calldata data, 
                    bool useCreate2) 
        external 
        payable 
        returns(address);
}