// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";

/**
 * @title Grails II Mint Pass
 * @author PROOF
 */
contract Grails2MintPass is ERC721ACommon, BaseTokenURI {
    // =========================================================================
    //                           Events
    // =========================================================================

    /**
     * @notice Emitted after airdropping a batch of mint passes in {airdrop}.
     */
    event BatchAirdropped(uint256 indexed batchId, uint256 total);

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if an airdrop would exceed the theoretical maximum of
     * passes.
     */
    error AirdropExceedsMaxSupply();

    /**
     * @notice Thrown if the expected number of airdropped tokens doesn't match
     * the actual one.
     */
    error WrongAirdropChecksum();

    /**
     * @notice Thrown if an airdrop batch is performed twice.
     */
    error AirdropBatchAlreadyPerformed();

    /**
     * @notice Thrown for unauthorized method calls that are reserved for the
     * Grails II contract.
     */
    error OnlyGrailsContract();

    // =========================================================================
    //                           Types
    // =========================================================================

    /**
     * @notice Struct encoding an airdrop: Receiver + number of passes.
     */
    struct Airdrop {
        address to;
        uint64 num;
    }

    // =========================================================================
    //                           CONSTANTS
    // =========================================================================

    /**
     * @notice The theoretical maximum number of passes.
     * - PROOF (1000)
     * - Grail Moonbirds (176)
     * @dev Artist and treasury allocations are minted directly from the Grails
     * contract.
     */
    uint256 public constant NUM_MAX_PASSES = 1176;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The Grails II contract address.
     */
    address public grails;

    /**
     * @notice Keeps track which batch of airdrops was already performed.
     * @dev Even though it is not really necessary to track this on-chain, we do
     * it anyways to prevent any possible mistakes.
     */
    mapping(uint256 => bool) internal _wasAirdropBatchPerformed;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI_,
        address payable royaltyReceiver
    )
        ERC721ACommon(name, symbol, royaltyReceiver, 500)
        BaseTokenURI(baseTokenURI_)
    {} // solhint-disable-line no-empty-blocks

    // =========================================================================
    //                           Minting
    // =========================================================================

    /**
     * @notice Performs a list of airdrops.
     * @param airdrops List of receivers and numbers of tokens.
     * @param batchId The id of the current batch for internal bookkeeping to
     * prevent mistakes.
     */
    function airdrop(
        Airdrop[] calldata airdrops,
        uint256 expectedTotal,
        uint256 batchId
    ) external onlyOwner {
        if (_wasAirdropBatchPerformed[batchId])
            revert AirdropBatchAlreadyPerformed();
        _wasAirdropBatchPerformed[batchId] = true;

        uint256 total;
        for (uint256 idx = 0; idx < airdrops.length; ++idx) {
            _mint(airdrops[idx].to, airdrops[idx].num);
            total += airdrops[idx].num;
        }

        if (_totalMinted() > NUM_MAX_PASSES) revert AirdropExceedsMaxSupply();
        if (total != expectedTotal) revert WrongAirdropChecksum();

        emit BatchAirdropped(batchId, total);
    }

    /**
     * @notice Interface to burn leftover passes that have not been redeemed.
     * @dev We did not put an explicit lock on this method (preventing us from
     * burning passes at any time) because we are disincentiviced to do so (by
     * missing revenue). Since the mint passes are ephemeral to begin with, we
     * opted to not add the additional complexity for this collection.
     */
    function burnRemaining(uint256[] calldata tokenIds) external onlyOwner {
        for (uint256 idx = 0; idx < tokenIds.length; ++idx) {
            _burn(tokenIds[idx]);
        }
    }

    /**
     * @notice Redeems a pass with given tokenId for a Grail.
     * @dev Only callable by the Grails II contract. Burns the pass.
     */
    function redeem(uint256 tokenId) external onlyGrailsContract {
        _burn(tokenId);
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Sets the Grails II contract address.
     */
    function setGrailsContract(address grails_) external onlyOwner {
        grails = grails_;
    }

    /**
     * @notice Modifier to make a method exclusively callable by the Grails II
     * contract.
     */
    modifier onlyGrailsContract() {
        if (msg.sender != grails) revert OnlyGrailsContract();
        _;
    }

    // =========================================================================
    //                           Metadata
    // =========================================================================

    /**
     * @notice The URI for pass metadata.
     * @dev Returns the same tokenURI for all passes.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return _baseURI();
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, BaseTokenURI)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }
}