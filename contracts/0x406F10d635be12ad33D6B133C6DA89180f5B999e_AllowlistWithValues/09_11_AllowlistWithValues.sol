// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./IIdentityVerifier.sol";
import "./IIdentityVerifierCheck.sol";

contract AllowlistWithValues is AdminControl, IIdentityVerifier, IIdentityVerifierCheck {

    // Maps listing ID to merkle root
    mapping(uint256 => bytes32) private _merkleRoots;

    // Maps how many mints a person has used for this listing
    // { listingId => { minterAddress => numberOfMints } }
    mapping(uint256 => mapping(address => uint256)) private _alreadyMintedPerPerson;

    address public immutable MARKETPLACE;

    constructor (address marketplace) AdminControl() {
        MARKETPLACE = marketplace;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IIdentityVerifier).interfaceId || interfaceId == type(IIdentityVerifierCheck).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * Checks if person and their specific mint index is on the allowlist. Assume merkle tree rows were generated with data,
     * as follows:
     *
     * {0xaddress},{index}
     *
     * e.g.
     * 0xabcd,0
     * 0xabcd,1
     * 0xefgh,0
     * 0xijkl,0
     * 0xijkl,1
     * 0xijkl,2
     *
     * The merkle leaves are the rows without the comma separator.
     *
     * A claimer must mint 1 at a time. Only one can be minted at a time and the indices are to be consumed sequentially.
     * We expect the caller to predetermine the next available index by calling checkVerify.
     */
    function onAllowList(address claimer, bytes32[] memory proof, uint256 listingId) private returns(bool) {
        // Find out how many they have
        uint howManyAlready = _alreadyMintedPerPerson[listingId][claimer];
        // Encode how many they have minted with their address, resulting in - 0xabcd,0
        bytes32 leaf = keccak256(abi.encodePacked(claimer, howManyAlready));
        // Check that this entry is in the tree
        bool verified = MerkleProof.verify(proof, _merkleRoots[listingId], leaf);

        // If verified, mark this as minted (used)
        if (verified) {
            _alreadyMintedPerPerson[listingId][claimer]++;
        }

        return verified;
    }

    // Checks if someone is on the allow-list for given proof they provide.
    // Will not modify the state (not to be used in real minting, as this would allow double-minting for a given index)
    function onAllowListView(address claimer, bytes32[] memory proof, uint listingId) private view returns(bool) {
        // Find out how many they have
        uint howManyAlready = _alreadyMintedPerPerson[listingId][claimer];
        // Encode how many they have minted with their address, resulting in - 0xabcd,0
        bytes32 leaf = keccak256(abi.encodePacked(claimer, howManyAlready));
        // Check that this entry is in the tree
        return MerkleProof.verify(proof, _merkleRoots[listingId], leaf);
    }

    function setAllowList(uint40 listingId, bytes32 merkleRoot) public adminRequired {
        _merkleRoots[listingId] = merkleRoot;
    }

    function verify(uint40 listingId, address identity, address, uint256, uint24 requestCount, uint256, address, bytes calldata data) external override returns (bool) {
        require(msg.sender == MARKETPLACE, "Can only be verified by the marketplace");
        require(requestCount == 1, "Can only buy one at a time");
        bytes32[] memory proof = abi.decode(data, (bytes32[]));
        if (onAllowList(identity, proof, listingId)) return true;
        return false;
    }

    function checkVerify(address marketplaceAddress, uint40 listingId, address identity, address, uint256, uint24 requestCount, uint256, address, bytes calldata data) external view returns (bool) {
      require(marketplaceAddress == MARKETPLACE, "Can only be verified by the marketplace");
      require(requestCount == 1, "Can only buy one at a time");
      bytes32[] memory proof = abi.decode(data, (bytes32[]));
      return onAllowListView(identity, proof, listingId);
    }

}