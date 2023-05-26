// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Originals is
    ERC721,
    ERC721Burnable,
    ERC721Enumerable,
    AccessControl,
    Ownable
{
    struct Release {
        bool frozenMetadata;
        uint256 maxSupply;
        uint256 createdSupply;
        uint256 totalSupply;
        uint256[] tokenIDs;
        string[] uris;
    }

    struct Token {
        uint256 releaseID;
        uint256 index;
    }

    error InvalidMaxSupply();
    error InvalidURIs();
    error ReleaseNotFound();
    error MetadataIsFrozen();
    error NotEnoughSupply();
    error TokenDoesNotBelongToRelease();
    error TokenNotFound();

    event ReleaseCreated(uint256 __releaseID);
    event MetadataUpdate(uint256 __tokenId);
    event PermanentURI(string __value, uint256 indexed __releaseID);

    // Used to track ID of next release
    uint256 private _nextReleaseID = 1;

    // Used to track ID of next token
    uint256 private _nextTokenID = 1;

    // Mapping of releases
    mapping(uint256 => Release) private _releases;

    // Mapping of tokens
    mapping(uint256 => Token) private _tokens;

    // Minter Role used in minting operations
    bytes32 constant MINTER_ROLE = bytes32("MINTER_ROLE");

    /**
     * @dev Sets name/symbol and grants initial roles to owner upon construction.
     */
    constructor(
        string memory __name,
        string memory __symbol
    ) ERC721(__name, __symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Checks if release exists.
     *
     * Requirements:
     *
     * - `__releaseID` must be of existing release.
     */
    modifier onlyExistingRelease(uint256 __releaseID) {
        if (!releaseExists(__releaseID)) {
            revert ReleaseNotFound();
        }
        _;
    }

    /**
     * @dev Checks if token exists.
     *
     * Requirements:
     *
     * - `__tokenID` must exist.
     */
    modifier onlyExistingToken(uint256 __tokenID) {
        if (!_exists(__tokenID)) {
            revert TokenNotFound();
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNALS
    ////////////////////////////////////////////////////////////////////////////

    function _beforeTokenTransfer(
        address __from,
        address __to,
        uint256 __tokenID,
        uint256 __batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(__from, __to, __tokenID, __batchSize);
    }

    ////////////////////////////////////////////////////////////////////////////
    // OWNER
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Used to create a new release.
     *
     * Emits a {ReleaseCreated} event.
     *
     */
    function createRelease(
        uint256 __maxSupply,
        string[] calldata __uris
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (__maxSupply == 0) {
            revert InvalidMaxSupply();
        }

        if (__uris.length != __maxSupply) {
            revert InvalidURIs();
        }

        uint256 releaseId = _nextReleaseID++;

        _releases[releaseId] = Release({
            frozenMetadata: false,
            maxSupply: __maxSupply,
            createdSupply: 0,
            totalSupply: 0,
            tokenIDs: new uint256[](__maxSupply),
            uris: __uris
        });

        emit ReleaseCreated(releaseId);
    }

    /**
     * @dev Used to edit a token URI.
     *
     * Emits a {MetadataUpdate} event.
     *
     */
    function editURI(
        uint256 __releaseID,
        uint256 __tokenID,
        string memory __uri
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyExistingRelease(__releaseID)
        onlyExistingToken(__tokenID)
    {
        Release memory release = _releases[__releaseID];

        if (release.frozenMetadata) {
            revert MetadataIsFrozen();
        }

        Token memory token = _tokens[__tokenID];

        if (token.releaseID != __releaseID) {
            revert TokenDoesNotBelongToRelease();
        }

        _releases[__releaseID].uris[token.index] = __uri;

        emit MetadataUpdate(__tokenID);
    }

    /**
     * @dev Used to edit the token URI(s) of a release.
     *
     * Emits a {MetadataUpdate} event.
     *
     */
    function editURIs(
        uint256 __releaseID,
        string[] memory __uris
    ) external onlyRole(DEFAULT_ADMIN_ROLE) onlyExistingRelease(__releaseID) {
        Release memory release = _releases[__releaseID];

        if (release.frozenMetadata) {
            revert MetadataIsFrozen();
        }

        if (__uris.length != release.maxSupply) {
            revert InvalidURIs();
        }

        _releases[__releaseID].uris = __uris;

        for (uint256 i = 0; i < release.tokenIDs.length; i++) {
            if (release.tokenIDs[i] != 0) {
                emit MetadataUpdate(release.tokenIDs[i]);
            }
        }
    }

    /**
     * @dev Used to freeze metadata.
     *
     * Emits a {ReleaseFrozen} event.
     *
     */
    function freezeMetadata(
        uint256 __releaseID
    ) external onlyRole(DEFAULT_ADMIN_ROLE) onlyExistingRelease(__releaseID) {
        Release memory release = _releases[__releaseID];

        _releases[__releaseID].frozenMetadata = true;

        for (uint256 i = 0; i < release.tokenIDs.length; i++) {
            if (release.tokenIDs[i] != 0) {
                emit PermanentURI(release.uris[i], release.tokenIDs[i]);
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // MINTER
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Used to mint token(s) of a release for a one account.
     */
    function mint(
        address __account,
        uint256 __releaseID,
        uint256 __amount
    ) external onlyRole(MINTER_ROLE) onlyExistingRelease(__releaseID) {
        Release memory release = _releases[__releaseID];

        if (release.createdSupply + __amount > release.maxSupply) {
            revert NotEnoughSupply();
        }

        for (uint256 i = 0; i < __amount; i++) {
            uint256 tokenID = _nextTokenID++;
            uint256 tokenIndex = _releases[__releaseID].createdSupply++;
            _releases[__releaseID].tokenIDs[tokenIndex] = tokenID;
            _tokens[tokenID] = Token(__releaseID, tokenIndex);
            _safeMint(__account, tokenID);
        }

        _releases[__releaseID].totalSupply += __amount;
    }

    /**
     * @dev Used to mint token(s) of a release for many accounts.
     */
    function mintMany(
        address[] calldata __accounts,
        uint256 __releaseID,
        uint256[] calldata __amounts
    ) external onlyRole(MINTER_ROLE) onlyExistingRelease(__releaseID) {
        Release memory release = _releases[__releaseID];

        uint256 totalAmount = 0;
        for (uint i = 0; i < __amounts.length; i++) {
            totalAmount += __amounts[i];
        }

        if (
            release.createdSupply + totalAmount >
            _releases[__releaseID].maxSupply
        ) {
            revert NotEnoughSupply();
        }

        for (uint256 i = 0; i < __accounts.length; i++) {
            for (uint256 n = 0; n < __amounts[i]; n++) {
                uint256 tokenID = _nextTokenID++;
                uint256 tokenIndex = _releases[__releaseID].createdSupply++;
                _releases[__releaseID].tokenIDs[tokenIndex] = tokenID;
                _tokens[tokenID] = Token(__releaseID, tokenIndex);
                _safeMint(__accounts[i], tokenID);
            }
        }

        _releases[__releaseID].totalSupply += totalAmount;
    }

    ////////////////////////////////////////////////////////////////////////////
    // WRITES
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Used to burn token(s) of a release for a one account.
     */
    function burn(
        uint256 __tokenID
    ) public override onlyExistingToken(__tokenID) {
        super.burn(__tokenID);

        Token memory token = _tokens[__tokenID];

        _releases[token.releaseID].tokenIDs[token.index] = 0;
        _releases[token.releaseID].totalSupply -= 1;
    }

    ////////////////////////////////////////////////////////////////////////////
    // READS
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Returns the max supply of a release.
     */
    function createdSupply(
        uint256 __releaseID
    ) external view onlyExistingRelease(__releaseID) returns (uint256) {
        return _releases[__releaseID].createdSupply;
    }

    /**
     * @dev Returns whether or not a release exists.
     */
    function releaseExists(uint256 __releaseID) public view returns (bool) {
        if (__releaseID != 0 && __releaseID < _nextReleaseID) {
            return true;
        }
        return false;
    }

    /**
     * @dev Returns a release.
     */
    function getRelease(
        uint256 __releaseID
    ) external view onlyExistingRelease(__releaseID) returns (Release memory) {
        return _releases[__releaseID];
    }

    /**
     * @dev Returns the max supply of a release.
     */
    function maxSupply(
        uint256 __releaseID
    ) external view onlyExistingRelease(__releaseID) returns (uint256) {
        return _releases[__releaseID].maxSupply;
    }

    /**
     * @dev Returns the number of total releases.
     */
    function totalReleases() external view returns (uint256) {
        return _nextReleaseID - 1;
    }

    /**
     * @dev Returns the token URI of a release.
     */
    function tokenURI(
        uint256 __tokenID
    )
        public
        view
        virtual
        override
        onlyExistingToken(__tokenID)
        returns (string memory)
    {
        Token memory token = _tokens[__tokenID];

        if (!releaseExists(token.releaseID)) {
            revert ReleaseNotFound();
        }

        return _releases[token.releaseID].uris[token.index];
    }

    /**
     * @dev See {ERC721-supportsInterface} and {AccessControl-supportsInterface}.
     */
    function supportsInterface(
        bytes4 __interfaceId
    )
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(__interfaceId);
    }
}