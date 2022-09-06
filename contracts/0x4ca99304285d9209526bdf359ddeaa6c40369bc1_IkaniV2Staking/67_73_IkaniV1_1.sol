// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { PausableUpgradeable } from "../../deps/PausableUpgradeable.sol";

import { IIkaniV1_1 } from "./interfaces/IIkaniV1_1.sol";
import { IIkaniV1MetadataController } from "./interfaces/IIkaniV1MetadataController.sol";
import { ContractUriUpgradeable } from "./lib/ContractUriUpgradeable.sol";
import { ERC721SequentialUpgradeable } from "./lib/ERC721SequentialUpgradeable.sol";
import { PersonalSign } from "./lib/PersonalSign.sol";
import { WithdrawableUpgradeable } from "./lib/WithdrawableUpgradeable.sol";

/**
 * @title IkaniV1_1
 * @author Cyborg Labs, LLC
 *
 * @notice The IKANI.AI ERC-721 NFT.
 */
contract IkaniV1_1 is
    ERC721SequentialUpgradeable,
    ContractUriUpgradeable,
    WithdrawableUpgradeable,
    PausableUpgradeable,
    IIkaniV1_1
{
    //---------------- Constants ----------------//

    uint256 public constant STARTING_INDEX_ADD_BLOCKS = 10;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable MAX_SUPPLY; // e.g. 8888

    //---------------- Storage V1 ----------------//

    IIkaniV1MetadataController internal _METADATA_CONTROLLER_;

    address internal _MINT_SIGNER_;

    /// @dev The set of message digests signed and consumed for minting.
    mapping(bytes32 => bool) internal _USED_MINT_DIGESTS_;

    /// @dev DEPRECATED: Poem text and metadata by token ID.
    mapping(uint256 => bytes) internal __DEPRECATED_POEM_INFO_;

    /// @dev Series information by index.
    mapping(uint256 => IIkaniV1_1.Series) internal _SERIES_INFO_;

    /// @dev Index of the current series available for minting.
    uint256 internal _CURRENT_SERIES_INDEX_;

    //---------------- Storage V1_1 ----------------//

    /// @dev Poem text by token ID.
    mapping(uint256 => string) internal _POEM_TEXT_;

    /// @dev Metadata traits by token ID.
    mapping(uint256 => IIkaniV1_1.PoemTraits) internal _POEM_TRAITS_;

    //---------------- Constructor & Initializer ----------------//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        uint256 maxSupply
    )
        initializer
    {
        MAX_SUPPLY = maxSupply;
    }

    //---------------- Owner-Only External Functions ----------------//

    function pause()
        external
        onlyOwner
    {
        _pause();
    }

    function unpause()
        external
        onlyOwner
    {
        _unpause();
    }

    function setContractUri(
        string memory contractUri
    )
        external
        onlyOwner
    {
        _setContractUri(contractUri);
    }

    function setMetadataController(
        IIkaniV1MetadataController metadataController
    )
        external
        onlyOwner
    {
        _METADATA_CONTROLLER_ = metadataController;
    }

    function setMintSigner(
        address mintSigner
    )
        external
        onlyOwner
    {
        _MINT_SIGNER_ = mintSigner;
    }

    function setPoemText(
        uint256[] calldata tokenIds,
        string[] calldata poemText
    )
        external
        onlyOwner
    {
        // Note: To save gas, we don't check that the token was minted; however,
        //       the owner should only call this function with minted token IDs.

        uint256 n = tokenIds.length;

        require(
            poemText.length == n,
            "Params length mismatch"
        );

        for (uint256 i = 0; i < n;) {
            _POEM_TEXT_[tokenIds[i]] = poemText[i];
            unchecked { ++i; }
        }
    }

    function setPoemTraits(
        uint256[] calldata tokenIds,
        IIkaniV1_1.PoemTraits[] calldata poemTraits
    )
        external
        onlyOwner
    {
        // Note: To save gas, we don't check that the token was minted; however,
        //       the owner should only call this function with minted token IDs.

        uint256 n = tokenIds.length;

        require(
            poemTraits.length == n,
            "Params length mismatch"
        );

        for (uint256 i = 0; i < n;) {
            uint256 tokenId = tokenIds[i];
            IIkaniV1_1.PoemTraits memory traits = poemTraits[i];
            require(
                traits.theme != IIkaniV1_1.Theme.NULL,
                "Theme cannot be null"
            );
            require(
                traits.fabric != IIkaniV1_1.Fabric.NULL,
                "Fabric cannot be null"
            );
            _POEM_TRAITS_[tokenId] = traits;
            emit FinishedPoem(tokenId);
            unchecked { ++i; }
        }
    }

    function setSeriesInfo(
        uint256 seriesIndex,
        string calldata name,
        bytes32 provenanceHash
    )
        external
        onlyOwner
    {
        IIkaniV1_1.Series storage series = _SERIES_INFO_[seriesIndex];

        series.name = name;
        series.provenanceHash = provenanceHash;

        emit SetSeriesInfo(
            seriesIndex,
            name,
            provenanceHash
        );
    }

    function endCurrentSeries(
        uint256 poemCreationDeadline
    )
        external
        onlyOwner
    {
        uint256 seriesIndex = _CURRENT_SERIES_INDEX_++;

        IIkaniV1_1.Series storage series = _SERIES_INFO_[seriesIndex];

        uint256 maxTokenIdExclusive = getNextTokenId();
        uint256 startingIndexBlockNumber = block.number + STARTING_INDEX_ADD_BLOCKS;

        series.poemCreationDeadline = poemCreationDeadline;
        series.maxTokenIdExclusive = maxTokenIdExclusive;
        series.startingIndexBlockNumber = startingIndexBlockNumber;

        emit EndedSeries(
            seriesIndex,
            poemCreationDeadline,
            maxTokenIdExclusive,
            startingIndexBlockNumber
        );
    }

    function advancePoemCreationDeadline(
        uint256 seriesIndex,
        uint256 poemCreationDeadline
    )
        external
        onlyOwner
    {
        IIkaniV1_1.Series storage series = _SERIES_INFO_[seriesIndex];

        require(
            poemCreationDeadline > series.poemCreationDeadline,
            "Can only move the deadline forward"
        );

        series.poemCreationDeadline = poemCreationDeadline;

        emit AdvancedPoemCreationDeadline(
            seriesIndex,
            poemCreationDeadline
        );
    }

    function mintByOwner(
        address[] calldata recipients
    )
        external
        onlyOwner
    {
        uint256 n = recipients.length;

        for (uint256 i = 0; i < n; i++) {
            // Note: Intentionally not using _safeMint().
            _mint(recipients[i]);
        }

        require(
            getNextTokenId() <= MAX_SUPPLY,
            "Global max supply exceeded"
        );
    }

    function expire(
        uint256 tokenId
    )
        external
        onlyOwner
    {
        require(
            !isPoemFinished(tokenId),
            "Cannot expire a finished poem"
        );

        uint256 seriesIndex = getPoemSeriesIndex(tokenId);

        IIkaniV1_1.Series storage series = _SERIES_INFO_[seriesIndex];

        require(
            series.startingIndexBlockNumber != 0,
            "Series not ended"
        );
        require(
            block.timestamp > series.poemCreationDeadline,
            "Token has not expired"
        );

        _burn(tokenId);
    }

    function expireBatch(
        uint256[] calldata tokenIds,
        uint256 seriesIndex
    )
        external
        onlyOwner
    {
        require(
            seriesIndex <= _CURRENT_SERIES_INDEX_,
            "Invalid series index"
        );

        IIkaniV1_1.Series storage series = _SERIES_INFO_[seriesIndex];

        require(
            series.startingIndexBlockNumber != 0,
            "Series not ended"
        );
        require(
            block.timestamp > series.poemCreationDeadline,
            "Series has not expired"
        );

        uint256 n = tokenIds.length;

        uint256 maxTokenIdExclusive = series.maxTokenIdExclusive;
        for (uint256 i = 0; i < n; i++) {
            require(
                tokenIds[i] < maxTokenIdExclusive,
                "Token ID not part of the series"
            );
        }

        if (seriesIndex > 0) {
            uint256 startTokenId = _SERIES_INFO_[seriesIndex - 1].maxTokenIdExclusive;
            for (uint256 i = 0; i < n; i++) {
                require(
                    tokenIds[i] >= startTokenId,
                    "Token ID not part of the series"
                );
            }
        }

        for (uint256 i = 0; i < n; i++) {
            require(
                !isPoemFinished(tokenIds[i]),
                "Cannot expire a finished poem"
            );
            _burn(tokenIds[i]);
        }
    }

    //---------------- Other State-Changing External Functions ----------------//

    function mint(
        IIkaniV1_1.MintArgs calldata mintArgs,
        bytes calldata signature
    )
        external
        payable
        whenNotPaused
    {
        require(
            mintArgs.seriesIndex == _CURRENT_SERIES_INDEX_,
            "Not the current series"
        );

        require(
            msg.value == mintArgs.mintPrice,
            "Wrong msg.value"
        );

        address sender = msg.sender;
        bytes memory message = abi.encode(
            sender,
            mintArgs
        );
        bytes32 messageDigest = keccak256(message);

        // Only allow one mint per message/digest/signature.
        require(
            !_USED_MINT_DIGESTS_[messageDigest],
            "Mint digest already used"
        );
        _USED_MINT_DIGESTS_[messageDigest] = true;

        // Note: Since the only signer is our admin, we don't need EIP-712.
        require(
            PersonalSign.isValidSignature(messageDigest, signature, _MINT_SIGNER_),
            "Invalid signature"
        );

        // Note: Intentionally not using _safeMint().
        uint256 tokenId = _mint(sender);

        require(
            tokenId < mintArgs.maxTokenIdExclusive,
            "Series max supply exceeded"
        );
        require(
            tokenId < MAX_SUPPLY,
            "Global max supply exceeded"
        );
    }

    function trySetSeriesStartingIndex(
        uint256 seriesIndex
    )
        external
        whenNotPaused
    {
        IIkaniV1_1.Series storage series = _SERIES_INFO_[seriesIndex];

        require(
            !series.startingIndexWasSet,
            "Starting index already set"
        );

        uint256 targetBlockNumber = series.startingIndexBlockNumber;
        require(
            targetBlockNumber != 0,
            "Series not ended"
        );

        require(
            block.number >= targetBlockNumber,
            "Starting index block not reached"
        );

        // If the hash for the target block is not available, set a new block number and exit.
        if (block.number - targetBlockNumber > 256) {
            uint256 newStartingIndexBlockNumber = block.number + STARTING_INDEX_ADD_BLOCKS;
            series.startingIndexBlockNumber = newStartingIndexBlockNumber;
            emit ResetSeriesStartingIndexBlockNumber(
                seriesIndex,
                newStartingIndexBlockNumber
            );
            return;
        }

        uint256 seriesSupply = getSeriesSupply(seriesIndex);
        uint256 startingIndex = uint256(blockhash(targetBlockNumber)) % seriesSupply;

        series.startingIndex = startingIndex;
        series.startingIndexWasSet = true;

        emit SetSeriesStartingIndex(
            seriesIndex,
            startingIndex
        );
    }

    //---------------- View-Only External Functions ----------------//

    function getMetadataController()
        external
        view
        returns (IIkaniV1MetadataController)
    {
        return _METADATA_CONTROLLER_;
    }

    function getMintSigner()
        external
        view
        returns (address)
    {
        return _MINT_SIGNER_;
    }

    function isUsedMintDigest(
        bytes32 digest
    )
        external
        view
        returns (bool)
    {
        return _USED_MINT_DIGESTS_[digest];
    }

    function getSeriesInfo(
        uint256 seriesIndex
    )
        external
        view
        returns (IIkaniV1_1.Series memory)
    {
        return _SERIES_INFO_[seriesIndex];
    }

    function getCurrentSeriesIndex()
        external
        view
        returns (uint256)
    {
        return _CURRENT_SERIES_INDEX_;
    }

    function exists(
        uint256 tokenId
    )
        external
        view
        returns (bool)
    {
        return _exists(tokenId);
    }

    //---------------- Public Functions ----------------//

    function getPoemSeriesIndex(
        uint256 tokenId
    )
        public
        view
        returns (uint256)
    {
        uint256 currentSeriesIndex = _CURRENT_SERIES_INDEX_;
        uint256 seriesIndex;
        for (seriesIndex = 0; seriesIndex < currentSeriesIndex; seriesIndex++) {
            IIkaniV1_1.Series storage series = _SERIES_INFO_[seriesIndex];

            if (tokenId < series.maxTokenIdExclusive) {
                break;
            }
        }
        return seriesIndex;
    }

    function getSeriesSupply(
        uint256 seriesIndex
    )
        public
        view
        returns (uint256)
    {
        IIkaniV1_1.Series storage series = _SERIES_INFO_[seriesIndex];

        require(
            series.startingIndexBlockNumber != 0,
            "Series not ended"
        );

        uint256 maxTokenIdExclusive = series.maxTokenIdExclusive;

        if (seriesIndex == 0) {
            return maxTokenIdExclusive;
        }

        IIkaniV1_1.Series storage previousSeries = _SERIES_INFO_[seriesIndex - 1];

        return maxTokenIdExclusive - previousSeries.maxTokenIdExclusive;
    }

    function getPoemText(
        uint256 tokenId
    )
        public
        view
        returns (string memory)
    {
        return _POEM_TEXT_[tokenId];
    }

    function getPoemTraits(
        uint256 tokenId
    )
        public
        view
        returns (IIkaniV1_1.PoemTraits memory)
    {
        return _POEM_TRAITS_[tokenId];
    }

    function isPoemFinished(
        uint256 tokenId
    )
        public
        view
        returns (bool)
    {
        return _POEM_TRAITS_[tokenId].theme != IIkaniV1_1.Theme.NULL;
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override
        returns (string memory)
    {
        return _METADATA_CONTROLLER_.tokenURI(tokenId);
    }
}