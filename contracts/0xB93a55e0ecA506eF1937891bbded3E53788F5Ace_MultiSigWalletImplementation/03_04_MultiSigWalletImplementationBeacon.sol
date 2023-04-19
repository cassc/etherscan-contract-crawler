// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MultiSigWalletImplementation.sol";


contract MultiSigWalletImplementationBeacon {

    event MultiSigWalletImplementationDeployed(address indexed implementation);

    constructor() {
        MultiSigWalletImplementation implementation = new MultiSigWalletImplementation();

        address[] memory owners = new address[](1);
        owners[0] = msg.sender;

        implementation.initialize(owners, 1);
        
        emit MultiSigWalletImplementationDeployed(address(implementation));
    }
}