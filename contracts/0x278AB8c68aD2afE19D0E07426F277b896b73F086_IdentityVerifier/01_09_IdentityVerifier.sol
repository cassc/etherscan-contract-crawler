// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

interface IIdentityVerifier is IERC165 {

    /**
     *  @dev Verify that the buyer can purchase/bid
     *
     *  @param listingId      The listingId associated with this verification
     *  @param identity       The identity to verify
     *  @param tokenAddress   The tokenAddress associated with this verification
     *  @param tokenId        The tokenId associated with this verification
     *  @param requestCount   The number of items being requested to purchase/bid
     *  @param requestAmount  The amount being requested
     *  @param requestERC20   The erc20 token address of the amount (0x0 if ETH)
     *  @param data           Additional data needed to verify
     *
     */
    function verify(uint40 listingId, address identity, address tokenAddress, uint256 tokenId, uint24 requestCount, uint256 requestAmount, address requestERC20, bytes calldata data) external returns (bool);
}

contract IdentityVerifier is AdminControl, IIdentityVerifier {

    // Maps listing ID to merkle root
    mapping(uint => bytes32) _merkleRoots;

    // Maps how many mints a person has used for this listing
    // { listingId => { minterAddress => numberOfMints } }
    mapping(uint => mapping(address => uint)) _alreadyMintedPerPerson;

    address _marketplace;

    function setMerkleRoot(uint listingId, bytes32 merkleRoot) public adminRequired {
      _merkleRoots[listingId] = merkleRoot;
    }

    function setMarketplace(address marketplace) public adminRequired {
        _marketplace = marketplace;
    }

    /**
     * Checks if person and their specific mint index is on the allowlist. Assume merkle tree rows are like this,
     *
     * 0xabcd,0
     * 0xabcd,1
     * 0xefgh,0
     * 0xijkl,0
     * 0xijkl,1
     * 0xijkl,2
     *
     * They must mint 1 at a time. So - will find out how many they have already and assume that is the index.
     */
    function onAllowList(address claimer, bytes32[] memory proof, uint listingId) private returns(bool) {
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

    function setAllowList(uint listingId, bytes32 merkleRoot) public adminRequired {
        _merkleRoots[listingId] = merkleRoot;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IIdentityVerifier).interfaceId || super.supportsInterface(interfaceId);
    }

    function verify(uint40 listingId, address identity, address, uint256, uint24 requestCount, uint256, address, bytes calldata data) external override returns (bool) {
        require(msg.sender == _marketplace, "Can only be verified by the marketplace");
        require(requestCount == 1, "Can only buy one at a time");
        bytes32[] memory proof = abi.decode(data, (bytes32[]));
        if (onAllowList(identity, proof, listingId)) return true;
        return false;
    }

    function verifyView(uint40 listingId, address identity, address, uint256, uint24 requestCount, uint256, address, bytes calldata data) external view returns (bool) {
        require(requestCount == 1, "Can only buy one at a time");
        bytes32[] memory proof = abi.decode(data, (bytes32[]));
        return onAllowListView(identity, proof, listingId);
    }
}