// SPDX-License-Identifier: MIT
// Based on ENS's offchain resolver implementation
pragma solidity ^0.8.4;

import "./ENSConnector.sol";
import "./SignatureVerifier.sol";
import "../common/PublicResolver.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddressResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddrResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IABIResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/ITextResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IPubkeyResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IContentHashResolver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IExtendedResolver {
    function resolve(bytes memory name, bytes memory data) external view returns (bytes memory);
}

contract ENSProxyResolver is Ownable, Multicallable, IAddrResolver, IAddressResolver, IABIResolver, ITextResolver,
IPubkeyResolver, IContentHashResolver, IExtendedResolver {

    ENSConnector ensConnector;
    ENSRegistry registry;

    // Offchain gateway for names that aren't linked on chain
    string public url;

    mapping(address => bool) public signers;

    event NewSigners(address[] signers);

    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    // Mapping of on-chain nodes e.g. bob.forever.id => bob.forever
    mapping(bytes32 => bytes32) public linkedNodes;

    event NewLinkedNode(bytes32 indexed node, bytes32 indexed linkedNode);

    constructor(ENSConnector _ensConnector, ENSRegistry _registry, string memory _url, address[] memory _signers) {
        ensConnector = _ensConnector;
        registry = _registry;

        url = _url;
        _setSigners(_signers);
    }

    function setSigners(address[] memory _signers) external onlyOwner {
        _setSigners(_signers);
    }

    function _setSigners(address[] memory _signers) internal {
        for (uint i = 0; i < _signers.length; i++) {
            signers[_signers[i]] = true;
        }
        emit NewSigners(_signers);
    }

    function setUrl(string memory _url) external onlyOwner {
        url = _url;
    }

    // Creates the node on-chain makes it possible to set a reverse record on ENS registry
    function link(bytes32 bridge, bytes32 label) external {
        bytes32 node = ensConnector.bridges(bridge);
        require(node != 0, "ENSResolver: No bridge registered for this node");

        bytes32 linked = keccak256(abi.encodePacked(node, label));
        bytes32 ensSubnode = keccak256(abi.encodePacked(bridge, label));
        address owner = registry.owner(linked);

        linkedNodes[ensSubnode] = linked;
        ensConnector.setSubnodeRecord(bridge, label, owner, address(this), 0);
        emit NewLinkedNode(ensSubnode, linked);
    }

    function addr(bytes32 node) external view override returns (address payable) {
        (bytes32 linked, address resolver) = _resolver(node);
        if (resolver == address(0)) {
            return payable(address(0));
        }

        return IAddrResolver(resolver).addr(linked);
    }

    function addr(bytes32 node, uint coinType) external view override returns (bytes memory) {
        (bytes32 linked, address resolver) = _resolver(node);
        if (resolver == address(0)) {
            return bytes("");
        }

        return IAddressResolver(resolver).addr(linked, coinType);
    }

    function ABI(bytes32 node, uint256 contentTypes) external view override returns (uint256, bytes memory) {
        (bytes32 linked, address resolver) = _resolver(node);
        if (resolver == address(0)) {
            return (0, bytes(""));
        }

        return IABIResolver(resolver).ABI(linked, contentTypes);
    }

    function text(bytes32 node, string calldata key) external view override returns (string memory) {
        (bytes32 linked, address resolver) = _resolver(node);
        if (resolver == address(0)) {
            return "";
        }

        return ITextResolver(resolver).text(linked, key);
    }

    function pubkey(bytes32 node) external view override returns (bytes32 x, bytes32 y) {
        (bytes32 linked, address resolver) = _resolver(node);
        if (resolver == address(0)) {
            return (0, 0);
        }

        return IPubkeyResolver(resolver).pubkey(linked);
    }

    function contenthash(bytes32 node) external view override returns (bytes memory) {
        (bytes32 linked, address resolver) = _resolver(node);
        if (resolver == address(0)) {
            return bytes("");
        }

        return IContentHashResolver(resolver).contenthash(linked);
    }

    function _resolver(bytes32 node) internal view returns (bytes32, address) {
        bytes32 linked = linkedNodes[node];
        if (linked == bytes32(0)) {
            return (bytes32(0), address(0));
        }

        return (linked, registry.resolver(linked));
    }

    function makeSignatureHash(uint64 expires, bytes memory request, bytes memory result) external view returns (bytes32) {
        return SignatureVerifier.makeSignatureHash(address(this), expires, request, result);
    }

    function resolve(bytes calldata name, bytes calldata data) external view override returns (bytes memory) {
        string[] memory urls = new string[](1);
        urls[0] = url;

        revert OffchainLookup(
            address(this),
            urls,
            msg.data,
            this.resolveWithProof.selector,
            msg.data
        );
    }

    function resolveWithProof(bytes calldata response, bytes calldata extraData) external view returns (bytes memory) {
        (address signer, bytes memory result) = SignatureVerifier.verify(extraData, response);
        require(
            signers[signer],
            "ENSProxyResolver: Invalid signature");
        return result;
    }

    function supportsInterface(bytes4 interfaceID) public pure override(Multicallable) returns (bool) {
        return interfaceID == type(IExtendedResolver).interfaceId ||
        interfaceID == type(IAddrResolver).interfaceId ||
        interfaceID == type(IAddressResolver).interfaceId ||
        interfaceID == type(IABIResolver).interfaceId ||
        interfaceID == type(ITextResolver).interfaceId ||
        interfaceID == type(IPubkeyResolver).interfaceId ||
        interfaceID == type(IContentHashResolver).interfaceId ||
        super.supportsInterface(interfaceID);
    }
}