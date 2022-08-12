// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { ERC721Upgradeable } from "../../deps//ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "../../deps/IERC165Upgradeable.sol";
import { IERC2981Upgradeable } from "../../deps/IERC2981Upgradeable.sol";
import { PausableUpgradeable } from "../../deps/PausableUpgradeable.sol";

import { IIkaniV2Staking } from "../../staking/v2/interfaces/IIkaniV2Staking.sol";
import { IIkaniV1MetadataController } from "../v1/interfaces/IIkaniV1MetadataController.sol";
import { ContractUriUpgradeable } from "../v1/lib/ContractUriUpgradeable.sol";
import { ERC721SequentialUpgradeable } from "../v1/lib/ERC721SequentialUpgradeable.sol";
import { PersonalSign } from "../v1/lib/PersonalSign.sol";
import { WithdrawableUpgradeable } from "../v1/lib/WithdrawableUpgradeable.sol";
import { IkaniV2SeriesLib } from "./lib/IkaniV2SeriesLib.sol";
import { IIkaniV2 } from "./interfaces/IIkaniV2.sol";

/**
 * @title IkaniV2
 * @author Cyborg Labs, LLC
 *
 * @notice The IKANI.AI ERC-721 NFT.
 */
contract IkaniV2 is
    ERC721SequentialUpgradeable,
    ContractUriUpgradeable,
    WithdrawableUpgradeable,
    PausableUpgradeable,
    IERC2981Upgradeable,
    IIkaniV2
{
    //---------------- Constants ----------------//

    uint256 internal constant BIPS_DENOMINATOR = 10000;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable MAX_SUPPLY; // e.g. 8888

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IIkaniV2Staking public immutable STAKING_CONTRACT;

    //---------------- Storage V1 ----------------//

    IIkaniV1MetadataController internal _METADATA_CONTROLLER_;

    address internal _MINT_SIGNER_;

    /// @dev The set of message digests signed and consumed for minting.
    mapping(bytes32 => bool) internal _USED_MINT_DIGESTS_;

    /// @dev DEPRECATED: Poem text and metadata by token ID.
    mapping(uint256 => bytes) internal __DEPRECATED_POEM_INFO_;

    /// @dev Series information by index.
    mapping(uint256 => IIkaniV2.Series) internal _SERIES_INFO_;

    /// @dev Index of the current series available for minting.
    uint256 internal _CURRENT_SERIES_INDEX_;

    //---------------- Storage V1_1 ----------------//

    /// @dev Poem text by token ID.
    mapping(uint256 => string) internal _POEM_TEXT_;

    /// @dev Metadata traits by token ID.
    mapping(uint256 => IIkaniV2.PoemTraits) internal _POEM_TRAITS_;

    //---------------- Storage V2 ----------------//

    address internal _ROYALTY_RECEIVER_;

    uint96 internal _ROYALTY_BIPS_;

    //---------------- Constructor & Initializer ----------------//

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        uint256 maxSupply,
        IIkaniV2Staking stakingContract
    )
        initializer
    {
        MAX_SUPPLY = maxSupply;
        STAKING_CONTRACT = stakingContract;
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

    function setRoyaltyReceiver(
        address royaltyReceiver
    )
        external
        onlyOwner
    {
        _ROYALTY_RECEIVER_ = royaltyReceiver;
        emit SetRoyaltyReceiver(royaltyReceiver);
    }

    function setRoyaltyBips(
        uint96 royaltyBips
    )
        external
        onlyOwner
    {
        _ROYALTY_BIPS_ = royaltyBips;
        emit SetRoyaltyBips(uint256(royaltyBips));
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
        IIkaniV2.PoemTraits[] calldata poemTraits
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
            IIkaniV2.PoemTraits memory traits = poemTraits[i];

            require(
                traits.theme != IIkaniV2.Theme.NULL,
                "Theme cannot be null"
            );
            require(
                traits.fabric != IIkaniV2.Fabric.NULL,
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
        IIkaniV2.Series storage _series_ = _SERIES_INFO_[seriesIndex];

        _series_.name = name;
        _series_.provenanceHash = provenanceHash;

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

        IkaniV2SeriesLib.endCurrentSeries(
            _SERIES_INFO_[seriesIndex],
            seriesIndex,
            poemCreationDeadline,
            getNextTokenId()
        );
    }

    function advancePoemCreationDeadline(
        uint256 seriesIndex,
        uint256 poemCreationDeadline
    )
        external
        onlyOwner
    {
        IIkaniV2.Series storage _series_ = _SERIES_INFO_[seriesIndex];

        require(
            poemCreationDeadline > _series_.poemCreationDeadline,
            "Deadline can only move forward"
        );

        _series_.poemCreationDeadline = poemCreationDeadline;

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

        for (uint256 i = 0; i < n;) {
            // Note: Intentionally not using _safeMint().
            _mint(recipients[i]);

            unchecked { ++i; }
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

        IIkaniV2.Series storage _series_ = _SERIES_INFO_[seriesIndex];

        require(
            _series_.startingIndexBlockNumber != 0,
            "Series not ended"
        );
        require(
            block.timestamp > _series_.poemCreationDeadline,
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

        IkaniV2SeriesLib.validateExpireBatch(
            _SERIES_INFO_,
            tokenIds,
            seriesIndex
        );

        uint256 n = tokenIds.length;

        for (uint256 i = 0; i < n;) {
            require(
                !isPoemFinished(tokenIds[i]),
                "Cannot expire a finished poem"
            );
            _burn(tokenIds[i]);

            unchecked { ++i; }
        }
    }

    //---------------- Other State-Changing External Functions ----------------//

    function mint(
        IIkaniV2.MintArgs calldata mintArgs,
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
        IkaniV2SeriesLib.trySetSeriesStartingIndex(
            _SERIES_INFO_,
            seriesIndex
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

    function getSeriesSupply(
        uint256 seriesIndex
    )
        external
        view
        returns (uint256)
    {
        return IkaniV2SeriesLib.getSeriesSupply(_SERIES_INFO_, seriesIndex);
    }

    function royaltyInfo(
        uint256 /* tokenId */,
        uint256 salePrice
    )
        external
        view
        override
        returns (address, uint256)
    {
        uint256 royaltyAmount = (salePrice * uint256(_ROYALTY_BIPS_)) / BIPS_DENOMINATOR;
        return (_ROYALTY_RECEIVER_, royaltyAmount);
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
        returns (IIkaniV2.Series memory)
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
        for (seriesIndex = 0; seriesIndex < currentSeriesIndex;) {
            IIkaniV2.Series storage _series_ = _SERIES_INFO_[seriesIndex];

            if (tokenId < _series_.maxTokenIdExclusive) {
                break;
            }

            unchecked { ++seriesIndex; }
        }
        return seriesIndex;
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
        returns (IIkaniV2.PoemTraits memory)
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
        return _POEM_TRAITS_[tokenId].theme != IIkaniV2.Theme.NULL;
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

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    //---------------- Internal Functions ----------------//

    function _beforeTokenTransfer(
        address /* from */,
        address /* to */,
        uint256 tokenId
    )
        internal
        view
        override
    {
        // Ensure that staked tokens can only be transfered via the staking contract.
        if (msg.sender != address(STAKING_CONTRACT)) {
            require(
                !STAKING_CONTRACT.isStaked(tokenId),
                "Cannot transfer staked token"
            );
        }
    }
}