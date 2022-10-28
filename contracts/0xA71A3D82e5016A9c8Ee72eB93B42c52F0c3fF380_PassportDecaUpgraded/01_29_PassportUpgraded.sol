// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./PassageUtils.sol";
import "./interfaces/IPassageRegistry.sol";
import "./interfaces/IPassport.sol";
import "./lib/ERC2771Recipient.sol";
import "./lib/Ownable.sol";
import "./lib/PassageAccess.sol";

///  ___
/// (  _`\
/// | |_) )  _ _   ___   ___    _ _    __     __
/// | ,__/'/'_` )/',__)/',__) /'_` ) /'_ `\ /'__`\
/// | |   ( (_| |\__, \\__, \( (_| |( (_) |(  ___/
/// (_)   `\__,_)(____/(____/`\__,_)`\__  |`\____)
///                                 ( )_) |
///                                  \___/'

/// @title Passage Passport
/// @notice Passport ERC-721 Token

contract PassportDecaUpgraded is
  ERC721BurnableUpgradeable,
  PassageAccess,
  UUPSUpgradeable,
  ERC2771Recipient,
  Ownable,
  IPassport
{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using PassageUtils for address;

  IPassageRegistry public passageRegistry;

  CountersUpgradeable.Counter private _tokenIdCounter;

  string public uri;
  bool public transferEnabled;
  bool public claimEnabled;
  bool public claimlistClaimEnabled;
  bool public versionLocked;
  bool public maxSupplyLocked;
  bool public transferEnabledLocked;
  uint256 public maxSupply; // 0 is no max
  uint256 public claimFee; // 0 is no fee
  uint256 public claimAmount;
  uint256 public claimlistClaimFee; // 0 is no fee
  bytes32 public claimlistRoot;
  mapping(address => bool) public claimlistClaimed; // claimlist address -> claimed

  // new storage values (must be appended to end)
  IDecagonBeforeTransferContract public beforeTransferContract; // default value 0x0000000000000000000000000000000000000000

  modifier onlyAuthorizedUpgrader() {
    if (isManaged()) {
      address registry = address(passageRegistry);
      require(registry == _msgSender(), "T1");
    } else {
      _checkRole(UPGRADER_ROLE, _msgSender());
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

  // ---- constructor/initializer ----

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  /// @notice Initializer function for contract creation instead of constructor to support upgrades
  /// @dev Only intended to be called from the registry
  /// @param _creator The address of the original creator
  /// @param _tokenName The token name
  /// @param _tokenSymbol The token symbol
  /// @param _transferEnabled If transfer enabled
  /// @param _maxSupply Max supply of tokens
  function initialize(
    address _creator,
    string calldata _tokenName,
    string calldata _tokenSymbol,
    bool _transferEnabled,
    uint256 _maxSupply
  ) external initializer {
    __ERC721_init(_tokenName, _tokenSymbol);
    __ERC721Burnable_init();
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _setupRoles(_creator);

    passageRegistry = IPassageRegistry(_msgSender());

    transferEnabled = _transferEnabled;
    maxSupply = _maxSupply;
    claimAmount = 1;
    emit PassportInitialized(
      _msgSender(),
      address(this),
      _tokenSymbol,
      _tokenName,
      _transferEnabled,
      _maxSupply
    );
  }

  // ---- public ----

  /// @notice Mint token(s) to caller
  /// @dev Must first enable claim & set fee/amount (if desired)
  /// @param _amount Number of tokens to mint
  function claim(uint256 _amount) external payable {
    require(claimEnabled, "T6");
    require(_amount <= claimAmount, "T7");
    if (claimFee > 0) require(msg.value == claimFee * _amount, "T8");
    for (uint256 i = 0; i < _amount; i++) {
      _mint(_msgSender());
    }
  }

  /// @notice Mint token(s) to caller if they are on the supplied claimlist
  /// @dev Must first set claimlist root, enable claim, & set fee (if desired). Merkle tree can be generated with the Javascript library "merkletreejs", the hashing algorithm should be keccak256 and pair sorting should be enabled. Leaf is abi encodePacked address & amount
  /// @param _proof Proof for merkle tree
  /// @param _maxAmount Maximum number of tokens a user can mint, must be the same as merkle tree leaf
  /// @param _claimAmount Number of tokens to mint, must be less than or equal to max amount
  function claimClaimlist(
    bytes32[] calldata _proof,
    uint256 _maxAmount,
    uint256 _claimAmount
  ) external payable {
    require(claimlistClaimEnabled, "T9");
    if (claimlistClaimFee > 0)
      require(msg.value == claimlistClaimFee * _claimAmount, "T8");
    require(_claimAmount <= _maxAmount, "T10");
    bool validProof = MerkleProof.verify(
      _proof,
      claimlistRoot,
      keccak256(abi.encodePacked(_msgSender(), _maxAmount))
    );
    require(validProof, "T11");
    require(!claimlistClaimed[_msgSender()], "T12");
    claimlistClaimed[_msgSender()] = true;
    for (uint256 i = 0; i < _claimAmount; i++) {
      _mint(_msgSender());
    }
  }

  /// @notice Returns if Passport is still managed in registry
  /// @return if Passport is still managed in registry
  function isManaged() public view returns (bool) {
    return address(passageRegistry) != address(0);
  }

  /// @notice Returns Passport implementation version
  /// @return version number
  function passportVersion() public pure virtual returns (uint256 version) {
    return 1;
  }

  // ---- permissioned ----

  /// @notice Allows MINTER role to mint a new token to supplied address
  /// @param to Address to mint token to
  /// @return The minted token id
  function mintPassport(address to)
    external
    onlyRole(MINTER_ROLE)
    returns (uint256)
  {
    return _mint(to);
  }

  /// @notice Allows MINTER role to mint a new token to any number of supplied addresses
  /// @param _addresses List of addresses
  function mintPassports(address[] calldata _addresses)
    external
    onlyRole(MINTER_ROLE)
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _mint(_addresses[i]);
    }
  }

  // ---- admin ----

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
        abi.encodePacked(
          passageRegistry.globalPassportBaseURI(),
          StringsUpgradeable.toString(block.chainid),
          "/",
          addrStr,
          "/"
        )
      );
      uri = defaultUri;
    }

    IPassageRegistry passageRegistryCache = passageRegistry;
    passageRegistry = IPassageRegistry(address(0));
    passageRegistryCache.ejectPassport();
  }

  /// @notice Locks the maxSupply which prevents any future maxSupply updates
  /// @notice this is a one way operation and cannot be undone
  /// @notice the current version must be locked
  function lockMaxSupply()
    external
    maxSupplyLockProhibited
    versionLockRequired
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    maxSupplyLocked = true;

    emit MaxSupplyLocked();
  }

  /// @notice Locks the transferEnabled for a token which prevents any future transferEnabled updates
  /// @notice this is a one way operation and cannot be undone
  /// @notice the current version must be locked
  function lockTransferEnabled()
    external
    versionLockRequired
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    transferEnabledLocked = true;

    emit TransferEnabledLocked();
  }

  /// @notice Locks the version of the contract preventing any future upgrades
  /// @notice this is a one way operation and cannot be undone
  function lockVersion()
    external
    versionLockProhibited
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    versionLocked = true;

    emit VersionLocked();
  }

  /// @notice Allows manager to set the minting claim fee & amount
  /// @param _claimFee The claim fee in wei
  /// @param _claimAmount Max number of tokens someone can claim per tx
  function setClaimOptions(uint256 _claimFee, uint256 _claimAmount)
    external
    onlyRole(MANAGER_ROLE)
  {
    claimFee = _claimFee;
    claimAmount = _claimAmount;
  }

  /// @notice Allows manager to set the ability for tokens to be transferred
  /// @param _transferEnabled If transfer is enabled
  function setTransferEnabled(bool _transferEnabled)
    external
    onlyRole(MANAGER_ROLE)
  {
    require(transferEnabledLocked == false, "T15");

    transferEnabled = _transferEnabled;
    emit TransferEnableUpdated(_transferEnabled);
  }

  /// @notice Allows manager to set the ability to set a new base URI rather than use the Passport Global URI
  /// @param _uri Token base URI
  function setBaseURI(string memory _uri) external onlyRole(MANAGER_ROLE) {
    uri = _uri;
    emit BaseUriUpdated(_uri);
  }

  /// @notice Allows manager to set if claim is enabled
  /// @param _claimEnabled If claim is enabled
  function setClaimEnabled(bool _claimEnabled) external onlyRole(MANAGER_ROLE) {
    claimEnabled = _claimEnabled;
  }

  /// @notice Allows manager to set max supply of tokens
  /// @param _maxSupply New max supply of tokens
  function setMaxSupply(uint256 _maxSupply)
    external
    maxSupplyLockProhibited
    onlyRole(MANAGER_ROLE)
  {
    require(_maxSupply >= _tokenIdCounter.current(), "T16");
    maxSupply = _maxSupply;

    emit MaxSupplyUpdated(maxSupply);
  }

  /// @notice Allows default admin to set the owner address
  /// @dev not used for access control, used by services that require a single owner account
  /// @param newOwner address of the new owner
  function setOwnership(address newOwner)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setOwnership(newOwner);
  }

  /// @notice Allows manager to set trusted forwarder for meta-transactions
  /// @param forwarder Address of trusted forwarder
  function setTrustedForwarder(address forwarder)
    external
    onlyRole(MANAGER_ROLE)
  {
    _setTrustedForwarder(forwarder);
  }

  /// @notice Allows manager to set the fee for the claimlist claim
  /// @param _claimFee Fee in wei
  function setClaimlistClaimFee(uint256 _claimFee)
    external
    onlyRole(MANAGER_ROLE)
  {
    claimlistClaimFee = _claimFee;
  }

  /// @notice Allows manager to set if the claimlist claim is enabled
  /// @param _claimEnabled If the claimlist claim is enabled
  function setClaimlistClaimEnabled(bool _claimEnabled)
    external
    onlyRole(MANAGER_ROLE)
  {
    claimlistClaimEnabled = _claimEnabled;
  }

  /// @notice Allows manager to set the merkle tree root for the claimlist
  /// @dev Merkle tree can be generated with the Javascript library "merkletreejs", the hashing algorithm should be keccak256 and pair sorting should be enabled. Leaf is abi encodePacked address & amount
  /// @param _claimlistRoot Merkle tree root
  function setClaimlistRoot(bytes32 _claimlistRoot)
    external
    onlyRole(MANAGER_ROLE)
  {
    claimlistRoot = _claimlistRoot;
  }

  /// @notice Allows manager to set the claimlist claim fee & merkle root
  /// @dev Merkle tree can be generated with the Javascript library "merkletreejs", the hashing algorithm should be keccak256 and pair sorting should be enabled. Leaf is abi encodePacked address & amount
  /// @param _claimFee The claim fee in wei for the claimlist
  /// @param _claimlistRoot Merkle tree root
  function setClaimlistOptions(uint256 _claimFee, bytes32 _claimlistRoot)
    external
    onlyRole(MANAGER_ROLE)
  {
    claimlistClaimFee = _claimFee;
    claimlistRoot = _claimlistRoot;
  }

  /// @notice Allows manager to transfer eth from contract
  function withdraw() external onlyRole(MANAGER_ROLE) {
    uint256 value = address(this).balance;
    address payable to = payable(_msgSender());
    emit Withdraw(value, _msgSender());
    to.transfer(value);
  }

  function setBeforeTransferContract(address _beforeTransferContract)
    external
    onlyRole(MANAGER_ROLE)
  {
    beforeTransferContract = IDecagonBeforeTransferContract(
      _beforeTransferContract
    );
  }

  // ---- private ----

  function _setupRoles(address _creator) internal {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _grantRole(DEFAULT_ADMIN_ROLE, _creator);
    _grantRole(UPGRADER_ROLE, _msgSender());
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
        abi.encodePacked(
          passageRegistry.globalPassportBaseURI(),
          StringsUpgradeable.toString(block.chainid),
          "/",
          addrStr,
          "/"
        )
      );
  }

  function _mint(address to) internal returns (uint256) {
    if (maxSupply > 0) require(_tokenIdCounter.current() < maxSupply, "T17");
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
    return tokenId;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC721Upgradeable) {
    // disable non-mint & non-burn transfers if requested
    require(
      (from == address(0) || ((to == address(0)) || transferEnabled)),
      "T18"
    );

    // call beforeTransferContract if set
    if (address(beforeTransferContract) != address(0)) {
      beforeTransferContract.beforeTransferLogic(from, to, amount);
    }

    super._beforeTokenTransfer(from, to, amount);
  }

  // ---- meta txs ----

  function _msgSender()
    internal
    view
    virtual
    override(BaseRelayRecipient, ContextUpgradeable)
    returns (address)
  {
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

  // ---- overrides ----

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyAuthorizedUpgrader
    versionLockProhibited
  {}

  function hasUpgraderRole(address _address)
    public
    view
    override(IPassport, PassageAccess)
    returns (bool)
  {
    return super.hasUpgraderRole(_address);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function upgradeTo(address newImplementation)
    external
    override(UUPSUpgradeable, IPassport)
    onlyProxy
  {
    _authorizeUpgrade(newImplementation);
    _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
  }

  function upgradeToAndCall(address newImplementation, bytes memory data)
    external
    payable
    override(UUPSUpgradeable, IPassport)
    onlyProxy
  {
    _authorizeUpgrade(newImplementation);
    _upgradeToAndCallUUPS(newImplementation, data, true);
  }
}

interface IDecagonBeforeTransferContract {
  function beforeTransferLogic(
    address from,
    address to,
    uint256 tokenId
  ) external view;
}