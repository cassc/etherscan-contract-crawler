// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12; 

import "./NameHash.sol";
import '@ensdomains/ens-contracts/contracts/registry/ENS.sol';
import '@ensdomains/ens-contracts/contracts/registry/ReverseRegistrar.sol';
import '@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol';

contract ReverseLookup {
    ENS _ens;
    ReverseRegistrar _reverseRegister;

    /**
     * The `constructor` takes ENS registry address
     */
    constructor(ENS ens, ReverseRegistrar reverseRegister) {
        _ens = ens;
        _reverseRegister = reverseRegister;
    }

    /**
     * Read only function to return ens name only if both forward and reverse resolution are set     *
     */
    function getNames(address[] calldata addresses) external view returns (string[] memory r) {
        r = new string[](addresses.length);
        for(uint i = 0; i < addresses.length; i++) {
            bytes32 node = _reverseRegister.node(addresses[i]);
            address resolverAddress = _ens.resolver(node);
            if(resolverAddress != address(0x0)){
                Resolver resolver = Resolver(resolverAddress);
                string memory name = resolver.name(node);
                if(bytes(name).length == 0 ){
                    continue;
                }
                bytes32 namehash = Namehash.namehash(name);
                address forwardResolverAddress = _ens.resolver(namehash);
                if(forwardResolverAddress != address(0x0)){
                    Resolver forwardResolver = Resolver(forwardResolverAddress);
                    address forwardAddress = forwardResolver.addr(namehash);
                    if(forwardAddress == addresses[i]){
                        r[i] = name;
                    }
                }
            }
        }
        return r;
    } 
}