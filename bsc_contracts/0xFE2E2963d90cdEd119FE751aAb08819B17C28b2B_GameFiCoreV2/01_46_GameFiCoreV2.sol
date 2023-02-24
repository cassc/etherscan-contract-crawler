/*

 ██████╗   █████╗  ███╗   ███╗ ███████╗ ███████╗ ██╗      ██████╗  ██████╗  ██████╗  ███████╗
██╔════╝  ██╔══██╗ ████╗ ████║ ██╔════╝ ██╔════╝ ██║     ██╔════╝ ██╔═══██╗ ██╔══██╗ ██╔════╝
██║  ███╗ ███████║ ██╔████╔██║ █████╗   █████╗   ██║     ██║      ██║   ██║ ██████╔╝ █████╗  
██║   ██║ ██╔══██║ ██║╚██╔╝██║ ██╔══╝   ██╔══╝   ██║     ██║      ██║   ██║ ██╔══██╗ ██╔══╝  
╚██████╔╝ ██║  ██║ ██║ ╚═╝ ██║ ███████╗ ██║      ██║     ╚██████╗ ╚██████╔╝ ██║  ██║ ███████╗
 ╚═════╝  ╚═╝  ╚═╝ ╚═╝     ╚═╝ ╚══════╝ ╚═╝      ╚═╝      ╚═════╝  ╚═════╝  ╚═╝  ╚═╝ ╚══════╝

*/
// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;
// solhint-disable not-rely-on-time

// inheritance list
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "./token/lib/BaseCore.sol";
import "../lib/TokenHelper.sol";
import "../interface/other/ITokenWithdraw.sol";
import "../interface/core/IGameFiCoreV2.sol";

// libs
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

// interfaces
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "../interface/core/IGameFiProfileVaultV2.sol";
import "../interface/core/token/basic/IGameFiTokenERC20.sol";
import "../interface/core/token/basic/IGameFiTokenERC721.sol";
import "../interface/core/token/basic/IGameFiTokenERC1155.sol";

/**
 * @author Alex Kaufmann
 * @dev Main GameFi infrastructure contract.
 * This contract is a collection contract factory.
 * Implements a system of game profiles through erc721 tokens.
 *
 * All methods are divided into 7 categories:
 *
 * "AccessControl" (IAccessControlUpgradeable) - role-based access control
 *
 * "ERC721" (IERC721, etc.) - profile management by users
 *
 * "Profile" (IProfileV2) - profile management by owners
 *
 * "Property" (IPropertyV2) - profile properties
 *
 * "Collection" (ICollectionV2) - collection management, allows you to create tokens
 *
 * "Token" (ITokenV2) - mint/burn token functions
 *
 * "Gas Station Network" (ITrustedForwarder) - GSN protocol supporting
 */
contract GameFiCoreV2 is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    BaseRelayRecipient,
    BaseCore,
    TokenHelper,
    ITokenWithdraw,
    IGameFiCoreV2
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address internal _profileVaultImpl;

    mapping(uint256 => address) internal _profileIdToVault;
    mapping(address => uint256) internal _profileVaultToId;
    mapping(uint256 => bool) internal _profileIsLocked;

    mapping(uint256 => Property) internal _property;
    CountersUpgradeable.Counter internal _totalProperties;
    mapping(uint256 => mapping(uint256 => bytes32)) internal _propertyValueOf;

    CountersUpgradeable.Counter internal _totalCollections;
    mapping(uint256 => Collection) internal _collection;

    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _;
    }

    modifier onlyAdminOrOperator() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(OPERATOR_ROLE, _msgSender()),
            "GameFiCoreV2: caller is not the admin/operator"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Constructor method (https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers).
     * @param name_ erc721 name() field (see ERC721Metadata).
     * @param symbol_ erc721 symbol() field (see ERC721Metadata).
     * @param baseURI_ erc721 token base uri.
     * @param profileVaultImpl_ address with implementation code of profile vault smart contract.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        address profileVaultImpl_
    ) external override initializer {
        require(profileVaultImpl_ != address(0));

        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
        __BaseCore_init(string(abi.encodePacked(name_, " profile")), symbol_, baseURI_);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _profileVaultImpl = profileVaultImpl_;
    }

    /**
     * @dev Method for better version control.
     * Takes hash from gameficore code.
     * @return four-byte version signature.
     */
    function versionHash() external view override returns (bytes4) {
        // check proxy pattern (eip1967)
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        address implAddress = StorageSlotUpgradeable.getAddressSlot(implementationSlot).value;

        // if not proxy
        if (implAddress == address(0)) {
            implAddress = address(this);
        }

        return (bytes4(keccak256(implAddress.code)));
    }

    /**
     * @dev Withdraw the specified token, only for admins.
     * @param standart Token standart.
     * @param token Token for withdrawal.
     */
    function withdrawToken(TokenStandart standart, TransferredToken memory token)
        external
        override
        onlyAdmin
        nonReentrant
    {
        _tokenTransfer(standart, token, _msgSender());

        emit WithdrawToken({sender: _msgSender(), standart: standart, token: token, timestamp: block.timestamp});
    }

    /**
     * @dev Returns true if 'target' has 'admin' role.
     * @return Bool flag.
     */
    function isAdmin(address target) external view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, target);
    }

    /**
     * @dev Returns true if 'target' has 'operator' role.
     * @return Bool flag.
     */
    function isOperator(address target) external view override returns (bool) {
        return hasRole(OPERATOR_ROLE, target);
    }

    //
    // Profile
    //

    /**
     * @dev Sets erc721 base URI, only for admins
     * @param newBaseURI token standart
     */
    function setBaseURI(string memory newBaseURI) external override onlyAdmin {
        _setBaseURI(newBaseURI);

        emit SetBaseURI({sender: _msgSender(), newBaseURI: newBaseURI, timestamp: block.timestamp});
    }

    /**
     * @dev Create new profile erc721 token and deploy profile vault.
     * @param targetWallet Where to move the created token.
     * @param salt Random non-repeating number, only needed to calculate the address.
     * @return profileId New profile id.
     * @return profileVault Profile Vault smart contract.
     */
    function mintProfile(address targetWallet, uint256 salt)
        external
        override
        nonReentrant
        returns (uint256 profileId, address profileVault)
    {
        uint256 newProfileId = _mintProfileToken(_msgSender());
        address newProfileVault = ClonesUpgradeable.cloneDeterministic(_profileVaultImpl, bytes32(salt));
        IGameFiProfileVaultV2(newProfileVault).initialize(address(this));

        _profileIdToVault[newProfileId] = newProfileVault;
        _profileVaultToId[newProfileVault] = newProfileId;

        emit MintProfile({
            sender: _msgSender(),
            targetWallet: targetWallet,
            profileId: newProfileId,
            profileVault: newProfileVault,
            salt: salt,
            timestamp: block.timestamp
        });

        return (newProfileId, newProfileVault);
    }

    /**
     * @dev Lock a profile so game operators can manage the tokens and properties of that profile
     * @param profileId Profile ID (equivalent to tokenId).
     */
    function lockProfile(uint256 profileId) external override {
        _checkProfileById(profileId);
        _checkIsNotLocked(profileId);
        _checkOwnerOf(_msgSender(), profileId);

        _profileIsLocked[profileId] = true;

        emit LockProfile({sender: _msgSender(), profileId: profileId, timestamp: block.timestamp});
    }

    /**
     * @dev Unlock a profile to give control of the profile to the user. Only for admins/operators.
     * @param profileId Profile ID (equivalent to tokenId).
     */
    function unlockProfile(uint256 profileId) external override {
        // TODO add onlyAdminOrOperator
        _checkProfileById(profileId);
        _checkIsLocked(profileId);
        _checkOwnerOf(_msgSender(), profileId);

        _profileIsLocked[profileId] = false;

        emit UnlockProfile({
            sender: _msgSender(),
            profileOwner: ownerOf(profileId),
            profileId: profileId,
            timestamp: block.timestamp
        });
    }

    /**
     * @dev Converts profile id (token id) to profile vault contract address.
     * @return Profile vault contract address.
     */
    function profileIdToVault(uint256 profileId) external view override returns (address) {
        _checkProfileById(profileId);
        return (_profileIdToVault[profileId]);
    }

    /**
     * @dev Converts profile vault contract address to profile id (token id).
     * @return Profile id (token id).
     */
    function profileVaultToId(address profileAddress) external view override returns (uint256) {
        require(profileAddress != address(0), "GameFiCoreV2: zero profile address");
        uint256 profileId = _profileVaultToId[profileAddress];
        _checkProfileById(profileId);
        require(_profileIdToVault[profileId] == profileAddress, "GameFiCoreV2: nonexistent profile");
        return profileId;
    }

    /**
     * @dev Returns true if profile is locked.
     * @return Bool flag.
     */
    function profileIsLocked(uint256 profileId) external view override returns (bool) {
        _checkProfileById(profileId);
        return (_profileIsLocked[profileId]);
    }

    /**
     * @dev Returns vault implementation contract.
     * @return vault implementation address.
     */
    function profileVaultImpl() external view override returns (address) {
        return _profileVaultImpl;
    }

    //
    // Property
    //

    /**
     * @dev Create a new property. Only for admins.
     * @param propertySettings Property settings.
     * @return propertyId created property.
     */
    function createProperty(Property memory propertySettings) external override onlyAdmin returns (uint256 propertyId) {
        propertyId = _totalProperties.current();

        emit CreateProperty({
            sender: _msgSender(),
            propertyId: propertyId,
            propertySettings: propertySettings,
            timestamp: block.timestamp
        });

        _property[propertyId] = propertySettings;

        _totalProperties.increment();

        return propertyId;
    }

    /**
     * @dev Create a new property. Only for admins.
     * @param propertyId Target property id.
     * @param propertySettings New property settings.
     */
    function editProperty(uint256 propertyId, Property memory propertySettings) external override onlyAdmin {
        _checkProperty(propertyId);

        emit EditProperty({
            sender: _msgSender(),
            propertyId: propertyId,
            propertySettings: propertySettings,
            timestamp: block.timestamp
        });

        _property[propertyId] = propertySettings;
    }

    /**
     * @dev Set the property value for the user profile. Profile must be locked.
     * @param profileId Target user profile.
     * @param propertyId Target property id.
     * @param newValue Hex-encoded value to set.
     * @param signature Legacy parameter, don't use
     */
    function setPropertyValue(
        uint256 profileId,
        uint256 propertyId,
        bytes32 newValue,
        bytes memory signature
    ) external override {
        _checkProfileById(profileId);
        _checkProperty(propertyId);
        Property memory targetProperty = _property[propertyId];
        require(targetProperty.isActive, "GameFiCoreV2: inactive property");

        if (targetProperty.accessType == PropertyAccessType.OPERATOR_ONLY) {
            _checkRole(OPERATOR_ROLE, _msgSender());
            _checkIsLocked(profileId);
        } else if (targetProperty.accessType == PropertyAccessType.WALLET_ONLY) {
            _checkOwnerOf(_msgSender(), profileId);
            _checkIsNotLocked(profileId);
        } else if (targetProperty.accessType == PropertyAccessType.MIXED) {
            // not implemented
            revert();
        }

        if (targetProperty.feeTokenStandart != TokenStandart.NULL) {
            _tokenTransferFrom(targetProperty.feeTokenStandart, targetProperty.feeToken, _msgSender(), address(this));
        }

        _propertyValueOf[profileId][propertyId] = newValue;

        emit SetPropertyValue({
            sender: _msgSender(),
            profileId: profileId,
            propertyId: propertyId,
            newValue: newValue,
            signature: signature,
            timestamp: block.timestamp
        });
    }

    /**
     * @dev Returns Property struct.
     * @return Property details.
     */
    function propertyDetails(uint256 propertyId) external view returns (Property memory) {
        _checkProperty(propertyId);
        return (_property[propertyId]);
    }

    /**
     * @dev Returns property value for specific profile.
     * @return Property value data (bytes32 hex).
     */
    function getPropertyValue(uint256 profileId, uint256 propertyId) external view override returns (bytes32) {
        _checkProfileById(profileId);
        _checkProperty(propertyId);

        return (_propertyValueOf[profileId][propertyId]);
    }

    /**
     * @dev Returns number of properties.
     * @return Number of properties.
     */
    function totalProperties() external view override returns (uint256) {
        return (_totalProperties.current());
    }

    //
    // Сollection
    //

    /**
     * @dev Create new token smart contract.
     * @param tokenStandart New token standart.
     * @param implementation Address with implementation code of profile storage smart contract.
     * @param salt Random non-repeating number, only needed to calculate the address.
     * @param name_ Token name() field (see token metadata extensions).
     * @param symbol_ Token symbol() field (see  tokenmetadata extensions).
     * @param contractURI_ contract-level metadata (see https://docs.opensea.io/docs/contract-level-metadata).
     * @param tokenURI_ Token metadata URI (see token metadata extensions).
     * @param data Custom hex-data for additional parameters. Depends on the implementation of the token.
     * Is empty by default.
     */
    function createCollection(
        TokenStandart tokenStandart,
        address implementation,
        uint256 salt,
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory tokenURI_,
        bytes memory data
    ) external override onlyAdmin nonReentrant returns (address) {
        _tokenStandartValidation(tokenStandart);
        uint256 id = _totalCollections.current();
        address collectionInstance = ClonesUpgradeable.cloneDeterministic(implementation, bytes32(salt));

        _collection[id] = Collection({
            tokenStandart: tokenStandart,
            implementation: implementation,
            tokenContract: collectionInstance,
            isActive: true
        });

        _totalCollections.increment();

        if (tokenStandart == TokenStandart.ERC20) {
            IGameFiTokenERC20(collectionInstance).initialize(name_, symbol_, contractURI_, data);
            _checkSupportsInterface(collectionInstance, type(IGameFiTokenERC20).interfaceId);
        } else if (tokenStandart == TokenStandart.ERC721) {
            IGameFiTokenERC721(collectionInstance).initialize(name_, symbol_, contractURI_, tokenURI_, data);
            _checkSupportsInterface(collectionInstance, type(IGameFiTokenERC721).interfaceId);
        } else {
            IGameFiTokenERC1155(collectionInstance).initialize(name_, symbol_, contractURI_, tokenURI_, data);
            _checkSupportsInterface(collectionInstance, type(IGameFiTokenERC1155).interfaceId);
        }

        emit CreateCollection({
            sender: _msgSender(),
            collectionId: id,
            collection: _collection[id],
            implementation: implementation,
            salt: salt,
            name: name_,
            symbol: symbol_,
            contractURI: contractURI_,
            tokenURI: tokenURI_,
            data: data,
            timestamp: block.timestamp
        });

        return collectionInstance;
    }

    function setCollectionActivity(uint256 collectionId, bool isActive) external onlyAdmin {
        _checkCollectionExistense(collectionId);

        emit SetCollectionActivity({
            sender: _msgSender(),
            collectionId: collectionId,
            newStatus: isActive,
            timestamp: block.timestamp
        });

        _collection[collectionId].isActive = isActive;
    }

    /**
     * @dev Call token (collection) smart contract method on behalf of gameficore.
     * @param collectionId Target collection Id.
     * @param data ABI-encoded calldata.
     * @return result Call returns.
     */
    function callToCollection(uint256[] memory collectionId, bytes[] memory data)
        external
        override
        onlyAdmin
        nonReentrant
        returns (bytes[] memory result)
    {
        require(collectionId.length == data.length);
        result = new bytes[](collectionId.length);
        for (uint256 i = 0; i < collectionId.length; i++) {
            _checkCollectionExistense(collectionId[i]);
            result[i] = AddressUpgradeable.functionCall(_collection[collectionId[i]].tokenContract, data[i]);
        }
    }

    /**
     * @dev Returns Collection struct.
     * @return Collection details.
     */
    function collectionDetails(uint256 collectionId) external view override returns (Collection memory) {
        _checkCollectionExistense(collectionId);
        return (_collection[collectionId]);
    }

    /**
     * @dev Returns number of collections.
     * @return Number of collections.
     */
    function totalCollections() external view override returns (uint256) {
        return (_totalCollections.current());
    }

    //
    // Token
    //

    /**
     * @dev Mint tokens to profile vault. Only for locked profiles.
     * @param collectionToken Target token.
     * @param profileId Profile ID (equivalent to tokenId).
     * @param data Custom hex-data for additional parameters. Depends on the implementation of the token.
     * Is empty by default.
     */
    function mintTokenToProfile(
        CollectionToken memory collectionToken,
        uint256 profileId,
        bytes memory data
    ) external override onlyAdminOrOperator nonReentrant {
        _checkCollectionExistense(collectionToken.collectionId);
        _checkCollectionActivity(collectionToken.collectionId);
        _checkProfileById(profileId);
        _checkIsLocked(profileId);

        address profileAddress = _profileIdToVault[profileId];

        _mintToken(collectionToken, profileAddress, data);

        emit MintTokenToProfile({
            sender: _msgSender(),
            collectionToken: collectionToken,
            profileId: profileId,
            data: data,
            timestamp: block.timestamp
        });
    }

    /**
     * @dev Burn tokens from profile vault. Only for locked profiles.
     * @param collectionToken Target token.
     * @param profileId Profile ID (equivalent to tokenId).
     * @param data Custom hex-data for additional parameters. Depends on the implementation of the token.
     * Is empty by default.
     */
    function burnTokenFromProfile(
        CollectionToken memory collectionToken,
        uint256 profileId,
        bytes memory data
    ) external override onlyAdminOrOperator nonReentrant {
        _checkCollectionExistense(collectionToken.collectionId);
        _checkCollectionActivity(collectionToken.collectionId);
        _checkProfileById(profileId);
        _checkIsLocked(profileId);

        address profileAddress = _profileIdToVault[profileId];

        _burnToken(collectionToken, profileAddress, data);

        emit BurnTokenFromProfile({
            sender: _msgSender(),
            collectionToken: collectionToken,
            profileId: profileId,
            data: data,
            timestamp: block.timestamp
        });
    }

    /**
     * @dev Mint tokens to some address.
     * @param collectionToken Target token.
     * @param targetWallet Where to mint tokens.
     * @param data Custom hex-data for additional parameters. Depends on the implementation of the token.
     * Is empty by default.
     */
    function mintTokenToWallet(
        CollectionToken memory collectionToken,
        address targetWallet,
        bytes memory data
    ) external override onlyAdminOrOperator nonReentrant {
        require(targetWallet != address(0), "GameFiCoreV2: zero wallet");
        _checkCollectionExistense(collectionToken.collectionId);
        _checkCollectionActivity(collectionToken.collectionId);

        _mintToken(collectionToken, targetWallet, data);

        emit MintTokenToWallet({
            sender: _msgSender(),
            collectionToken: collectionToken,
            targetWallet: targetWallet,
            data: data,
            timestamp: block.timestamp
        });
    }

    //
    // Other
    //

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(BaseCore, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IGameFiCoreV2).interfaceId || super.supportsInterface(interfaceId);
    }

    //
    // Internal methods
    //

    function _mintToken(
        CollectionToken memory collectionToken,
        address target,
        bytes memory data
    ) internal {
        Collection memory collection = _collection[collectionToken.collectionId];
        TransferredToken memory token = TransferredToken(
            collection.tokenContract,
            collectionToken.tokenId,
            collectionToken.amount
        );

        _tokenStandartValidation(collection.tokenStandart);
        if (collection.tokenStandart == TokenStandart.ERC20) {
            _erc20Validation(token);
            IGameFiTokenERC20(token.tokenContract).mint(target, token.amount, data);
        } else if (collection.tokenStandart == TokenStandart.ERC721) {
            _erc721Validation(token);
            IGameFiTokenERC721(token.tokenContract).mint(target, data);
        } else {
            _erc1155Validation(token);
            IGameFiTokenERC1155(token.tokenContract).mint(target, token.tokenId, token.amount, data);
        }
    }

    function _burnToken(
        CollectionToken memory collectionToken,
        address target,
        bytes memory data
    ) internal {
        Collection memory collection = _collection[collectionToken.collectionId];
        TransferredToken memory token = TransferredToken(
            collection.tokenContract,
            collectionToken.tokenId,
            collectionToken.amount
        );

        _tokenStandartValidation(collection.tokenStandart);
        if (collection.tokenStandart == TokenStandart.ERC20) {
            _erc20Validation(token);
            IGameFiTokenERC20(token.tokenContract).burn(target, token.amount, data);
        } else if (collection.tokenStandart == TokenStandart.ERC721) {
            _erc721Validation(token);
            require(
                IERC721Upgradeable(token.tokenContract).ownerOf(token.tokenId) == target,
                "GameFiCoreV2: wrong token owner"
            );
            IGameFiTokenERC20(token.tokenContract).burn(target, token.amount, data);
        } else {
            _erc1155Validation(token);
            IGameFiTokenERC1155(token.tokenContract).burn(target, token.tokenId, token.amount, data);
        }
    }

    function _checkProfileById(uint256 profileId) internal view {
        require(_exists(profileId), "GameFiCoreV2: nonexistent profile");
    }

    function _checkIsLocked(uint256 profileId) internal view {
        require(_profileIsLocked[profileId], "GameFiCoreV2: only for locked profile");
    }

    function _checkIsNotLocked(uint256 profileId) internal view {
        require(!_profileIsLocked[profileId], "GameFiCoreV2: only for unlocked profile");
    }

    function _checkProperty(uint256 propertyId) internal view {
        require(propertyId < _totalProperties.current(), "GameFiCoreV2: nonexistent property");
    }

    function _checkCollectionExistense(uint256 collectionId) internal view {
        require(collectionId < _totalCollections.current(), "GameFiCoreV2: nonexistent collection");
    }

    function _checkCollectionActivity(uint256 collectionId) internal view {
        require(_collection[collectionId].isActive, "GameFiCoreV2: inactive collection");
    }

    function _checkOwnerOf(address target, uint256 profileId) internal view {
        require(target == ownerOf(profileId), "GameFiCoreV2: only for profile owner");
    }

    function _checkSupportsInterface(address target, bytes4 interfaceId) internal view {
        require(IERC165Upgradeable(target).supportsInterface(interfaceId), "GameFiCoreV2: unsupported interface");
    }

    //
    // Hooks
    //

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(BaseCore) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    //
    // GSN
    //

    /**
     * @dev Sets trusted forwarder contract (see https://docs.opengsn.org/).
     * @param newTrustedForwarder New trusted forwarder contract.
     */
    function setTrustedForwarder(address newTrustedForwarder) external override onlyAdmin {
        _setTrustedForwarder(newTrustedForwarder);
    }

    /**
     * @dev Returns recipient version of the GSN protocol (see https://docs.opengsn.org/).
     * @return Version string in SemVer.
     */
    function versionRecipient() external pure override returns (string memory) {
        return "1.0.0";
    }

    function _msgSender() internal view override(ContextUpgradeable, BaseRelayRecipient) returns (address) {
        return BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, BaseRelayRecipient) returns (bytes calldata) {
        return BaseRelayRecipient._msgData();
    }
}