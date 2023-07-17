// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ITokengateManifoldExtension.sol";

/**
 * @title Default implementation of the ITokengateManifoldExtension interface.
 *
 * See {ITokengateManifoldExtension} for more information and a detailed explanation on the way the
 * token URI generation works.
 *
 * @author DSENT AG, www.dsent.com
 */
contract TokengateManifoldExtension is
    ITokengateManifoldExtension,
    CreatorExtension,
    ICreatorExtensionTokenURI,
    AccessControlEnumerable
{
    using Strings for uint256;

    /**
     * @dev Role for all addresses that are authorized to mint tokens through this extension.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Variable that stores the base token URI that is used during token URI generation. The base
     * token URI is used for editions that have neither a token URI suffix nor a full token URI specified.
     *
     * Refer to the 'Token URI Generation' section in {ITokengateManifoldExtension} for more information on this variable.
     */
    string private _baseTokenURI;

    /**
     * @dev Variable that stores the default token URI prefix that is used during token URI generation.
     * The default token URI prefix is used for editions that have a token URI suffix defined.
     *
     * Refer to the 'Token URI Generation' section in {ITokengateManifoldExtension} for more information on this variable.
     */
    string private _defaultTokenURIPrefix;

    /**
     * @dev Variable that stores custom token URI suffixes for single editions or editions of a series.
     *
     * Note: Maps creator addresses => tokenIds => token URI suffixes
     *
     * Refer to the 'Token URI Generation' section in {ITokengateManifoldExtension} for more information on this variable.
     */
    mapping(address => mapping(uint256 => string)) private _tokenURISuffixMap;

    /**
     * @dev Variable that stores full token URIs for single editions or editions of a series.
     *
     * Note: Maps creator addresses => tokenIds => full token URIs
     *
     * Refer to the 'Token URI Generation' section in {ITokengateManifoldExtension} for more information on this variable.
     */
    mapping(address => mapping(uint256 => string)) private _fullTokenURIMap;

    /**
     * @dev Variable that stores all series created for the specified project ids.
     *
     * Note: Maps project ids => Series custom types
     */
    mapping(uint64 => Series) private _seriesMap;

    /**
     * @dev Variable that stores whether a given edition id has been minted or not. Edition ids are
     * created by bit shifting a 64-bit project id with a 32-bit edition number into a 96-bit uint.
     *
     * Note: Maps edition ids => edition minted booleans
     */
    mapping(uint96 => bool) private _mintedEditionIdMap;

    /**
     * @dev Variable that stores edition ids for all created token ids. Edition ids consist of a
     * project id and edition number and are stored by bit shifting the 64-bit project id with the
     * 32-bit edition number into a 96-bit uint.
     *
     * Note: Maps creator addresses => token ids => edition ids
     */
    mapping(address => mapping(uint256 => uint96)) private _editionIdMap;

    /**
     * @dev Note: Declaring a constructor `payable` reduces the deployed EVM bytecode by 10 opcodes.
     */
    constructor(string memory baseTokenURI, string memory defaultTokenURIPrefix)
        payable
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _baseTokenURI = baseTokenURI;
        _defaultTokenURIPrefix = defaultTokenURIPrefix;
    }

    /**
     * @dev Check whether a given interface is supported by this extension.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(CreatorExtension, IERC165, AccessControlEnumerable)
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            CreatorExtension.supportsInterface(interfaceId) ||
            interfaceId == type(ITokengateManifoldExtension).interfaceId ||
            AccessControlEnumerable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ITokengateManifoldExtension-createSeries}.
     */
    function createSeries(
        uint64 projectId,
        uint32 editionSize,
        string calldata tokenURIPrefix,
        string calldata tokenURISuffix,
        bool addEditionToTokenURISuffix,
        string calldata tokenURIExtension
    ) external onlyRole(MINTER_ROLE) {
        if (projectId == 0) {
            revert ProjectIdMustBePositive(address(this));
        }
        if (editionSize <= 1) {
            revert EditionSizeMustBeGreaterThanOne(address(this));
        }
        if (_seriesMap[projectId].hasEntry) {
            revert SeriesAlreadyCreated(address(this));
        }
        if (_mintedEditionIdMap[createEditionId(projectId, 1)]) {
            revert ProjectIsMintedAsSingleEdition(address(this));
        }

        _seriesMap[projectId] = Series(
            true,
            editionSize,
            0,
            tokenURIPrefix,
            tokenURISuffix,
            addEditionToTokenURISuffix,
            tokenURIExtension
        );

        emit SeriesCreated(projectId);
    }

    /**
     * @dev See {ITokengateManifoldExtension-setSeriesParams}.
     */
    function setSeriesParams(
        uint64 projectId,
        string calldata tokenURIPrefix,
        string calldata tokenURISuffix,
        bool addEditionToTokenURISuffix,
        string calldata tokenURIExtension
    ) external onlyRole(MINTER_ROLE) {
        if (!_seriesMap[projectId].hasEntry) {
            revert SeriesNotFound(address(this));
        }

        Series storage series = _seriesMap[projectId];
        series.tokenURIPrefix = tokenURIPrefix;
        series.tokenURISuffix = tokenURISuffix;
        series.addEditionToTokenURISuffix = addEditionToTokenURISuffix;
        series.tokenURIExtension = tokenURIExtension;

        emit SeriesParamsSet(projectId);
    }

    /**
     * @dev See {ITokengateManifoldExtension-getSeries}.
     */
    function getSeries(uint64 projectId) external view returns (Series memory) {
        return _seriesMap[projectId];
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSeries}.
     */
    function mintSeries(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 editionNumber,
        bool isFullTokenURI,
        string memory tokenURIData
    ) external onlyRole(MINTER_ROLE) {
        _mintSeries(
            creator,
            recipient,
            projectId,
            editionNumber,
            isFullTokenURI,
            tokenURIData
        );
    }

    /**
     * @dev Internal function used to mint editions of a series.
     */
    function _mintSeries(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 editionNumber,
        bool isFullTokenURI,
        string memory tokenURIData
    ) internal {
        if (recipient == address(0)) {
            revert ZeroAddressNotAllowed(address(this));
        }
        if (!_seriesMap[projectId].hasEntry) {
            revert SeriesNotFound(address(this));
        }

        if (editionNumber == 0) {
            revert EditionNumberMustBePositive(address(this));
        }

        if (editionNumber > _seriesMap[projectId].editionSize) {
            revert EditionNumberExceedsEditionSize(address(this));
        }

        uint96 editionId = createEditionId(projectId, editionNumber);
        if (_mintedEditionIdMap[editionId]) {
            revert EditionAlreadyMinted(address(this));
        }
        _mintedEditionIdMap[editionId] = true;
        _seriesMap[projectId].editionCount += 1;

        uint256 tokenId = IERC721CreatorCore(creator).mintExtension(recipient);

        if (bytes(tokenURIData).length != 0) {
            if (isFullTokenURI) {
                _fullTokenURIMap[creator][tokenId] = tokenURIData;
            } else {
                _tokenURISuffixMap[creator][tokenId] = tokenURIData;
            }
        }

        _editionIdMap[creator][tokenId] = editionId;

        emit EditionMinted(creator, tokenId, projectId, editionNumber);
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSeriesBatch1}.
     */
    function mintSeriesBatch1(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 startEditionNumber,
        uint32 nbEditions
    ) external onlyRole(MINTER_ROLE) {
        for (uint32 i = 0; i < nbEditions; ) {
            _mintSeries(
                creator,
                recipient,
                projectId,
                startEditionNumber + i,
                false,
                ""
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSeriesBatch1}.
     */
    function mintSeriesBatch1(
        address creator,
        address recipient,
        uint64 projectId,
        uint32 startEditionNumber,
        uint32 nbEditions,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external onlyRole(MINTER_ROLE) {
        if (
            isFullTokenURIs.length != nbEditions ||
            tokenURIData.length != nbEditions
        ) {
            revert ArrayLengthMismatch(address(this));
        }

        for (uint32 i = 0; i < nbEditions; ) {
            _mintSeries(
                creator,
                recipient,
                projectId,
                startEditionNumber + i,
                isFullTokenURIs[i],
                tokenURIData[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSeriesBatchN}.
     */
    function mintSeriesBatchN(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds,
        uint32[] calldata editionNumbers
    ) external onlyRole(MINTER_ROLE) {
        uint256 batchSize = recipients.length;
        if (
            projectIds.length != batchSize || editionNumbers.length != batchSize
        ) {
            revert ArrayLengthMismatch(address(this));
        }

        for (uint256 i = 0; i < batchSize; ) {
            _mintSeries(
                creator,
                recipients[i],
                projectIds[i],
                editionNumbers[i],
                false,
                ""
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSeriesBatchN}.
     */
    function mintSeriesBatchN(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds,
        uint32[] calldata editionNumbers,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external onlyRole(MINTER_ROLE) {
        uint256 batchSize = recipients.length;
        if (
            projectIds.length != batchSize ||
            editionNumbers.length != batchSize ||
            isFullTokenURIs.length != batchSize ||
            tokenURIData.length != batchSize
        ) {
            revert ArrayLengthMismatch(address(this));
        }

        for (uint256 i = 0; i < batchSize; ) {
            _mintSeries(
                creator,
                recipients[i],
                projectIds[i],
                editionNumbers[i],
                isFullTokenURIs[i],
                tokenURIData[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSingle}.
     */
    function mintSingle(
        address creator,
        address recipient,
        uint64 projectId,
        bool isFullTokenURI,
        string memory tokenURIData
    ) public onlyRole(MINTER_ROLE) {
        if (recipient == address(0)) {
            revert ZeroAddressNotAllowed(address(this));
        }
        if (projectId == 0) {
            revert ProjectIdMustBePositive(address(this));
        }

        uint96 editionId = createEditionId(projectId, 1);

        if (_mintedEditionIdMap[editionId]) {
            revert EditionAlreadyMinted(address(this));
        }
        if (_seriesMap[projectId].hasEntry) {
            revert ProjectIsMintedAsSeries(address(this));
        }

        _mintedEditionIdMap[editionId] = true;

        uint256 tokenId = IERC721CreatorCore(creator).mintExtension(recipient);

        if (bytes(tokenURIData).length != 0) {
            if (isFullTokenURI) {
                _fullTokenURIMap[creator][tokenId] = tokenURIData;
            } else {
                _tokenURISuffixMap[creator][tokenId] = tokenURIData;
            }
        }

        _editionIdMap[creator][tokenId] = editionId;

        emit EditionMinted(creator, tokenId, projectId, 1);
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSingleBatch}.
     */
    function mintSingleBatch(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds
    ) external onlyRole(MINTER_ROLE) {
        uint256 batchSize = recipients.length;
        if (projectIds.length != batchSize) {
            revert ArrayLengthMismatch(address(this));
        }

        for (uint256 i = 0; i < batchSize; ) {
            mintSingle(creator, recipients[i], projectIds[i], false, "");

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-mintSingleBatch}.
     */
    function mintSingleBatch(
        address creator,
        address[] calldata recipients,
        uint64[] calldata projectIds,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external onlyRole(MINTER_ROLE) {
        uint256 batchSize = recipients.length;
        if (
            projectIds.length != batchSize ||
            isFullTokenURIs.length != batchSize ||
            tokenURIData.length != batchSize
        ) {
            revert ArrayLengthMismatch(address(this));
        }

        for (uint256 i = 0; i < batchSize; ) {
            mintSingle(
                creator,
                recipients[i],
                projectIds[i],
                isFullTokenURIs[i],
                tokenURIData[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata baseTokenURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = baseTokenURI;
        emit BaseTokenURISet(_baseTokenURI);
    }

    /**
     * @dev See {ITokengateManifoldExtension-getBaseTokenURI}.
     */
    function getBaseTokenURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {ITokengateManifoldExtension-setDefaultTokenURIPrefix}.
     */
    function setDefaultTokenURIPrefix(string calldata defaultTokenURIPrefix_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _defaultTokenURIPrefix = defaultTokenURIPrefix_;
        emit DefaultTokenURIPrefixSet(_defaultTokenURIPrefix);
    }

    /**
     * @dev See {ITokengateManifoldExtension-getDefaultTokenURIPrefix}.
     */
    function getDefaultTokenURIPrefix() external view returns (string memory) {
        return _defaultTokenURIPrefix;
    }

    /**
     * @dev See {ITokengateManifoldExtension-setTokenURIData}.
     */
    function setTokenURIData(
        address creator,
        uint256 tokenId,
        bool isFullTokenURI,
        string calldata tokenURIData
    ) public onlyRole(MINTER_ROLE) {
        if (_editionIdMap[creator][tokenId] == 0) {
            revert TokenNotFound(address(this));
        }
        if (isFullTokenURI) {
            _fullTokenURIMap[creator][tokenId] = tokenURIData;
        } else {
            _tokenURISuffixMap[creator][tokenId] = tokenURIData;
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-setTokenURIDataBatch}.
     */
    function setTokenURIDataBatch(
        address creator,
        uint256[] calldata tokenIds,
        bool[] calldata isFullTokenURIs,
        string[] calldata tokenURIData
    ) external onlyRole(MINTER_ROLE) {
        uint256 batchSize = tokenIds.length;
        if (
            isFullTokenURIs.length != batchSize ||
            tokenURIData.length != batchSize
        ) {
            revert ArrayLengthMismatch(address(this));
        }

        for (uint256 i = 0; i < batchSize; ) {
            setTokenURIData(
                creator,
                tokenIds[i],
                isFullTokenURIs[i],
                tokenURIData[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ITokengateManifoldExtension-getTokenURISuffix}.
     */
    function getTokenURISuffix(address creator, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return _tokenURISuffixMap[creator][tokenId];
    }

    /**
     * @dev See {ITokengateManifoldExtension-getFullTokenURI}.
     */
    function getFullTokenURI(address creator, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return _fullTokenURIMap[creator][tokenId];
    }

    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     *
     * Refer to the 'Token URI Generation' section in {ITokengateManifoldExtension} for more information.
     */
    function tokenURI(address creator, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory fullTokenURI = _fullTokenURIMap[creator][tokenId];
        if (bytes(fullTokenURI).length != 0) {
            return fullTokenURI;
        }

        (uint64 projectId, uint32 editionNumber) = splitEditionId(
            _editionIdMap[creator][tokenId]
        );

        Series memory series = _seriesMap[projectId];
        if (series.hasEntry) {
            return
                getSeriesTokenURI(creator, tokenId, projectId, editionNumber);
        }

        string memory tokenURISuffix = _tokenURISuffixMap[creator][tokenId];
        if (bytes(tokenURISuffix).length != 0) {
            return
                string(
                    abi.encodePacked(_defaultTokenURIPrefix, tokenURISuffix)
                );
        }

        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    toString(creator),
                    "-",
                    tokenId.toString()
                )
            );
    }

    /**
     * @dev Internal function used to generate the tokenURI for an edition of a series.
     */
    function getSeriesTokenURI(
        address creator,
        uint256 tokenId,
        uint64 projectId,
        uint32 editionNumber
    ) internal view returns (string memory) {
        string memory suffix = _tokenURISuffixMap[creator][tokenId];
        Series memory series = _seriesMap[projectId];

        if (
            bytes(series.tokenURISuffix).length == 0 &&
            bytes(suffix).length == 0
        ) {
            return
                string(
                    abi.encodePacked(
                        _baseTokenURI,
                        toString(creator),
                        "-",
                        tokenId.toString()
                    )
                );
        }

        string memory tokenURIPrefix = getSeriesTokenURIPrefix(projectId);

        if (bytes(suffix).length != 0) {
            return string(abi.encodePacked(tokenURIPrefix, suffix));
        }

        if (series.addEditionToTokenURISuffix) {
            if (bytes(series.tokenURIExtension).length != 0) {
                return
                    string(
                        abi.encodePacked(
                            tokenURIPrefix,
                            series.tokenURISuffix,
                            uint256(editionNumber).toString(),
                            series.tokenURIExtension
                        )
                    );
            }

            return
                string(
                    abi.encodePacked(
                        tokenURIPrefix,
                        series.tokenURISuffix,
                        uint256(editionNumber).toString()
                    )
                );
        }

        return string(abi.encodePacked(tokenURIPrefix, series.tokenURISuffix));
    }

    /**
     * @dev Internal function used to determine the token URI prefix to use for an edition of a series.
     */
    function getSeriesTokenURIPrefix(uint64 projectId)
        internal
        view
        returns (string memory)
    {
        Series memory series = _seriesMap[projectId];

        if (bytes(series.tokenURIPrefix).length != 0) {
            return series.tokenURIPrefix;
        }

        return _defaultTokenURIPrefix;
    }

    /**
     * @dev See {ITokengateManifoldExtension-getTokenInfo}.
     */
    function getTokenInfo(address creator, uint256 tokenId)
        external
        view
        returns (uint64 projectId, uint32 editionNumber)
    {
        uint96 editionId = _editionIdMap[creator][tokenId];
        if (editionId == 0) {
            revert TokenNotFound(address(this));
        }
        (projectId, editionNumber) = splitEditionId(
            _editionIdMap[creator][tokenId]
        );
    }

    /**
     * @dev See {ITokengateManifoldExtension-isSeries}.
     */
    function isSeries(uint64 projectId) external view returns (bool) {
        return _seriesMap[projectId].hasEntry;
    }

    /**
     * @dev See {ITokengateManifoldExtension-isMinted}.
     */
    function isMinted(uint64 projectId, uint32 editionNumber)
        external
        view
        returns (bool)
    {
        return _mintedEditionIdMap[createEditionId(projectId, editionNumber)];
    }

    /**
     * @dev See {ITokengateManifoldExtension-createEditionId}.
     */
    function createEditionId(uint64 projectId, uint32 editionNumber)
        public
        pure
        returns (uint96)
    {
        uint96 editionId = projectId;
        editionId = editionId << 32;
        editionId = editionId + editionNumber;
        return editionId;
    }

    /**
     * @dev See {ITokengateManifoldExtension-splitEditionId}.
     */
    function splitEditionId(uint96 editionId)
        public
        pure
        returns (uint64 projectId, uint32 editionNumber)
    {
        projectId = uint64(editionId >> 32);
        editionNumber = uint32(editionId);
    }

    /**
     * @dev See {ITokengateManifoldExtension-getRoleMembers}.
     */
    function getRoleMembers(bytes32 role)
        public
        view
        returns (address[] memory)
    {
        uint256 roleCount = getRoleMemberCount(role);
        address[] memory members = new address[](roleCount);
        for (uint256 i = 0; i < roleCount; ) {
            members[i] = getRoleMember(role, i);

            unchecked {
                ++i;
            }
        }
        return members;
    }

    /**
     * @dev Convert an address to a string.
     */
    function toString(address addr) public pure returns (string memory) {
        uint256 data = uint256(uint160(addr));
        return data.toHexString();
    }
}