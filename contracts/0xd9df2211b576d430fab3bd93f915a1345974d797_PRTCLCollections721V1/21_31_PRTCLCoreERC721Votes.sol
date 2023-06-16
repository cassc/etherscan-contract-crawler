// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../ERC721MultiCollection.sol";
import "./PRTCLVotes.sol";

/**
 * @dev Extension of ERC721MultiCollection to support voting and delegation as implemented by {PRTCLVotes}, where each individual NFT counts
 * as 1 vote unit within a collection.
 *
 * Tokens do not count as votes until they are delegated, because votes must be tracked which incurs an additional cost
 * on every transfer. Token holders can either delegate to a trusted representative who will decide how to make use of
 * the votes in governance decisions, or they can delegate to themselves to be their own representative.
 *
 * @author Particle Collection - valdi.eth
 */
abstract contract PRTCLCoreERC721Votes is ERC721MultiCollection, PRTCLVotes {
    using ECDSA for bytes32;

    /**
     * @notice Used to validate delegation addresses
     */
    address public delegateSigner;

    /**
     * @dev Emitted when the signer address is updated.
     */
    event SignerUpdated(address signer);

    /**
     * @dev Initializes the contract by setting a `delegateSigner`.
     */
    constructor(address _delegateSigner) {
        delegateSigner = _delegateSigner;
    }

    /**
     * @dev Update signer address.
     */
    function _setDelegationSigner(address _signer) internal {
        require(_signer != address(0), "Must input non-zero address");
        delegateSigner = _signer;

        emit SignerUpdated(_signer);
    }

    /**
     * @dev See {ERC721-_afterTokenTransfer}. Adjusts votes when tokens are transferred.
     *
     * Emits a {IPRTCLVotes-DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        _transferVotingUnits(from, to, batchSize, tokenIdToCollectionId(firstTokenId));
        super._afterTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
     * @dev Returns the balance of `account` for collection `collectionId`.
     * 1 vote per token.
     */
    function _getVotingUnits(address account, uint256 collectionId) internal view virtual override returns (uint256) {
        return balanceOf(account, collectionId);
    }

    /**
     * @dev Override regular delegation to disable it
     */
    function delegate(address /* delegatee */, uint256 /* collectionId */) public virtual override {
        revert("PRTCLCoreERC721Votes: regular delegation disabled. Please use delegation with signature.");
    }

    /**
     * @dev Delegation that only allows whitelisted addresses
     */
    function delegate(address delegatee, uint256 collectionId, bytes memory signature, uint256 expirationBlock) public {
        require(verifyDelegation(signature, expirationBlock, msg.sender, delegatee, collectionId), "PRTCLCoreERC721Votes: invalid signature");
        super.delegate(delegatee, collectionId);
    }

    /**
     * @dev Verify signature for delegation
     */
    function verifyDelegation(bytes memory _signature, uint256 _expirationBlock, address _delegate, address _delegatee, uint256 _collectionId) public 
    view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(_delegate, _delegatee, _collectionId, _expirationBlock));
        return block.number < _expirationBlock && delegateSigner == messageHash.toEthSignedMessageHash().recover(_signature);
    }
}