pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {ITokenUriResolver} from "../../interfaces/ITokenUriResolver.sol";

/// @author KnownOrigin Labs - https://knownorigin.io/
interface IERC721KODAEditions is IERC721Metadata, IERC2981 {
    error BatchOrUnknownEdition();
    error EditionDoesNotExist();
    error EditionSizeExceeded();
    error InvalidRange();
    error InvalidEditionSize();
    error InvalidMintQuantity();
    error InvalidRecipient();
    error NotAuthorised();
    error TokenAlreadyMinted();
    error TokenDoesNotExist();

    /// @dev emitted when a new edition is created
    event EditionCreated(uint256 indexed _editionId);

    /// @dev emitted when the creator address for an edition is updated
    event EditionCreatorUpdated(uint256 indexed _editionId, address _creator);

    /// @dev emitted when the owner updates the edition override for secondary royalty
    event EditionRoyaltyPercentageUpdated(
        uint256 indexed _editionId,
        uint256 _percentage
    );

    /// @dev emitted when edition sales are enabled/disabled
    event EditionSalesDisabledUpdated(
        uint256 indexed _editionId,
        bool _disabled
    );

    /// @dev emitted when the edition metadata URI is updated
    event EditionURIUpdated(uint256 indexed _editionId);

    /// @dev emitted when the external token metadata URI resolver is updated
    event TokenURIResolverUpdated(address indexed _tokenUriResolver);

    /// @dev Struct defining the properties of an edition stored internally
    struct Edition {
        uint32 editionSize; // on-chain edition size
        bool isOpenEdition; // true if not all tokens were minted at creation
        string uri; // the referenced metadata
    }

    /// @dev Struct defining the full property set of an edition exposed externally
    struct EditionDetails {
        address owner;
        address creator;
        uint256 editionId;
        uint256 mintedCount;
        uint256 size;
        bool isOpenEdition;
        string uri;
    }

    /// @dev struct defining the ownership record of an edition
    struct EditionOwnership {
        uint256 editionId;
        address editionOwner;
    }

    /// @dev returns the creator address for an edition used to indicate if the NFT creator is different to the contract creator/owner
    function editionCreator(uint256 _editionId) external view returns (address);

    /// @dev returns the full set of properties for an edition, see {EditionDetails}
    function editionDetails(
        uint256 _editionId
    ) external view returns (EditionDetails memory);

    /// @dev returns whether the edition exists or not
    function editionExists(uint256 _editionId) external view returns (bool);

    /// @dev returns the maximum possible token ID that can be minted in an edition
    function editionMaxTokenId(
        uint256 _editionId
    ) external view returns (uint256);

    /// @dev returns the number of tokens currently minted in an edition
    function editionMintedCount(
        uint256 _editionId
    ) external view returns (uint256);

    /// @dev returns the owner of an edition, by default this will be the contract owner at the time the edition was first created
    function editionOwner(uint256 _editionId) external view returns (address);

    /// @dev returns the royalty percentage used for secondary sales of an edition
    function editionRoyaltyPercentage(
        uint256 _editionId
    ) external view returns (uint256);

    /// @dev returns a boolean indicating whether sales are disabled or not for an edition
    function editionSalesDisabled(
        uint256 _editionId
    ) external view returns (bool);

    /// @dev returns a boolean indicating whether an edition is sold out (primary market) or sales are otherwise disabled
    function editionSalesDisabledOrSoldOut(
        uint256 _editionId
    ) external view returns (bool);

    /// @dev returns a boolean indicating whether an edition is sold out (primary market) or sales are otherwise disabled
    function editionSalesDisabledOrSoldOutFrom(
        uint256 _editionId,
        uint256 _startId
    ) external view returns (bool);

    /// @dev returns the size (the maximum number of tokens that can be minted) of an edition
    function editionSize(uint256 _editionId) external view returns (uint256);

    /// @dev returns a boolean indicating whether primary listings of an edition have sold out or not
    function editionSoldOut(uint256 _editionId) external view returns (bool);

    /// @dev returns a boolean indicating whether primary listings of an edition have sold out or not in a range
    function editionSoldOutFrom(
        uint256 _editionId,
        uint256 _startId
    ) external view returns (bool);

    /// @dev returns the metadata URI for an edition
    function editionURI(
        uint256 _editionId
    ) external view returns (string memory);

    /// @dev returns the edition creator address for the edition that a token with `_tokenId` belongs to
    function tokenEditionCreator(
        uint256 _tokenId
    ) external view returns (address);

    /// @dev returns the full set of properties of the edition that token `_tokenId` belongs to, see {EditionDetails}
    function tokenEditionDetails(
        uint256 _tokenId
    ) external view returns (EditionDetails memory);

    /// @dev returns the ID of an edition that a token with ID `_tokenId` belongs to
    function tokenEditionId(uint256 _tokenId) external view returns (uint256);

    /// @dev returns the size of the edition that a token with `_tokenId` belongs to
    function tokenEditionSize(uint256 _tokenId) external view returns (uint256);

    /// @dev returns a boolean indicating whether an external token metadata URI resolver is active or not
    function tokenUriResolverActive() external view returns (bool);

    /// @dev used to execute a simultaneous transfer of multiple tokens with IDs `_tokenIds`
    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _tokenIds
    ) external;

    /// @dev used to enabled/disable sales of an edition
    function toggleEditionSalesDisabled(uint256 _editionId) external;

    /// @dev used to update the address of the creator associated with the works of an edition
    function updateEditionCreator(
        uint256 _editionId,
        address _creator
    ) external;

    /// @dev used to update the royalty percentage for external secondary sales of tokens belonging to a specific edition
    function updateEditionRoyaltyPercentage(
        uint256 _editionId,
        uint256 _percentage
    ) external;

    /// @dev used to set an external token URI resolver for the contract
    function updateTokenURIResolver(
        ITokenUriResolver _tokenUriResolver
    ) external;
}