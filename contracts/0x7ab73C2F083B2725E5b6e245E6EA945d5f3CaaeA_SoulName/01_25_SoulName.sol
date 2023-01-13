// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./libraries/Errors.sol";
import "./libraries/Utils.sol";
import "./interfaces/ISoulboundIdentity.sol";
import "./interfaces/ISoulName.sol";
import "./tokens/MasaNFT.sol";

/// @title SoulName NFT
/// @author Masa Finance
/// @notice SoulName NFT that points to a Soulbound identity token
/// @dev SoulName NFT, that inherits from the NFT contract, and points to a Soulbound identity token.
/// It has an extension, and stores all the information about the identity names.
contract SoulName is MasaNFT, ISoulName, ReentrancyGuard {
    /* ========== STATE VARIABLES ========== */
    using SafeMath for uint256;

    uint256 constant YEAR = 31536000; // 60 seconds * 60 minutes * 24 hours * 365 days

    ISoulboundIdentity public soulboundIdentity;
    string public extension; // suffix of the names (.sol?)

    // contractURI() points to the smart contract metadata
    // see https://docs.opensea.io/docs/contract-level-metadata
    string public contractURI;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    mapping(string => bool) private _URIs; // used to check if a uri is already used

    mapping(uint256 => TokenData) public tokenData; // used to store the data of the token id
    mapping(string => NameData) public nameData; // stores the token id of the current active soul name

    struct TokenData {
        string name; // Name with lowercase and uppercase
        uint256 expirationDate;
    }

    struct NameData {
        bool exists;
        uint256 tokenId;
    }

    /* ========== INITIALIZE ========== */

    /// @notice Creates a new SoulName NFT
    /// @dev Creates a new SoulName NFT, that points to a Soulbound identity, inheriting from the NFT contract.
    /// @param admin Administrator of the smart contract
    /// @param _soulboundIdentity Address of the Soulbound identity contract
    /// @param _extension Extension of the soul name
    /// @param _contractURI URI of the smart contract metadata
    constructor(
        address admin,
        ISoulboundIdentity _soulboundIdentity,
        string memory _extension,
        string memory _contractURI
    ) MasaNFT(admin, "Masa Soul Name", "MSN", "") {
        if (address(_soulboundIdentity) == address(0)) revert ZeroAddress();

        soulboundIdentity = _soulboundIdentity;
        extension = _extension;
        contractURI = _contractURI;
    }

    /* ========== RESTRICTED FUNCTIONS ====================================== */

    /// @notice Sets the SoulboundIdentity contract address linked to this soul name
    /// @dev The caller must have the admin role to call this function
    /// @param _soulboundIdentity Address of the SoulboundIdentity contract
    function setSoulboundIdentity(ISoulboundIdentity _soulboundIdentity)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (address(_soulboundIdentity) == address(0)) revert ZeroAddress();
        if (soulboundIdentity == _soulboundIdentity) revert SameValue();
        soulboundIdentity = _soulboundIdentity;
    }

    /// @notice Sets the extension of the soul name
    /// @dev The caller must have the admin role to call this function
    /// @param _extension Extension of the soul name
    function setExtension(string memory _extension)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (
            keccak256(abi.encodePacked((extension))) ==
            keccak256(abi.encodePacked((_extension)))
        ) revert SameValue();
        extension = _extension;
    }

    /// @notice Sets the URI of the smart contract metadata
    /// @dev The caller must have the admin role to call this function
    /// @param _contractURI URI of the smart contract metadata
    function setContractURI(string memory _contractURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (
            keccak256(abi.encodePacked((contractURI))) ==
            keccak256(abi.encodePacked((_contractURI)))
        ) revert SameValue();
        contractURI = _contractURI;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Mints a new soul name
    /// @dev The caller can mint more than one name. The soul name must be unique.
    /// @param to Address of the owner of the new soul name
    /// @param name Name of the new soul name
    /// @param yearsPeriod Years of validity of the name
    /// @param _tokenURI URI of the NFT
    function mint(
        address to,
        string memory name,
        uint256 yearsPeriod,
        string memory _tokenURI
    ) public override nonReentrant returns (uint256) {
        if (!isAvailable(name)) revert NameAlreadyExists(name);
        if (bytes(name).length == 0) revert ZeroLengthName(name);
        if (yearsPeriod == 0) revert ZeroYearsPeriod(yearsPeriod);
        if (soulboundIdentity.balanceOf(to) == 0)
            revert AddressDoesNotHaveIdentity(to);
        if (
            !Utils.startsWith(_tokenURI, "ar://") &&
            !Utils.startsWith(_tokenURI, "ipfs://")
        ) revert InvalidTokenURI(_tokenURI);

        uint256 tokenId = _mintWithCounter(to);
        _setTokenURI(tokenId, _tokenURI);

        tokenData[tokenId].name = name;
        tokenData[tokenId].expirationDate = block.timestamp.add(
            YEAR.mul(yearsPeriod)
        );

        string memory lowercaseName = Utils.toLowerCase(name);
        nameData[lowercaseName].tokenId = tokenId;
        nameData[lowercaseName].exists = true;

        return tokenId;
    }

    /// @notice Update the expiration date of a soul name
    /// @dev The caller must be the owner or an approved address of the soul name.
    /// @param tokenId TokenId of the soul name
    /// @param yearsPeriod Years of validity of the name
    function renewYearsPeriod(uint256 tokenId, uint256 yearsPeriod) external {
        // ERC721: caller is not token owner nor approved
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert CallerNotOwner(_msgSender());
        if (yearsPeriod == 0) revert ZeroYearsPeriod(yearsPeriod);

        // check that the last registered tokenId for that name is the current token
        string memory lowercaseName = Utils.toLowerCase(
            tokenData[tokenId].name
        );
        if (nameData[lowercaseName].tokenId != tokenId)
            revert NameRegisteredByOtherAccount(lowercaseName, tokenId);

        // check if the name is expired
        if (tokenData[tokenId].expirationDate < block.timestamp) {
            tokenData[tokenId].expirationDate = block.timestamp.add(
                YEAR.mul(yearsPeriod)
            );
        } else {
            tokenData[tokenId].expirationDate = tokenData[tokenId]
                .expirationDate
                .add(YEAR.mul(yearsPeriod));
        }

        emit YearsPeriodRenewed(
            tokenId,
            yearsPeriod,
            tokenData[tokenId].expirationDate
        );
    }

    /// @notice Burn a soul name
    /// @dev The caller must be the owner or an approved address of the soul name.
    /// @param tokenId TokenId of the soul name to burn
    function burn(uint256 tokenId) public override {
        if (!_exists(tokenId)) revert TokenNotFound(tokenId);

        string memory lowercaseName = Utils.toLowerCase(
            tokenData[tokenId].name
        );

        // remove info from tokenIdName and tokenData
        delete tokenData[tokenId];

        // if the last owner of the name is burning it, remove the name from nameData
        if (nameData[lowercaseName].tokenId == tokenId) {
            delete nameData[lowercaseName];
        }

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            _URIs[_tokenURIs[tokenId]] = false;
            delete _tokenURIs[tokenId];
        }

        super.burn(tokenId);
    }

    /* ========== VIEWS ========== */

    /// @notice Returns the extension of the soul name
    /// @dev This function is used to get the extension of the soul name
    /// @return Extension of the soul name
    function getExtension() external view override returns (string memory) {
        return extension;
    }

    /// @notice Checks if a soul name is available
    /// @dev This function queries if a soul name already exists and is in the available state
    /// @param name Name of the soul name
    /// @return available `true` if the soul name is available, `false` otherwise
    function isAvailable(string memory name)
        public
        view
        override
        returns (bool available)
    {
        string memory lowercaseName = Utils.toLowerCase(name);
        if (nameData[lowercaseName].exists) {
            uint256 tokenId = nameData[lowercaseName].tokenId;
            return tokenData[tokenId].expirationDate < block.timestamp;
        } else {
            return true;
        }
    }

    /// @notice Returns the information of a soul name
    /// @dev This function queries the information of a soul name
    /// @param name Name of the soul name
    /// @return sbtName Soul name, in upper/lower case and extension
    /// @return linked `true` if the soul name is linked, `false` otherwise
    /// @return identityId Identity id of the soul name
    /// @return tokenId SoulName id of the soul name
    /// @return expirationDate Expiration date of the soul name
    /// @return active `true` if the soul name is active, `false` otherwise
    function getTokenData(string memory name)
        external
        view
        override
        returns (
            string memory sbtName,
            bool linked,
            uint256 identityId,
            uint256 tokenId,
            uint256 expirationDate,
            bool active
        )
    {
        tokenId = _getTokenId(name);
        address _owner = ownerOf(tokenId);
        bool _linked = soulboundIdentity.balanceOf(_owner) > 0;
        uint256 _identityId = 0;
        if (_linked) {
            _identityId = soulboundIdentity.tokenOfOwner(_owner);
        }

        TokenData memory _tokenData = tokenData[tokenId];

        return (
            _getName(_tokenData.name),
            _linked,
            _identityId,
            tokenId,
            _tokenData.expirationDate,
            _tokenData.expirationDate >= block.timestamp
        );
    }

    /// @notice Returns the token id of a soul name
    /// @dev This function queries the token id of a soul name
    /// @param name Name of the soul name
    /// @return SoulName id of the soul name
    function getTokenId(string memory name)
        external
        view
        override
        returns (uint256)
    {
        return _getTokenId(name);
    }

    /// @notice Returns all the active soul names of an account
    /// @dev This function queries all the identity names of the specified identity Id
    /// @param identityId TokenId of the identity
    /// @return sbtNames Array of soul names associated to the identity Id
    function getSoulNames(uint256 identityId)
        external
        view
        override
        returns (string[] memory sbtNames)
    {
        // return owner if exists
        address _owner = soulboundIdentity.ownerOf(identityId);

        return getSoulNames(_owner);
    }

    /// @notice Returns all the active soul names of an account
    /// @dev This function queries all the identity names of the specified account
    /// @param owner Address of the owner of the identities
    /// @return sbtNames Array of soul names associated to the account
    function getSoulNames(address owner)
        public
        view
        override
        returns (string[] memory sbtNames)
    {
        uint256 results = 0;
        uint256 balance = balanceOf(owner);

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            if (tokenData[tokenId].expirationDate >= block.timestamp) {
                results = results.add(1);
            }
        }

        string[] memory _sbtNames = new string[](results);
        uint256 index = 0;

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            if (tokenData[tokenId].expirationDate >= block.timestamp) {
                _sbtNames[index] = Utils.toLowerCase(tokenData[tokenId].name);
                index = index.add(1);
            }
        }

        // return identity names if exists and are active
        return _sbtNames;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev This function returns the token URI of the soul name specified by the name
    /// @param name Name of the soul name
    /// @return URI of the soulname associated to a name
    function tokenURI(string memory name)
        external
        view
        virtual
        returns (string memory)
    {
        uint256 tokenId = _getTokenId(name);
        return tokenURI(tokenId);
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    /// @param tokenId NFT to get the URI of
    /// @return URI of the NFT
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _getName(string memory name) private view returns (string memory) {
        return string(bytes.concat(bytes(name), bytes(extension)));
    }

    function _getTokenId(string memory name) private view returns (uint256) {
        string memory lowercaseName = Utils.toLowerCase(name);
        if (!nameData[lowercaseName].exists) revert NameNotFound(name);

        return nameData[lowercaseName].tokenId;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        if (!_exists(tokenId)) revert TokenNotFound(tokenId);
        if (_URIs[_tokenURI]) revert URIAlreadyExists(_tokenURI);

        _tokenURIs[tokenId] = _tokenURI;
        _URIs[_tokenURI] = true;
    }

    /* ========== MODIFIERS ========== */

    /* ========== EVENTS ========== */

    event YearsPeriodRenewed(
        uint256 tokenId,
        uint256 yearsPeriod,
        uint256 newExpirationDate
    );
}