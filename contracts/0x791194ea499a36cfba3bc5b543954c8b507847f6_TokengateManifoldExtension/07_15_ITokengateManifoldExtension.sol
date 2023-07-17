// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title An extension for Manifold Creator contracts that allows the various NFT marketplaces run by
 * DSENT AG to mint tokens on behalf of a creator. The extension ensures that only a limited number of
 * editions can be minted for any given project. A project in the context of this extension serves as
 * a general term for a wide range of collectibles such as artworks, PFPs, club memberships, etc.
 * Projects can either be minted as single editions or editions of a series with a predefined maximum size.
 *
 * @author DSENT AG, www.dsent.com
 *
 * Token URI Generation:
 * ---------------------
 * The logic used to generate a URI for a specified token id uses one of three approaches
 * based on the provided token URI data. Token URI data is always specified using `isFullTokenURI` and
 * `tokenURIData` parameters. If `isFullTokenURI == true` then `tokenURIData` will be interpreted as a
 * complete token URI and no further concatenation logic will be applied. For `isFullTokenURI == false`
 * the `tokenURIData` is used as a URI suffix and is concatenated with a URI prefix to form a complete
 * token URI.
 *
 * Token URI data can either be specified during minting or afterwards using either `setTokenURIData()`
 * or its batch variant `setTokenURIDataBatch()`.
 *
 * The three approaches for URI generation work as follows:
 *
 * 1. If no specific token URI data is specified, the base token URI is concatenated with the creator
 * address and the token id to form a complete URI.
 *
 * 2. If a token URI suffix is specified for a given token, then that suffix gets concatenated with
 * a token URI prefix to form a complete URI.
 *
 * For all single editions the token URI prefix is read from the default token URI prefix variable.
 * Editions of a series on the other hand can use an optional override of the default prefix that
 * can be specified during `createSeries()` or `setSeriesParams()` calls.
 *
 * A token URI suffix can be defined directly on the token level using the URI data parameters
 * of the minting or `setTokenURIData()`/`setTokenURIDataBatch()` calls. Alternatively, it is also possible to
 * to define a suffix that applies to all editions of a series. Such a suffix can be specified during
 * `createSeries()` or `setSeriesParams()` calls. In the case of a series it is further possible to set
 * `addEditionToTokenURISuffix = true`, which will cause the concatenation logic to append the
 * edition number to the specified suffix. If necessary, an optional `tokenURIExtension` can be
 * specified, in order to append an additional extension after the edition number. This is useful if
 * an endpoint has no proper support for Content-Type headers.
 *
 * It is important to understand that a suffix defined on the token level will always take precedence
 * over one defined on a series level.
 *
 * 3. If a full token URI is specified for a given token, then that full URI takes precedence over
 * everything else. It will override a suffix that might be specified for that token.
 *
 * A full token URI must be defined directly on the token level using the URI data parameters
 * of the minting or `setTokenURIData()`/`setTokenURIDataBatch()` calls.
 */
interface ITokengateManifoldExtension is IERC165 {
    /**
     * @dev Event that is emitted when a new single edition or an edition of a series is minted.
     */
    event EditionMinted(
        address indexed creator,
        uint256 indexed tokenId,
        uint64 indexed projectId,
        uint32 editionNumber
    );

    /**
     * @dev Event that is emitted when a new series with a predefined edition size is created.
     */
    event SeriesCreated(uint64 indexed projectId);

    /**
     * @dev Event that is emitted when the parameters of a series are changed that drive the
     * token URI generation of the editions belonging to that series.
     */
    event SeriesParamsSet(uint64 indexed projectId);

    /**
     * @dev Event that is emitted when the base token URI is changed that is used during tokenURI
     * generation. The base token URI is used for editions that have neither a token URI suffix nor
     * a full token URI specified.
     */
    event BaseTokenURISet(string baseTokenURI);

    /**
     * @dev Event that is emitted when the default token URI prefix is changed that is used during
     * token URI generation. The default token URI prefix is used for editions that have a token URI suffix
     * defined.
     */
    event DefaultTokenURIPrefixSet(string defaultTokenURIPrefix);

    /**
     * @dev Error that occurs when specifying a project id of zero.
     */
    error ProjectIdMustBePositive(address emitter);

    /**
     * @dev Error that occurs when creating a series that does not consist of at least two editions.
     */
    error EditionSizeMustBeGreaterThanOne(address emitter);

    /**
     * @dev Error that occurs when minting a token of a series with an edition number of zero.
     */
    error EditionNumberMustBePositive(address emitter);

    /**
     * @dev Error that occurs when minting a token of a series with an edition number that is larger
     * than the maximum allowed size for that series.
     */
    error EditionNumberExceedsEditionSize(address emitter);

    /**
     * @dev Error that occurs when creating a series with a project id that belongs to an already
     * existing series.
     */
    error SeriesAlreadyCreated(address emitter);

    /**
     * @dev Error that occurs when creating a series for a project id that was already used to mint
     * a single edition.
     */
    error ProjectIsMintedAsSingleEdition(address emitter);

    /**
     * @dev Error that occurs when minting an edition for a project id and edition number
     * that is already used by another single edition or an edition of a series.
     */
    error EditionAlreadyMinted(address emitter);

    /**
     * @dev Error that occurs when minting a single edition for a project id that was already used
     * to create a series.
     */
    error ProjectIsMintedAsSeries(address emitter);

    /**
     * @dev Error that occurs when specifying a project id that does not belong to any of the
     * created series.
     */
    error SeriesNotFound(address emitter);

    /**
     * @dev Error that occurs when specifying the 0x0 address.
     */
    error ZeroAddressNotAllowed(address emitter);

    /**
     * @dev Error that occurs when the length of the parameter arrays used in a batch operation
     * do not match.
     */
    error ArrayLengthMismatch(address emitter);

    /**
     * @dev Error that occurs when specifying a token id that does not exist.
     */
    error TokenNotFound(address emitter);

    /**
     * @dev Custom type that is used to represent a series of limited edition tokens belonging to
     * a certain project. Series are always referenced by the project id that they belong to.
     */
    struct Series {
        /**
         * @dev Variable that stores whether a series was created for a given project id.
         */
        bool hasEntry;
        /**
         * @dev Variable that stores the maximum number of editions that can be minted for the series.
         */
        uint32 editionSize;
        /**
         * @dev Variable that stores the number of editions that have been minted for the series.
         */
        uint32 editionCount;
        /**
         * @dev Variable that stores an optional override for the default token URI prefix that is used
         * for all editions of the series.
         *
         * Refer to the 'Token URI Generation' section above for more information on this variable.
         */
        string tokenURIPrefix;
        /**
         * @dev Variable that stores an optional token URI suffix that is used for all editions of
         * the series.
         *
         * Refer to the 'Token URI Generation' section above for more information on this variable.
         */
        string tokenURISuffix;
        /**
         * @dev Variable that controls whether the edition number is to be added to the token URI suffix
         * during token URI generation or not.
         *
         * Refer to the 'Token URI Generation' section above for more information on this variable.
         */
        bool addEditionToTokenURISuffix;
        /**
         * @dev Variable that stores an optional extension to add to the edition number during
         * token URI generation. Setting this value only makes sense when `addEditionToTokenURISuffix == true`.
         *
         * Refer to the 'Token URI Generation' section above for more information on this variable.
         */
        string tokenURIExtension;
    }

    /**
     * @dev Create a new series of limited edition tokens belonging to a certain project.
     */
    function createSeries(
        uint64 projectId,
        uint32 editionSize,
        string calldata tokenURIPrefix,
        string calldata tokenURISuffix,
        bool addEditionToTokenURISuffix,
        string calldata tokenURIExtension
    ) external;

    /**
     * @dev Set the parameters of a series that drive the token URI generation of its editions.
     */
    function setSeriesParams(
        uint64 projectId,
        string calldata tokenURIPrefix,
        string calldata tokenURISuffix,
        bool addEditionToTokenURISuffix,
        string calldata tokenURIExtension
    ) external;

    /**
     * @dev Get the custom type that stores all the state variables for the specified series.
     */
    function getSeries(uint64 projectId) external view returns (Series memory);

    /**
     * @dev Mint a new edition for the series specified by the project id.
     *
     * Note: If no custom token URI data is required, use `isFullTokenURI = false` and `tokenURIData = ''`
     */
    function mintSeries(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 editionNumber,
        bool isFullTokenURI,
        string calldata tokenURIData
    ) external;

    /**
     * @dev Batch mint new editions to a single recipient for the series specified by the project id.
     * This function overload does not take any custom token URI data for the editions to mint.
     */
    function mintSeriesBatch1(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 startEditionNumber,
        uint32 nbEditions
    ) external;

    /**
     * @dev Batch mint new editions to a single recipient for the series specified by the project id.
     * This function overload takes custom token URI data for the editions to mint.
     */
    function mintSeriesBatch1(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 startEditionNumber,
        uint32 nbEditions,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external;

    /**
     * @dev Batch mint new editions to multiple recipients for the series specified by the project id.
     * This function overload does not take any custom token URI data for the editions to mint.
     */
    function mintSeriesBatchN(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds,
        uint32[] calldata editionNumbers
    ) external;

    /**
     * @dev Batch mint new editions to multiple recipients for the series specified by the project id.
     * This function overload takes custom token URI data for the editions to mint.
     */
    function mintSeriesBatchN(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds,
        uint32[] calldata editionNumbers,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external;

    /**
     * @dev Mint a new single edition for the specified project id.
     *
     * Note: If no custom token URI data is required, use `isFullTokenURI = false` and `tokenURIData = ''`
     */
    function mintSingle(
        address creator,
        address recipient,
        uint64 projectId,
        bool isFullTokenURI,
        string calldata tokenURIData
    ) external;

    /**
     * @dev Batch mint new single editions to multiple recipients for the specified project ids.
     * This function overload does not take any custom token URI data for the editions to mint.
     */
    function mintSingleBatch(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds
    ) external;

    /**
     * @dev Batch mint new single editions to multiple recipients for the specified project ids.
     * This function overload takes custom token URI data for the editions to mint.
     */
    function mintSingleBatch(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external;

    /**
     * @dev Set the base token URI that is used during token URI generation. The base token URI is
     * used for editions that have neither a token URI suffix nor a full token URI specified.
     */
    function setBaseTokenURI(string calldata baseTokenURI) external;

    /**
     * @dev Get the base token URI that is used during token URI generation. The base token URI is
     * used for editions that have neither a token URI suffix nor a full token URI specified.
     */
    function getBaseTokenURI() external view returns (string memory);

    /**
     * @dev Set the default token URI prefix that is used during token URI generation. The default
     * token URI prefix is used for editions that have a token URI suffix defined.
     */
    function setDefaultTokenURIPrefix(string calldata defaultTokenURIPrefix)
        external;

    /**
     * @dev Get the default token URI prefix that is used during token URI generation. The default
     * token URI prefix is used for editions that have a token URI suffix defined.
     */
    function getDefaultTokenURIPrefix() external view returns (string memory);

    /**
     * @dev Set either a full token URI (if `isFullTokenURI == true`) or a token URI suffix (if `isFullTokenURI == false`)
     * for the specified token id.
     *
     * Note: Specifying a full token URI always takes precedence over any other token URI generation
     * logic. If a currently active full token URI is to be replaced by a token URI suffix, make sure
     * to reset the full token URI value before by specifying an empty string '' in `tokenURIData`.
     *
     * Refer to the 'Token URI Generation' section above for more information.
     */
    function setTokenURIData(
        address creator,
        uint256 tokenId,
        bool isFullTokenURI,
        string calldata tokenURIData
    ) external;

    /**
     * @dev Batch set either full token URIs (if `isFullTokenURI == true`) or token URI suffixes (if `isFullTokenURI == false`)
     * for the specified token ids.
     *
     * Note: Specifying a full token URI always takes precedence over any other token URI generation
     * logic. If a currently active full token URI is to be replaced by a token URI suffix, make sure
     * to reset the full token URI value before by specifying an empty string '' in `tokenURIData`.
     *
     * Refer to the 'Token URI Generation' section above for more information.
     */
    function setTokenURIDataBatch(
        address creator,
        uint256[] calldata tokenIds,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external;

    /**
     * @dev Get the token URI suffix for the specified token id if one has been set.
     */
    function getTokenURISuffix(address creator, uint256 tokenId)
        external
        view
        returns (string memory);

    /**
     * @dev Get the full token URI for the specified token id if one has been set.
     */
    function getFullTokenURI(address creator, uint256 tokenId)
        external
        view
        returns (string memory);

    /**
     * @dev Get the token info consisting of the project id and edition number for the specified token id.
     */
    function getTokenInfo(address creator, uint256 tokenId)
        external
        view
        returns (uint64 projectId, uint32 editionNumber);

    /**
     * @dev Check whether a series has been created for the specified project id.
     */
    function isSeries(uint64 projectId) external view returns (bool);

    /**
     * @dev Check whether an edition has been minted for the specified project id and edition number.
     */
    function isMinted(uint64 projectId, uint32 editionNumber)
        external
        view
        returns (bool);

    /**
     * @dev Create an edition id by bit shifting a 64-bit project id with a 32-bit edition number into a 96-bit uint.
     */
    function createEditionId(uint64 projectId, uint32 editionNumber)
        external
        pure
        returns (uint96);

    /**
     * @dev Split an edition id by bit shifting the 96-bit uint into a 64-bit project id and a 32-bit edition number.
     */
    function splitEditionId(uint96 editionId)
        external
        pure
        returns (uint64 projectId, uint32 editionNumber);

    /**
     * @dev Get all addresses that are granted the specified role.
     */
    function getRoleMembers(bytes32 role)
        external
        view
        returns (address[] memory);
}