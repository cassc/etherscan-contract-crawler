// SPDX-License-Identifier: MIT

import "@ens/registry/IReverseRegistrar.sol";

pragma solidity ^0.8.16;

abstract contract PrimaryEns {

    IReverseRegistrar immutable public REVERSE_REGISTRAR;

    address private deployer ;

    constructor(){
        deployer = msg.sender;
        REVERSE_REGISTRAR = IReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);
    }

    /*
     * @description Set the primary name of the contract
     * @param _ens The ENS that is set to the contract address. Must be full name
     * including the .eth. Can also be a subdomain.
     */
    function setPrimaryName(string calldata _ens) public {
        require(msg.sender == deployer, "only deployer");
        REVERSE_REGISTRAR.setName(_ens);
    }
}