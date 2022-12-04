// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

///  ___
/// (  _`\
/// | |_) )  _ _   ___   ___    _ _    __     __
/// | ,__/'/'_` )/',__)/',__) /'_` ) /'_ `\ /'__`\
/// | |   ( (_| |\__, \\__, \( (_| |( (_) |(  ___/
/// (_)   `\__,_)(____/(____/`\__,_)`\__  |`\____)
///                                 ( )_) |
///                                  \___/'

/// @title Passage Passport v2
/// @notice Passport v2 ERC-721 Token

import "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

import "./PassageUtils.sol";
import "./lib/ERC2771Recipient.sol";
import "./lib/Ownable.sol";
import "./lib/PassageAccess.sol";

import "./interfaces/IPassport2.sol";
import "./interfaces/IPassageRegistry2.sol";
import "./interfaces/modules/render/IRenderModule.sol";
import "./interfaces/modules/beforeTransfer/I721BeforeTransfersModule.sol";
import "./interfaces/modules/minting/IMintingModule.sol";

contract Passport2 is
    ERC721ABurnableUpgradeable,
    ERC2981Upgradeable,
    PassageAccess,
    UUPSUpgradeable,
    ERC2771Recipient,
    Ownable,
    IPassport2
{
    using PassageUtils for address;

    IPassageRegistry2 public passageRegistry;
    IRenderModule public renderModule;
    I721BeforeTransfersModule public beforeTransfersModule;
    mapping(uint256 => IMintingModule) public mintingModules;

    string public uri;
    uint256 public maxSupply; // 0 is no max
    uint256 public initialTokenId;
    bool public versionLocked;
    bool public maxSupplyLocked;

    // ---- modifiers ----

    modifier onlyAuthorizedUpgrader() {
        if (isManaged()) {
            address registry = address(passageRegistry);
            require(registry == _msgSenderERC721A(), "T1");
        } else {
            _checkRole(UPGRADER_ROLE, _msgSenderERC721A());
        }
        _;
    }

    modifier versionLockRequired() {
        require(versionLocked == true, "T2");
        _;
    }

    modifier versionLockProhibited() {
        require(versionLocked == false, "T3");
        _;
    }

    modifier maxSupplyLockProhibited() {
        require(maxSupplyLocked == false, "T5");
        _;
    }

    modifier checkSupplyLimit(uint256 quantity) {
        if (maxSupply > 0) require(_totalMinted() + quantity <= maxSupply, "T17");
        _;
    }

    // ---- constructor/initializer ----

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer function for contract creation instead of constructor to support upgrades
    /// @dev Only intended to be called from the registry
    /// @param _creator The address of the original creator
    /// @param _tokenName The token name
    /// @param _tokenSymbol The token symbol
    /// @param _maxSupply Max supply of tokens
    /// @param _royaltyWallet The address of the wallet to designated to receive royalty payments
    /// @param _royaltyBasisPoints The number representing the basis points of royalty fees out of 10000 (e.g. 750 = 7.5% royalty)
    function initialize(
        address _creator,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        uint256 _initialTokenId,
        address _royaltyWallet,
        uint96 _royaltyBasisPoints
    ) public initializerERC721A initializer {
        initialTokenId = _initialTokenId;
        __ERC721A_init(_tokenName, _tokenSymbol);
        __ERC721ABurnable_init();
        __ERC2981_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setupRoles(_creator, _msgSenderERC721A());
        _setRoyalty(_royaltyWallet, _royaltyBasisPoints);

        passageRegistry = IPassageRegistry2(_msgSenderERC721A());
        maxSupply = _maxSupply;

        emit PassportInitialized(_msgSenderERC721A(), address(this), _tokenSymbol, _tokenName, _maxSupply);
    }

    // ---- public ----

    /// @notice Mint token(s) to caller
    /// @dev Must enable a minting module
    /// @param mintingModuleIndex uint256 Desired index of minting module
    /// @param tokenIds uint256[] Held token ID(s) of tokens to mint
    /// @param mintAmounts uint256[] Amount of tokens to mint for each held token
    /// @param proof bytes32[] proof for claimlist
    /// @param data bytes[] supplemental data
    function claim(
        uint256 mintingModuleIndex,
        uint256[] calldata tokenIds,
        uint256[] calldata mintAmounts,
        bytes32[] calldata proof,
        bytes calldata data
    ) external payable {
        IMintingModule mintingModule = mintingModules[mintingModuleIndex];
        require(address(mintingModule) != address(0), "T22");

        uint256 amount = mintingModule.canMint(_msgSenderERC721A(), msg.value, tokenIds, mintAmounts, proof, data);
        _mintLogic(_msgSenderERC721A(), amount);
    }

    /// @notice Returns if Passport is still managed in registry
    /// @return if Passport is still managed in registry
    function isManaged() public view returns (bool) {
        return address(passageRegistry) != address(0);
    }

    /// @notice Returns Passport implementation version
    /// @return version number
    function passportVersion() public pure virtual returns (uint256 version) {
        return 0;
    }

    /// @notice returns true if the given _address has UPGRADER_ROLE
    /// @param _address Address to check for UPGRADER_ROLE
    /// @return bool whether _address has UPGRADER_ROLE
    function hasUpgraderRole(address _address) public view override(IPassport2, PassageAccess) returns (bool) {
        return super.hasUpgraderRole(_address);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721AUpgradeable) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (address(renderModule) != address(0)) {
            return renderModule.tokenURI(tokenId);
        }

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, AccessControlUpgradeable, ERC2981Upgradeable, IPassport2)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(IPassport2).interfaceId;
    }

    function upgradeTo(address newImplementation) external override(UUPSUpgradeable, IPassport2) onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        override(UUPSUpgradeable, IPassport2)
        onlyProxy
    {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    // ---- permissioned ----

    /// @notice Allows MINTER role to mint a new token to any number of supplied addresses
    /// @param _addresses List of addresses
    /// @param _amounts List of respective mint amounts
    /// @return first token ID minted & last token ID minted. Mints are sequential from address provided in address input array
    function mintPassports(address[] calldata _addresses, uint256[] calldata _amounts)
        external
        onlyRole(MINTER_ROLE)
        returns (uint256, uint256)
    {
        uint256 startId = _nextTokenId();
        require(_addresses.length == _amounts.length, "T19");
        for (uint256 i = 0; i < _addresses.length; ) {
            _mintLogic(_addresses[i], _amounts[i]);
            unchecked {
                ++i;
            }
        }
        uint256 endId = _nextTokenId() - 1;
        return (startId, endId);
    }

    /// @notice Updates the royalty details to a new wallet address and percentage
    /// @param _royaltyWallet The address of the wallet to designated to receive royalty payments
    /// @param _royaltyBasisPoints The number representing the basis points of royalty fees out of 10000 (e.g. 750 = 7.5% royalty)
    function setRoyalty(address _royaltyWallet, uint96 _royaltyBasisPoints) external onlyRole(MANAGER_ROLE) {
        _setRoyalty(_royaltyWallet, _royaltyBasisPoints);
    }

    /// @notice Allows manager to set max supply of tokens
    /// @param _maxSupply New max supply of tokens
    function setMaxSupply(uint256 _maxSupply) external maxSupplyLockProhibited onlyRole(MANAGER_ROLE) {
        require(_maxSupply >= _totalMinted(), "T16");
        maxSupply = _maxSupply;

        emit MaxSupplyUpdated(maxSupply);
    }

    /// @notice Allows manager to set trusted forwarder for meta-transactions
    /// @param forwarder Address of trusted forwarder
    function setTrustedForwarder(address forwarder) external onlyRole(MANAGER_ROLE) {
        _setTrustedForwarder(forwarder);
    }

    /// @notice Allows manager to transfer eth from contract
    function withdraw() external onlyRole(MANAGER_ROLE) {
        uint256 value = address(this).balance;
        emit Withdraw(value, _msgSenderERC721A());
        (bool sent, ) = _msgSenderERC721A().call{value: value}("");
        require(sent, "T26");
    }

    /// @notice Allows admin to eject from Passage management & upgrade contract independently of the registry
    /// @dev This is a one-way operation, there is no way to become managed again
    function eject() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isManaged(), "T14");
        address registry = address(passageRegistry);
        revokeRole(DEFAULT_ADMIN_ROLE, registry);
        revokeRole(UPGRADER_ROLE, registry);
        if (bytes(uri).length == 0) {
            string memory addrStr = address(this).address2Str();
            string memory defaultUri = string(
                abi.encodePacked(passageRegistry.globalPassportBaseURI(), _toString(block.chainid), "/", addrStr, "/")
            );
            uri = defaultUri;
        }

        IPassageRegistry2 passageRegistryCache = passageRegistry;
        passageRegistry = IPassageRegistry2(address(0));
        passageRegistryCache.ejectPassport();
    }

    /// @notice Locks the maxSupply which prevents any future maxSupply updates
    /// @notice this is a one way operation and cannot be undone
    /// @notice the current version must be locked
    function lockMaxSupply() external maxSupplyLockProhibited versionLockRequired onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupplyLocked = true;

        emit MaxSupplyLocked();
    }

    /// @notice Locks the version of the contract preventing any future upgrades
    /// @notice this is a one way operation and cannot be undone
    function lockVersion() external versionLockProhibited onlyRole(DEFAULT_ADMIN_ROLE) {
        versionLocked = true;

        emit VersionLocked();
    }

    /// @notice Allows manager to set the ability to set a new base URI rather than use the Passport Global URI
    /// @param _uri Token base URI
    function setBaseURI(string memory _uri) external onlyRole(MANAGER_ROLE) {
        uri = _uri;

        emit BaseUriUpdated(_uri);
    }

    /// @notice Allows default admin to set the owner address
    /// @dev not used for access control, used by services that require a single owner account
    /// @param newOwner address of the new owner
    function setOwnership(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setOwnership(newOwner);
    }

    /// @notice Allows manager to set the render module
    /// @param _contractAddress address of the render module
    function setRenderModule(address _contractAddress) public onlyRole(MANAGER_ROLE) {
        _setRenderModule(_contractAddress);
    }

    /// @notice Allows manager to set the before transfer module
    /// @param _contractAddress address of the before transfer module
    function setBeforeTransfersModule(address _contractAddress) public onlyRole(MANAGER_ROLE) {
        _setBeforeTransfersModule(_contractAddress);
    }

    /// @notice Allows manager to set the minting module
    /// @param _index index of mintingModules to set
    /// @param _contractAddress address of the minting module
    function setMintingModule(uint256 _index, address _contractAddress) public onlyRole(MANAGER_ROLE) {
        _setMintingModule(_index, _contractAddress);
    }

    // ---- private ----

    function _setRoyalty(address _royaltyWallet, uint96 _royaltyBasisPoints) internal {
        _setDefaultRoyalty(_royaltyWallet, _royaltyBasisPoints);

        emit RoyaltyInfoSet(_royaltyWallet, _royaltyBasisPoints);
    }

    function _setBeforeTransfersModule(address _contractAddress) internal {
        beforeTransfersModule = I721BeforeTransfersModule(_contractAddress);

        emit BeforeTransferModuleSet(_contractAddress);
    }

    function _setRenderModule(address _contractAddress) internal {
        renderModule = IRenderModule(_contractAddress);

        emit RenderModuleSet(_contractAddress);
    }

    function _setMintingModule(uint256 _index, address _contractAddress) internal {
        IMintingModule mintingModule = IMintingModule(_contractAddress);

        mintingModules[_index] = mintingModule;

        emit MintingModuleAdded(_contractAddress, _index);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (address(beforeTransfersModule) != address(0)) {
            beforeTransfersModule.beforeTokenTransfers(_msgSenderERC721A(), from, to, startTokenId, quantity);
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _mintLogic(address _to, uint256 _amount) internal checkSupplyLimit(_amount) {
        _safeMint(_to, _amount);
    }

    function _msgSenderERC721A() internal view override returns (address) {
        return _msgSender();
    }

    function _setupRoles(address _creator, address _registry) internal {
        _grantRole(DEFAULT_ADMIN_ROLE, _creator);
        _grantRole(UPGRADER_ROLE, _registry);
        _grantRole(UPGRADER_ROLE, _creator);
        _grantRole(MANAGER_ROLE, _creator);
        _grantRole(MINTER_ROLE, _creator);
        _setOwnership(_creator);
    }

    function _baseURI() internal view override returns (string memory) {
        if (bytes(uri).length > 0) return uri; // custom URI has been set
        string memory addrStr = address(this).address2Str();
        return
            string(
                abi.encodePacked(passageRegistry.globalPassportBaseURI(), _toString(block.chainid), "/", addrStr, "/")
            );
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAuthorizedUpgrader
        versionLockProhibited
    {}

    function _msgSender() internal view virtual override(BaseRelayRecipient, ContextUpgradeable) returns (address) {
        return BaseRelayRecipient._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(BaseRelayRecipient, ContextUpgradeable)
        returns (bytes calldata)
    {
        return BaseRelayRecipient._msgData();
    }

    function _startTokenId() internal view override(ERC721AUpgradeable) returns (uint256) {
        return initialTokenId;
    }
}