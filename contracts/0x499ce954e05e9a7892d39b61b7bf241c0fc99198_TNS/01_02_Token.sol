//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Interfaces.sol";

contract TNS {
    ENSRegistryWithFallback ens;

    constructor() {
        ens = ENSRegistryWithFallback(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e); 
        // The ens registry address is shared across testnets and mainnet
    }

    // Enter 'uni' to lookup uni.tkn.eth
    function addressFor(string calldata _name) public view returns (address) {
        bytes32 namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('tkn')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
        address resolverAddr = ens.resolver(namehash);
        PublicResolver resolver = PublicResolver(resolverAddr);
        return resolver.addr(namehash);
    }

    struct Metadata {
        address contractAddress;
        string name;
        string url;
        string avatar;
        string description;
        string notice;
        string twitter;
        string github;
        bytes contenthash;
        address payable arb1_address;
        address payable avaxc_address;
        address payable bsc_address;
        address payable cro_address;
        address payable ftm_address;
        address payable gno_address;
        address payable matic_address;
        bytes near_address;
        address payable op_address;
        bytes sol_address;
        bytes trx_address;
        bytes zil_address; 
    }

    function infoFor(string calldata _name) public view returns (Metadata memory) {
        bytes32 namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('tkn')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
        address resolverAddr = ens.resolver(namehash);
        PublicResolver resolver = PublicResolver(resolverAddr);

        return Metadata(
            resolver.addr(namehash),
            resolver.text(namehash, "name"),
            resolver.text(namehash, "url"),
            resolver.text(namehash, "avatar"),
            resolver.text(namehash, "description"),
            resolver.text(namehash, "notice"),
            resolver.text(namehash, "com.twitter"),
            resolver.text(namehash, "com.github"),
            resolver.contenthash(namehash),
            bytesToAddress(resolver.addr(namehash, 2147525809)), // ARB1trum
            bytesToAddress(resolver.addr(namehash, 2147526762)), // AVAXC
            bytesToAddress(resolver.addr(namehash, 2147483704)), // BSC
            bytesToAddress(resolver.addr(namehash, 2147483673)), // CRO
            bytesToAddress(resolver.addr(namehash, 2147483898)), // FTM
            bytesToAddress(resolver.addr(namehash, 2147483748)), // GNO
            bytesToAddress(resolver.addr(namehash, 2147483785)), // MATIC Polygon
            resolver.addr(namehash, 397), // NEAR
            bytesToAddress(resolver.addr(namehash, 2147483658)), // OP
            resolver.addr(namehash, 501), // SOL
            resolver.addr(namehash, 195), // TRX
            resolver.addr(namehash, 119)  // ZIL
        );
    }

    // Get chain ID here: https://github.com/ensdomains/address-encoder
    function getContractForChain(uint256 _chainId, string calldata _name) public view returns (bytes memory) {
        bytes32 namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked('tkn')))
        );
        namehash = keccak256(
            abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
        address resolverAddr = ens.resolver(namehash);
        PublicResolver resolver = PublicResolver(resolverAddr);
        return resolver.addr(namehash, _chainId);
    }
    
    // Calculate the namehash offchain using eth-ens-namehash to save gas costs.
    // Better for write queries that require gas
    // Library: https://npm.runkit.com/eth-ens-namehash
    function gasEfficientFetch(bytes32 namehash) public view returns (address) {
        address resolverAddr = ens.resolver(namehash);
        PublicResolver resolver = PublicResolver(resolverAddr);
        return resolver.addr(namehash);
    }
        
    // Get an account's balance using a ticker symbol
    function balanceWithTicker(address user, string calldata tickerSymbol) public view returns (uint) {
        IERC20 tokenContract = IERC20(addressFor(tickerSymbol));
        return tokenContract.balanceOf(user);
    }

    // Helpers
    function bytesToAddress(bytes memory b)
        internal
        pure
        returns (address payable a)
    {
        if (b.length == 20) {
            assembly {
                a := div(mload(add(b, 32)), exp(256, 12))
            }
        } else {
            return payable(address(0));
        }
    }
}