// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./interfaces/ILoyaltyLedger2.sol";
import "./interfaces/IPassageRegistry2.sol";
import "./lib/ERC2771Recipient.sol";
import "./interfaces/IPassport2.sol";

///  ___
/// (  _`\
/// | |_) )  _ _   ___   ___    _ _    __     __
/// | ,__/'/'_` )/',__)/',__) /'_` ) /'_ `\ /'__`\
/// | |   ( (_| |\__, \\__, \( (_| |( (_) |(  ___/
/// (_)   `\__,_)(____/(____/`\__,_)`\__  |`\____)
///                                 ( )_) |
///                                  \___/'

/// @title Passage Registry v2
/// @notice The registry facilitates creation of v2 Passports and v2 Loyalty Ledgers

contract PassageRegistry2 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ERC2771Recipient,
    IPassageRegistry2
{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    string public globalPassportBaseURI;
    string public globalLoyaltyBaseURI;

    // version -> implementation
    address[] public passportImplementations;
    address[] public loyaltyImplementations;

    // keep track of deployed contracts to ensure that callers are all deployed by passage
    mapping(address => bool) public managedPassports;
    mapping(address => bool) public managedLoyaltyLedgers;

    modifier onlyFromManagedPassport() {
        require(managedPassports[_msgSender()], "R1");
        _;
    }

    modifier onlyFromManagedLoyaltyLedger() {
        require(managedLoyaltyLedgers[_msgSender()], "R2");
        _;
    }

    // ---- constructor/initializer ----

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Initializer function for contract creation instead of constructor to support upgrades
    /// @param _globalPassportBaseURI The global base URI for Passports
    /// @param _globalLoyaltyBaseURI The global base URI for Loyalty Ledgers
    function initialize(string calldata _globalPassportBaseURI, string calldata _globalLoyaltyBaseURI)
        external
        initializer
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());

        globalPassportBaseURI = _globalPassportBaseURI;
        globalLoyaltyBaseURI = _globalLoyaltyBaseURI;
        emit PassportBaseUriUpdated(_globalPassportBaseURI);
        emit LoyaltyBaseUriUpdated(_globalLoyaltyBaseURI);
    }

    // ---- public ----

    /// @notice Get the index of the latest passport implementation added
    /// @return latestVersion index of the latest passport implementation added
    function passportLatestVersion() public view returns (uint256) {
        return passportImplementations.length - 1;
    }

    /// @notice Get the index of the latest loyalty ledger implementation added
    /// @return latestVersion index of the latest loyalty ledger implementation added
    function loyaltyLatestVersion() public view returns (uint256) {
        return loyaltyImplementations.length - 1;
    }

    // ---- passport functions ----

    /// @notice Creates a new Passport
    /// @dev a convenience function for createPassport(bytes memory data)
    /// @param _tokenName The token name
    /// @param _tokenSymbol The token symbol
    /// @param _maxSupply Max supply of tokens
    /// @param _startTokenId Token Id to use for first mint
    /// @param _royaltyWallet The address of the wallet to designated to receive royalty payments
    /// @param _royaltyBasisPoints The number representing the basis points of royalty fees out of 10000 (e.g. 750 = 7.5% royalty)
    function createPassport(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        uint256 _maxSupply,
        uint256 _startTokenId,
        address _royaltyWallet,
        uint96 _royaltyBasisPoints
    ) external returns (address passportAddress) {
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,string,string,uint256,uint256,address,uint96)",
            _msgSender(),
            _tokenName,
            _tokenSymbol,
            _maxSupply,
            _startTokenId,
            _royaltyWallet,
            _royaltyBasisPoints
        );
        return createPassport(data);
    }

    /// @notice Creates a new Passport
    /// @param data The encoded function data for the Passport initialize function
    /// @return passportAddress The created Passport contract address
    function createPassport(bytes memory data) public returns (address passportAddress) {
        ERC1967Proxy proxy = new ERC1967Proxy(passportImplementations[passportLatestVersion()], data);
        managedPassports[address(proxy)] = true;
        emit PassportCreated(address(proxy));
        return address(proxy);
    }

    /// @notice Upgrades a deployed Passport to new implementation
    /// @dev Can only upgrade 1 version at a time & caller must have UPGRADER role on Passport
    /// @param version The version to upgrade to
    /// @param passportAddress The address of the Passport to upgrade
    /// @return newVersion The new implementation version of the Passport
    function upgradePassport(uint256 version, address passportAddress) external returns (uint256 newVersion) {
        IPassport2 passport = IPassport2(passportAddress);
        require(managedPassports[passportAddress], "R3");
        require(passport.hasUpgraderRole(_msgSender()), "R4");

        uint256 currentVersion = passport.passportVersion();
        require(version == currentVersion + 1, "R5");
        require(version <= passportLatestVersion(), "R6");
        address upgradeAddress = passportImplementations[version];

        emit PassportVersionUpgraded(passportAddress, version);
        passport.upgradeTo(upgradeAddress);

        return currentVersion + 1;
    }

    // ---- loyalty ledger functions ----

    /// @notice Creates a new Loyalty Ledger
    /// @dev a convenience function for createLoyalty(bytes memory data)
    /// @param _royaltyWallet The address of the wallet to designated to receive royalty payments
    /// @param _royaltyBasisPoints The number representing the basis points of royalty fees out of 10000 (e.g. 750 = 7.5% royalty)
    /// @return loyaltyAddress The created Loyalty Ledger contract address
    function createLoyalty(address _royaltyWallet, uint96 _royaltyBasisPoints)
        external
        returns (address loyaltyAddress)
    {
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,address,uint96)",
            _msgSender(),
            _royaltyWallet,
            _royaltyBasisPoints
        );
        return createLoyalty(data);
    }

    /// @notice Creates a new Loyalty Ledger
    /// @param data The encoded function data for the Loyalty Ledger initialize function
    /// @return loyaltyAddress The created Loyalty Ledger contract address
    function createLoyalty(bytes memory data) public returns (address loyaltyAddress) {
        ERC1967Proxy proxy = new ERC1967Proxy(loyaltyImplementations[loyaltyLatestVersion()], data);
        managedLoyaltyLedgers[address(proxy)] = true;
        emit LoyaltyCreated(address(proxy));
        return address(proxy);
    }

    /// @notice Upgrades a deployed Passport to new implementation
    /// @dev Can only upgrade 1 version at a time & caller must have UPGRADER role on Loyalty Ledger
    /// @param version The version to upgrade to
    /// @param loyaltyAddress The address of the Loyalty Ledger to upgrade
    /// @return newVersion The new implementation version of the Passport
    function upgradeLoyalty(uint256 version, address loyaltyAddress) external returns (uint256 newVersion) {
        ILoyaltyLedger2 ll = ILoyaltyLedger2(loyaltyAddress);
        require(managedLoyaltyLedgers[loyaltyAddress], "R3");
        require(ll.hasUpgraderRole(_msgSender()), "R4");
        uint256 currentVersion = ll.loyaltyLedgerVersion();

        require(version == currentVersion + 1, "R5");
        require(version <= loyaltyLatestVersion(), "R6");
        address upgradeAddress = loyaltyImplementations[version];

        emit LoyaltyVersionUpgraded(loyaltyAddress, version);
        ll.upgradeTo(upgradeAddress);

        return currentVersion + 1;
    }

    // ---- admin ----

    /// @notice Allows manager to add a new Passport implementation
    /// @param implementation Address of the implementation
    function addPassportImplementation(address implementation) external onlyRole(MANAGER_ROLE) {
        require(IPassport2(implementation).supportsInterface(type(IPassport2).interfaceId), "R7");
        require(IPassport2(implementation).passportVersion() == passportImplementations.length, "R7");

        passportImplementations.push(implementation);

        emit PassportImplementationAdded(passportImplementations.length - 1, implementation);
    }

    /// @notice Allows manager to add a new Loyalty Ledger implementation
    /// @param implementation Address of the implementation
    function addLoyaltyImplementation(address implementation) external onlyRole(MANAGER_ROLE) {
        require(ILoyaltyLedger2(implementation).supportsInterface(type(ILoyaltyLedger2).interfaceId), "R8");
        require(ILoyaltyLedger2(implementation).loyaltyLedgerVersion() == loyaltyImplementations.length, "R8");

        loyaltyImplementations.push(implementation);

        emit LoyaltyLedgerImplementationAdded(loyaltyImplementations.length - 1, implementation);
    }

    /// @notice Removes Loyalty Ledger from managed list
    /// @dev Only callable from managed Loyalty Ledger
    function ejectLoyaltyLedger() external onlyFromManagedLoyaltyLedger {
        managedLoyaltyLedgers[_msgSender()] = false;

        emit LoyaltyLedgerEjected(_msgSender());
    }

    /// @notice Removes Passport from managed list
    /// @dev Only callable from managed Passport
    function ejectPassport() external onlyFromManagedPassport {
        managedPassports[_msgSender()] = false;

        emit PassportEjected(_msgSender());
    }

    /// @notice Allows manager to set new global Passport URI
    /// @param _uri New global Passport URI
    function setGlobalPassportBaseURI(string calldata _uri) external onlyRole(MANAGER_ROLE) {
        globalPassportBaseURI = _uri;
        emit PassportBaseUriUpdated(_uri);
    }

    /// @notice Allows manager to set new global Loyalty Ledger URI
    /// @param _uri New global Loyalty Ledger URI
    function setGlobalLoyaltyBaseURI(string calldata _uri) external onlyRole(MANAGER_ROLE) {
        globalLoyaltyBaseURI = _uri;
        emit LoyaltyBaseUriUpdated(_uri);
    }

    /// @notice Allows manager to set new trusted forwarder for meta-transactions
    /// @param forwarder Address of trusted forwarder
    function setTrustedForwarder(address forwarder) external onlyRole(MANAGER_ROLE) {
        _setTrustedForwarder(forwarder);
    }

    /// @notice Allows manager to upgrade contract
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(MANAGER_ROLE) {}

    // ---- meta txs ----

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
}