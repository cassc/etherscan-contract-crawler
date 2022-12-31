// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**          

      `7MM"""Mq.                     mm           
        MM   `MM.                    MM           
        MM   ,M9  ,pW"Wq.   ,pW"Wq.mmMMmm ,pP"Ybd 
        MMmmdM9  6W'   `Wb 6W'   `Wb MM   8I   `" 
        MM  YM.  8M     M8 8M     M8 MM   `YMMMa. 
        MM   `Mb.YA.   ,A9 YA.   ,A9 MM   L.   I8 
      .JMML. .JMM.`Ybmd9'   `Ybmd9'  `MbmoM9mmmP' 

      E D I T I O N S
                
      https://roots.samking.photo/editions

*/

import "./Constants.sol";
import {SKS721} from "./SKS721.sol";
import {IRootsEditions} from "./IRootsEditions.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";

/**
 * @author Sam King (samkingstudio.eth)
 * @title  Roots Editions
 * @notice Numbered edition ERC721 NFTs as an extension of Roots by Sam King
 */
contract RootsEditions is IRootsEditions, SKS721 {
    struct ArtworkData {
        uint8 editionSize;
        uint128 price;
        uint32 starts;
        uint8 presaleAmount;
        uint8 soldPresale;
        uint8 sold;
        bool artistProofMinted;
    }

    /// @dev A mapping of original artwork ids to artwork data
    mapping(uint256 => ArtworkData) internal _artworks;

    /// @notice A mapping of original artwork ids to merkle roots for presale groups
    mapping(uint256 => bytes32) public presaleRoots;

    /// @dev A mapping of address => artwork id => presale collected
    mapping(address => mapping(uint256 => bool)) internal _presaleCollected;

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    error ArtistProofAlreadyMinted();
    error ArtistProofNotMinted();
    error CannotSetZeroStartTime();
    error CannotUsePresaleWithoutRoot();

    error ArtworkDoesNotExist();

    error SaleAlreadyStarted();
    error PresaleAmountExceedsEditionSize();

    error PresaleNotRequired();
    error PresaleInvalidProof();
    error PresaleNotStarted();
    error PresaleConcluded();
    error PresaleSoldOut();
    error PresaleAlreadyCollected();

    error IncorrectPrice();
    error ArtworkSoldOut();
    error ArtworkNotForSale();
    error ArtworkNoEditionsCurrentlyAvailable();
    error ArtworkAlreadyCollected();
    error NoMoreEditionsToRelease();

    error UnsoldTimelockNotElapsed();

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    /**
     * @notice When a new artist proof has been minted
     * @param id The artwork id
     */
    event ArtistProofMint(uint256 indexed id);

    /**
     * @notice When a new edition has been released and minted to the artist
     * @param id The artwork id
     * @param price The price to collect an edition
     * @param starts When the artwork can be collected
     */
    event EditionMint(uint256 indexed id, uint256 indexed price, uint256 indexed starts);

    /**
     * @notice When a presale amount is updated for an artwork
     * @param id The artwork id
     * @param amount The new presale amount
     */
    event PresaleAmountSet(uint256 indexed id, uint256 indexed amount);

    /**
     * @notice When a presale merkle root is updated for an artwork
     * @param id The artwork id
     * @param root The merkle root
     */
    event PresaleRootSet(uint256 indexed id, bytes32 indexed root);

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(address owner, address metadata)
        SKS721(owner, "Roots Editions", "ROOTED", metadata)
    {}

    /* ------------------------------------------------------------------------
       M I N T   R E L E A S E
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Mints an artist proof for an edition to the artist
     *
     * @dev
     * The full edition can only be minted once the artist proof has been minted. Reverts if
     * the artist proof has already been minted before the full edition has been minted.
     */
    function mintArtistProof() external onlyOwner {
        ArtworkData memory artwork = _artworks[nextId];

        // Revert if the proof has already been minted
        if (artwork.artistProofMinted) revert ArtistProofAlreadyMinted();

        // Set the initial artwork data
        artwork.editionSize = uint8(EDITION_SIZE);
        artwork.artistProofMinted = true;
        _artworks[nextId] = artwork;

        // Mint the proof to the artist
        _mint(artist, _getRealTokenId(nextId, 0));
        emit ArtistProofMint(nextId);
    }

    /**
     * @notice
     * Mints the next release to the artist with a price, start time, and presale options
     *
     * @dev
     * Emits multiple `Transfer` events and doesn't update ownership in storage to save gas.
     * If there are leftover tokens after the sale period, the artist can take actual ownership of
     * the remaining tokens.
     *
     * Reverts if:
     *  - the artist proof for the release has not been minted
     *  - the start time is set to zero since that determines if artwork data exists
     *  - a presale amount is set, but no presale root is provided
     *
     * @param price The sale price for the next release
     * @param starts The start time of the sale period
     * @param presaleAmount The number of editions that require a proof to collect
     * @param presaleRoot The merkle root for the next release
     */
    function mintEdition(
        uint128 price,
        uint32 starts,
        uint8 presaleAmount,
        bytes32 presaleRoot
    ) external onlyOwner {
        ArtworkData memory artwork = _artworks[nextId];

        // Can only mint the edition when the artist proof has been minted
        if (!artwork.artistProofMinted) revert ArtistProofNotMinted();

        // Must specify a start time
        if (starts == 0) revert CannotSetZeroStartTime();

        // Can only create with a presale if a presale merkle root is provided
        if (presaleAmount > 0 && presaleRoot == bytes32(0)) revert CannotUsePresaleWithoutRoot();

        // Save the presale root if provided
        if (presaleRoot != bytes32(0)) {
            presaleRoots[nextId] = presaleRoot;
            emit PresaleRootSet(nextId, presaleRoot);
        }

        // Emit an event if there's a presale allocation
        if (presaleAmount > 0) {
            artwork.presaleAmount = presaleAmount;
            emit PresaleAmountSet(nextId, presaleAmount);
        }

        // Save the artwork data
        artwork.price = price;
        artwork.starts = starts;
        _artworks[nextId] = artwork;

        /**
         * Transfer from the artist to `to`
         *
         * Safety:
         *   1. the edition size is small and will likely never overflow for this project.
         */
        unchecked {
            _balanceOf[artist] += EDITION_SIZE;
        }
        for (uint256 i = 0; i < EDITION_SIZE; i++) {
            emit Transfer(address(0), artist, _getRealTokenId(nextId, i + 1));
        }

        // Emit that the edition was minted
        emit EditionMint(nextId, price, starts);

        /**
         * Increment the counter ready for the next artwork
         *
         * Safety:
         *   1. the next edition id will never overflow
         */
        unchecked {
            ++nextId;
        }
    }

    /** INTERNAL ----------------------------------------------------------- */

    /**
     * @notice
     * Internal function to transfer the next edition from the artist to `to`
     *
     * @param id The artwork id
     * @param to The account to transfer the edition to
     * @param artwork The artwork sale data
     */
    function _transferFromArtist(
        uint256 id,
        address to,
        ArtworkData memory artwork
    ) internal {
        uint256 realId = _getRealTokenId(id, artwork.soldPresale + artwork.sold);
        if (_ownerOf[realId] != address(0)) revert ArtworkAlreadyCollected();

        /**
         * Transfer from the artist to `to`
         *
         * Safety:
         *   1. Artist balance is always above 1 given a transfer can only happen once a
         *      pre-mint has happened.
         *   2. Unlikely that `to` balance will ever overflow for this project.
         */
        unchecked {
            _balanceOf[artist]--;
            _balanceOf[to]++;
        }
        _ownerOf[realId] = to;

        emit Transfer(artist, to, realId);
    }

    /** ADMIN -------------------------------------------------------------- */

    /**
     * @notice
     * Admin function to set the number of editions that are reserved for presale
     *
     * @dev
     * Reverts if:
     *  - the artwork does not exist
     *  - the presale amount exceeds the standard edition size
     *  - the sale has already started.
     *
     * @param id The artwork id
     * @param presaleAmount The number of editions reserved for presale
     */
    function setPresaleAmountForEdition(uint256 id, uint8 presaleAmount) external onlyOwner {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        if (presaleAmount > EDITION_SIZE) revert PresaleAmountExceedsEditionSize();
        if (block.timestamp > artwork.starts) revert SaleAlreadyStarted();

        // Set the number of editions to reserve
        _artworks[id].presaleAmount = presaleAmount;
        emit PresaleAmountSet(id, presaleAmount);
    }

    /**
     * @notice
     * Admin function to set a merkle root for a particular artwork
     *
     * @dev
     * Reverts if:
     * - the artwork does not exist
     * - the presale amount is greater than zero, and the root is empty
     *
     * @param id The artwork id
     * @param presaleRoot The new merkle root
     */
    function setPresaleRootForEdition(uint256 id, bytes32 presaleRoot) external onlyOwner {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        if (artwork.presaleAmount > 0 && presaleRoot == bytes32(0)) {
            revert CannotUsePresaleWithoutRoot();
        }

        // Set the new merkle root
        presaleRoots[id] = presaleRoot;
        emit PresaleRootSet(id, presaleRoot);
    }

    /**
     * @notice
     * Admin function to remove any presale requirements for a particular artwork
     *
     * @dev
     * Reverts if:
     * - the artwork does not exist
     *
     * @param id The artwork id
     */
    function removePresaleRequirementForEdition(uint256 id) external onlyOwner {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();

        artwork.presaleAmount = 0;
        _artworks[id] = artwork;

        presaleRoots[id] = bytes32(0);

        emit PresaleAmountSet(id, 0);
        emit PresaleRootSet(id, bytes32(0));
    }

    /** GETTERS ------------------------------------------------------------ */

    /**
     * @notice
     * Checks if the artist proof for an edition has been minted
     *
     * @param id The artwork id
     * @return artistProofMinted If the artist proof has been minted
     */
    function getHasArtistProofBeenMinted(uint256 id) external view returns (bool) {
        ArtworkData memory artwork = _artworks[id];
        return artwork.artistProofMinted;
    }

    /**
     * @notice
     * Gets the edition size for a particular artwork
     *
     * @dev
     * Reverts if:
     *  - the artist proof has not been minted
     *
     * @param id The artwork id
     * @return editionMinted If the edition has been minted
     */
    function getHasArtworkEditionBeenMinted(uint256 id) external view returns (bool) {
        ArtworkData memory artwork = _artworks[id];
        if (!artwork.artistProofMinted) revert ArtistProofNotMinted();
        return artwork.starts > 0;
    }

    /**
     * @notice
     * Gets the edition size for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return editionSize The edition size of the artwork
     */
    function getArtworkEditionSize(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return artwork.editionSize;
    }

    /**
     * @notice
     * Gets the number of editions available for presale for a given artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return presaleAmount The number of editions available for presale
     */
    function getArtworkPresaleAmount(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return artwork.presaleAmount;
    }

    /**
     * @notice
     * Gets the sale price for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return price The sale price of the artwork
     */
    function getArtworkSalePrice(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return artwork.price;
    }

    /**
     * @notice
     * Gets the sale start time in seconds for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return starts The sale start time in seconds
     */
    function getArtworkSaleStartTime(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return artwork.starts;
    }

    /**
     * @notice
     * Gets the total number of editions sold for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return editionsSold The number of editions sold
     */
    function getArtworkEditionsSold(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return artwork.soldPresale + artwork.sold;
    }

    /**
     * @notice
     * Gets the number of editions sold in the presale for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return soldInPresale The number of editions sold in the presale
     */
    function getArtworkEditionsSoldInPresale(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return artwork.soldPresale;
    }

    /**
     * @notice
     * Gets the number of editions that are currently collectable
     *
     * @dev
     * Every `EDITION_RELEASE_SCHEDULE` that has elapsed from the start, the available
     * amount increases by one, and each sale decreases the amount by one.
     *
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return editionsSold The number of editions sold
     */
    function getArtworkEditionsCurrentlyAvailable(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return _artworkEditionsAvailable(artwork);
    }

    /**
     * @notice
     * Internal function to get the number of editions currently available to collect
     *
     * @dev
     * Uses the sale period and the amount sold to calculate how many editions can be
     * collected at the current block timestamp.
     *
     * @param artwork The artwork information
     * @return available The current number of editions that are available to collect
     */
    function _artworkEditionsAvailable(ArtworkData memory artwork) internal view returns (uint256) {
        if (block.timestamp < artwork.starts || artwork.starts == 0) return 0;
        uint256 released = _artworkEditionsReleased(artwork);
        uint256 max = (EDITION_SIZE - artwork.soldPresale);
        return (released >= max ? max : released) - artwork.sold;
    }

    /**
     * @notice
     * Gets the next release time of an edition from a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @return nextReleaseTime The next edition release time in seconds
     */
    function getArtworkEditionsNextReleaseTime(uint256 id) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return _artworkEditionsNextReleaseTime(artwork);
    }

    /**
     * @notice
     * Internal function to get the number of editions released since the start
     *
     * @dev
     * Caps the number at `EDITION_SIZE`
     *
     * @param artwork The artwork information
     * @return editionsReleased The number of editions released since the start
     */
    function _artworkEditionsReleased(ArtworkData memory artwork) internal view returns (uint256) {
        if (block.timestamp < artwork.starts) return 0;
        if (block.timestamp < artwork.starts + EDITION_RELEASE_SCHEDULE) return 1;
        uint256 released = ((block.timestamp - artwork.starts) / EDITION_RELEASE_SCHEDULE) + 1;
        return released > EDITION_SIZE ? EDITION_SIZE : released;
    }

    /**
     * @notice
     * Internal function to get the next release time of an edition
     *
     * @param artwork The artwork information
     * @return nextReleaseTime The next edition release time in seconds
     */
    function _artworkEditionsNextReleaseTime(ArtworkData memory artwork)
        internal
        view
        returns (uint256)
    {
        uint256 released = _artworkEditionsReleased(artwork);
        return artwork.starts + (released * EDITION_RELEASE_SCHEDULE);
    }

    /**
     * @notice
     * Gets the real token id for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param id The artwork id
     * @param edition The edition number
     * @return realId The real token id
     */
    function getArtworkRealTokenId(uint256 id, uint256 edition) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return _getRealTokenId(id, edition);
    }

    /**
     * @notice
     * Gets the original artwork id from a real token id for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param realId The real token id
     * @return originalId The original artwork id
     */
    function getArtworkIdFromRealId(uint256 realId) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[_getIdFromRealTokenId(realId)];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return _getIdFromRealTokenId(realId);
    }

    /**
     * @notice
     * Gets the edition number from a real token id for a particular artwork
     *
     * @dev
     * Reverts if the artwork does not exist
     *
     * @param realId The real token id
     * @return edition The edition number
     */
    function getArtworkEditionNumberFromRealId(uint256 realId) external view returns (uint256) {
        ArtworkData memory artwork = _artworks[_getIdFromRealTokenId(realId)];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        return _getEditionFromRealTokenId(realId);
    }

    /**
     * @notice
     * Gets information about a particular artwork
     *
     * @param id The artwork id
     */
    function getArtworkInformation(uint256 id)
        external
        view
        returns (
            bool artistProofMinted,
            uint256 editionSize,
            uint256 price,
            uint256 starts,
            uint256 nextEditionReleaseTime,
            uint256 editionsCurrentlyAvailable,
            uint256 presaleAmount,
            bytes32 presaleRoot,
            uint256 soldPresale,
            uint256 sold,
            bool editionMinted
        )
    {
        ArtworkData memory artwork = _artworks[id];

        artistProofMinted = artwork.artistProofMinted;
        editionSize = artwork.editionSize;
        price = artwork.price;
        starts = artwork.starts;
        nextEditionReleaseTime = _artworkEditionsNextReleaseTime(artwork);
        editionsCurrentlyAvailable = _artworkEditionsAvailable(artwork);
        presaleAmount = artwork.presaleAmount;
        presaleRoot = presaleRoots[id];
        soldPresale = artwork.soldPresale;
        sold = artwork.sold;
        editionMinted = artwork.starts > 0;
    }

    /* ------------------------------------------------------------------------
       P R E S A L E
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Allows a verified account to collect an edition in the presale period
     *
     * @dev
     * Reverts if:
     *  - the artwork does not exist
     *  - there is no presale for the artwork
     *  - the caller has already collected in the presale
     *  - the presale has not started yet
     *  - the presale has concluded
     *  - the presale has sold out
     *  - the price does not match the sale price
     *  - the provided proof is not valid
     *
     * @param id The artwork id
     * @param proof The merkle proof that allows the caller to collect
     */
    function collectInPresale(uint256 id, bytes32[] calldata proof) external payable {
        ArtworkData memory artwork = _artworks[id];

        // Check the presale conditions
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        if (artwork.presaleAmount == 0) revert PresaleNotRequired();
        if (_presaleCollected[msg.sender][id]) revert PresaleAlreadyCollected();
        if (artwork.starts - PRESALE_PERIOD > block.timestamp) revert PresaleNotStarted();
        if (block.timestamp >= artwork.starts) revert PresaleConcluded();
        if (artwork.soldPresale == artwork.presaleAmount) revert PresaleSoldOut();
        if (artwork.price != msg.value) revert IncorrectPrice();
        if (!_verifyProof(id, msg.sender, proof)) revert PresaleInvalidProof();

        /**
         * Increment the sold counter for the presale
         *
         * Safety:
         *   1. We check above that the presale amount does not exceed the allowed amount
         *      so an overflow will not happen.
         */
        unchecked {
            ++artwork.soldPresale;
        }
        _artworks[id] = artwork;

        // Prevent collecting multiple times in the same presale
        _presaleCollected[msg.sender][id] = true;

        // Transfer the artwork from the artist
        _transferFromArtist(id, msg.sender, artwork);
    }

    /**
     * @notice
     * Internal function to verify a merkle proof for a given artwork
     *
     * @param id The artwork id
     * @param account The account to verify the proof for
     * @param proof The merkle proof to verify
     */
    function _verifyProof(
        uint256 id,
        address account,
        bytes32[] calldata proof
    ) internal view returns (bool) {
        return MerkleProof.verify(proof, presaleRoots[id], keccak256(abi.encodePacked(account)));
    }

    /** GETTERS ------------------------------------------------------------ */

    /**
     * @notice
     * Checks if an account can collect an edition in the presale for an artwork
     *
     * @dev
     * Skips proof checks if the artwork does not require it.
     * Reverts if the artwork does not exist.
     *
     * @param id The artwork id
     * @param account The account to check
     * @return allowedToCollect If the account can collect an edition with the provided proof
     */
    function getCanCollectInPresale(
        uint256 id,
        address account,
        bytes32[] calldata proof
    ) external view returns (bool) {
        ArtworkData memory artwork = _artworks[id];
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        if (artwork.presaleAmount == 0) return true;
        return _verifyProof(id, account, proof);
    }

    /* ------------------------------------------------------------------------
       C O L L E C T
    ------------------------------------------------------------------------ */

    /**
     * @notice
     * Collect an edition of the specified id
     *
     * @dev
     * Transfers the artwork from the artist to the msg.sender
     *
     * Reverts if:
     *  - the artwork does not exist
     *  - the sale period has not started yet
     *  - the price does not match the sale price
     *  - the edition is sold out
     *  - the next edition is not purchasable yet
     *
     * @param id The artwork id to collect
     */
    function collect(uint256 id) external payable {
        ArtworkData memory artwork = _artworks[id];

        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        if (artwork.starts > block.timestamp) revert ArtworkNotForSale();
        if (artwork.price != msg.value) revert IncorrectPrice();
        if (artwork.soldPresale + artwork.sold == artwork.editionSize) revert ArtworkSoldOut();
        if (_artworkEditionsAvailable(artwork) == 0) revert ArtworkNoEditionsCurrentlyAvailable();

        /**
         * Increment the sold counter for the presale
         *
         * Safety:
         *   1. We check above that the sold amount does not exceed the allowed amount
         *      so an overflow will not happen.
         */
        unchecked {
            ++artwork.sold;
        }
        _artworks[id] = artwork;

        // Transfer the artwork from the artist
        _transferFromArtist(id, msg.sender, artwork);
    }

    /** ADMIN -------------------------------------------------------------- */

    /**
     * @notice
     * Allows the artist to close the edition once the time lock has elapsed. Any
     * unsold editions are burned, and the edition size is set to the amount sold.
     *
     * @dev
     * Since the `_ownerOf` was never set in storage when pre-minting to the artist, the
     * burning is also done by only emitting transfer events to save gas.
     *
     * Reverts if:
     *  - the artwork does not exist
     *  - the sale period has not started yet
     *  - the time lock has not elapsed
     *  - the edition is sold out
     *
     * @param id The artwork id to take ownership of unsold editions
     */
    function closeEdition(uint256 id) external onlyOwner {
        ArtworkData memory artwork = _artworks[id];
        uint256 totalSold = artwork.soldPresale + artwork.sold;

        // Check the unsold editions ownership can be set
        if (artwork.starts == 0) revert ArtworkDoesNotExist();
        if (artwork.starts + UNSOLD_TIMELOCK > block.timestamp) revert UnsoldTimelockNotElapsed();
        if (totalSold == artwork.editionSize) revert ArtworkSoldOut();

        // Emit burn events for the token
        for (uint256 edition = totalSold + 1; edition <= EDITION_SIZE; edition++) {
            emit Transfer(artist, address(0), _getRealTokenId(id, edition));
        }

        // Set the new edition size to the total sold amount
        artwork.editionSize = uint8(totalSold);
        _artworks[id] = artwork;

        // Update the burned counter for the whole collection
        burned += totalSold;
    }
}