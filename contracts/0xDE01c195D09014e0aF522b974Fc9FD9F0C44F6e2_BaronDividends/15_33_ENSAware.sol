// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// ENS is deployed here in most chains (Mainnet, Ropsten, Rinkeby and Goerli)
// See https://docs.ens.domains/ens-deployments
address constant ENS_ADDRESS = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

// This is the hash of "addr.reverse" used to identify the registrar.
bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/contracts/registry/IReverseRegistrar.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";

// This allows an owner to control the reverse ENS address for the contract.
// It also exposes helpers for contracts to resolve ENS names.
// NOTE: implementations must invoke _claimReverseENS
abstract contract ENSAware {
    ENS private _ens = ENS(ENS_ADDRESS);

    // visible for testing
    function _setENS(address ens) internal {
        _ens = ENS(ens);
    }

    function _claimReverseENS(address owner) internal virtual {
        IReverseRegistrar rr = IReverseRegistrar(_ens.owner(ADDR_REVERSE_NODE));
        rr.claim(owner);
    }

    function _resolveAddr(bytes32 node) internal virtual view returns (address) {
        Resolver resolver = Resolver(_ens.resolver(node));
        return resolver.addr(node);
    }
}