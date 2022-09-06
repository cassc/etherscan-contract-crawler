// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ILazyDelivery is IERC165 {
    function deliver(uint40 listingId, address to, uint256 assetId, uint24 payableCount, uint256 payableAmount, address payableERC20, uint256 index) external returns(uint256);
}

interface ILazyDeliveryMetadata is IERC165 {
    function assetURI(uint256 assetId) external view returns(string memory);
}

interface IIdentityVerifier is IERC165 {
    function verify(uint40 listingId, address identity, address tokenAddress, uint256 tokenId, uint24 requestCount, uint256 requestAmount, address requestERC20, bytes calldata data) external returns (bool);
}

// ⚡️
contract PowerInterns is AdminControl, IIdentityVerifier, ICreatorExtensionTokenURI, ILazyDelivery, ILazyDeliveryMetadata {
    using Strings for uint256;

    address private _creator;
    string private _baseURI;
    string private _assetURI;

    address _marketplace;
    uint _listingId;

    bytes32 _merkleRoot;
    mapping(address => bool) _alreadyMinted;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IIdentityVerifier).interfaceId || interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(ILazyDelivery).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function configure(address marketplace, uint listingId, bytes32 merkleRoot) public adminRequired {
        _marketplace = marketplace;
        _listingId = listingId;
        _merkleRoot = merkleRoot;
    }

    function onAllowList(address claimer, bytes32[] memory proof) private returns(bool) {
        require(!_alreadyMinted[claimer], "Already minted");
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        bool verified = MerkleProof.verify(proof, _merkleRoot, leaf);
        _alreadyMinted[claimer] = true;
        return verified;
    }

    function onAllowListView(address claimer, bytes32[] memory proof) private view returns(bool) {
        require(!_alreadyMinted[claimer], "Already minted");
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }

    /**
     * During AL period, deliver is only called by marketplace if it passes the verify function
     */
    function deliver(uint40 listingId, address to, uint256, uint24 payableCount, uint256, address, uint256) external override returns(uint256) {
        require(msg.sender == _marketplace && listingId == _listingId, "Invalid call data");
        for (uint i; i < payableCount; i++) {
            IERC721CreatorCore(_creator).mintExtension(to);
        }
        return 0;
    }

    function setURIs(string memory baseURI, string memory newAssetURI) public adminRequired {
      _baseURI = baseURI;
      _assetURI = newAssetURI;
    }

    function assetURI(uint256) external view override returns(string memory) {
        return _assetURI;
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    function verify(uint40, address identity, address, uint256, uint24 requestCount, uint256, address, bytes calldata data) external override returns (bool) {
        require(msg.sender == _marketplace, "Can only be verified by the marketplace");
        require(requestCount == 1, "Can only buy one at a time");
        bytes32[] memory proof = abi.decode(data, (bytes32[]));
        if (onAllowList(identity, proof)) return true;
        return false;
    }

    function verifyView(uint40, address identity, address, uint256, uint24 requestCount, uint256, address, bytes calldata data) external view returns (bool) {
        require(requestCount == 1, "Can only buy one at a time");
        bytes32[] memory proof = abi.decode(data, (bytes32[]));
        return onAllowListView(identity, proof);
    }
}