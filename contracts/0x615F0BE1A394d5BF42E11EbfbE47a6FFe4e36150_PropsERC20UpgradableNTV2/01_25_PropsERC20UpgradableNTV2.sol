// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "@thirdweb-dev/contracts/openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";
import "@thirdweb-dev/contracts/feature/interface/IOwnable.sol";

//  ==========  Internal imports    ==========

import "../interfaces/IPropsContract.sol";
import "../interfaces/ISignatureMinting.sol";

contract PropsERC20UpgradableNTV2 is
  Initializable,
  ERC20Upgradeable,
  ERC20BurnableUpgradeable,
  PausableUpgradeable,
  OwnableUpgradeable,
  AccessControlEnumerableUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC2771ContextUpgradeable
{
  using StringsUpgradeable for uint256;
  using ECDSAUpgradeable for bytes32;

  //////////////////////////////////////////////
  // State Vars
  /////////////////////////////////////////////

  bytes32 private constant MODULE_TYPE = bytes32("PropsERC20UpgradableNT");
  uint256 private constant VERSION = 2;

  bytes32 private constant CONTRACT_ADMIN_ROLE =
    keccak256("CONTRACT_ADMIN_ROLE");
  bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 private constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");

  // @dev reserving space for 10 more roles
  bytes32[32] private __gap;

  address private _owner;
  address private accessRegistry;
  address private assetTokenAddress;
  address public signatureVerifier;
  address public approvedReceiverAddress;
  address public project;
  address[] private trustedForwarders;

  mapping(address => uint256) public claimedTokens;

  //////////////////////////////////////////////
  // Errors
  /////////////////////////////////////////////

  error NonTransferable();
  error InvalidSignature();
  error MintQuantityInvalid();
  error ExpiredSignature();

  function initialize(
    address _defaultAdmin,
    string memory name,
    string memory symbol,
    address[] memory _trustedForwarders,
    address _accessRegistry
  ) public initializer {
    __ERC20_init(name, symbol);
    __ERC20Burnable_init();
    __Pausable_init();
    __Ownable_init();
    _owner = _defaultAdmin;
    transferOwnership(_defaultAdmin);
    _mint(_defaultAdmin, 1 * 10**18);
    accessRegistry = _accessRegistry;

    _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
    _setRoleAdmin(CONTRACT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(PRODUCER_ROLE, CONTRACT_ADMIN_ROLE);
    _setRoleAdmin(MINTER_ROLE, PRODUCER_ROLE);

    // call registry add here
    // add default admin entry to registry
    // IPropsAccessRegistry(accessRegistry).add(_defaultAdmin, address(this));
  }

  /*///////////////////////////////////////////////////////////////
                      Generic contract logic
    //////////////////////////////////////////////////////////////*/

  /// @dev Returns the type of the contract.
  function contractType() external pure returns (bytes32) {
    return MODULE_TYPE;
  }

  /// @dev Returns the version of the contract.
  function contractVersion() external pure returns (uint8) {
    return uint8(VERSION);
  }

  function setAssetTokenAddress(address _address)
    external
    minRole(CONTRACT_ADMIN_ROLE)
  {
    assetTokenAddress = _address;
  }

  function setApprovedReceiverAddress(address _address)
    external
    minRole(CONTRACT_ADMIN_ROLE)
  {
    approvedReceiverAddress = _address;
  }

  /// @dev Lets a contract admin set the address for the access registry.
  function setAccessRegistry(address _accessRegistry)
    external
    minRole(CONTRACT_ADMIN_ROLE)
  {
    accessRegistry = _accessRegistry;
  }

  /// @dev Lets a contract admin set the address for the parent project.
  function setProject(address _project) external minRole(PRODUCER_ROLE) {
    project = _project;
  }

  function grantRole(bytes32 role, address account)
    public
    virtual
    override(AccessControlUpgradeable, IAccessControlUpgradeable)
    onlyOwner
  {
    if (!hasRole(role, account)) {
      super._grantRole(role, account);
      // IPropsAccessRegistry(accessRegistry).add(account, address(this));
    }
  }

  function revokeRole(bytes32 role, address account)
    public
    virtual
    override(AccessControlUpgradeable, IAccessControlUpgradeable)
    onlyOwner
  {
    if (hasRole(role, account)) {
      if (role == DEFAULT_ADMIN_ROLE && account == owner()) revert();
      super._revokeRole(role, account);
      // IPropsAccessRegistry(accessRegistry).remove(account, address(this));
    }
  }

  /**
   * @dev Check if minimum role for function is required.
   */
  modifier minRole(bytes32 _role) {
    require(_hasMinRole(_role), "Not authorized");
    _;
  }

  function hasMinRole(bytes32 _role) public view virtual returns (bool) {
    return _hasMinRole(_role);
  }

  function _hasMinRole(bytes32 _role) internal view returns (bool) {
    // @dev does account have role?
    if (hasRole(_role, _msgSender())) return true;
    // @dev are we checking against default admin?
    if (_role == DEFAULT_ADMIN_ROLE) return false;
    // @dev walk up tree to check if user has role admin role
    return _hasMinRole(getRoleAdmin(_role));
  }

  /*///////////////////////////////////////////////////////////////
                      ERC20 contract logic
    //////////////////////////////////////////////////////////////*/

  function setSignatureVerifier(address _address)
    external
    minRole(CONTRACT_ADMIN_ROLE)
  {
    signatureVerifier = _address;
  }

  function getSignatureVerifier() external view returns (address) {
    return signatureVerifier;
  }

  function mint(address _to, uint256 _amount)
    public
    minRole(CONTRACT_ADMIN_ROLE)
  {
    claimedTokens[_to] += _amount;
  }

  function batchMint(address[] calldata __to, uint256[] calldata __amount)
    external
    minRole(CONTRACT_ADMIN_ROLE)
  {
    for (uint256 i = 0; i < __to.length; i++) {
      claimedTokens[__to[i]] += __amount[i];
    }
  }

  function issueTokens(address _to, uint256 _amount) public {
    require(msg.sender == assetTokenAddress, "Unauthorized");
    claimedTokens[_to] += (_amount * (10**18));
  }

  function pause() public minRole(CONTRACT_ADMIN_ROLE) {
    _pause();
  }

  function unpause() public minRole(CONTRACT_ADMIN_ROLE) {
    _unpause();
  }

  function balanceOf(address account)
    public
    view
    override
    returns (uint256 balance)
  {
    balance = claimedTokens[account] / (10**18);

    //Retrieve unclaimed balance from 721 contract and add to balance
    balance += ERC721AssetContract(assetTokenAddress)
      .aggregateUnclaimedERC20TokenBalance(account);
    balance *= (10**18);
  }

  function getClaimedTokenBalance(address account)
    public
    view
    returns (uint256 balance)
  {
    balance = claimedTokens[account] / (10**18);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    if (from != address(0x0)) {
      revert NonTransferable();
    }
  }

  /*///////////////////////////////////////////////////////////////
                            Signature Enforcement
    //////////////////////////////////////////////////////////////*/

  function revertOnInvalidMintSignature(
    address sender,
    ISignatureMinting.SignatureMintCartItem memory cartItem
  ) public view {
    if (cartItem.expirationTime < block.timestamp) revert ExpiredSignature();

    if (
      mintedByID[cartItem.uid][sender] + cartItem.quantity >
      cartItem.allocation
    ) revert MintQuantityInvalid();

    address recoveredAddress = ECDSAUpgradeable.recover(
      keccak256(
        abi.encodePacked(
          sender,
          cartItem.uid,
          cartItem.quantity,
          cartItem.price,
          cartItem.allocation,
          cartItem.expirationTime
        )
      ).toEthSignedMessageHash(),
      cartItem.signature
    );

    if (recoveredAddress != signatureVerifier) revert InvalidSignature();
  }

  function logMintActivity(
    string memory uid,
    address wallet_address,
    uint256 incrementalQuantity
  ) external {
    require(msg.sender == assetTokenAddress, "Unauthorized");
    _logMintActivity(uid, wallet_address, incrementalQuantity);
  }

  function _logMintActivity(
    string memory uid,
    address wallet_address,
    uint256 incrementalQuantity
  ) internal {
    mintedByID[uid][wallet_address] += incrementalQuantity;
  }

  /*///////////////////////////////////////////////////////////////
                                Earn
    //////////////////////////////////////////////////////////////*/

  function earnWithSignature(ISignatureMinting.SignatureMintCart calldata cart)
    external
    payable
    nonReentrant
  {
    uint256 _cost = 0;
    uint256 _quantity = 0;

    for (uint256 i = 0; i < cart.items.length; i++) {
      ISignatureMinting.SignatureMintCartItem memory _item = cart.items[i];

      //validate signatures
      //validate quantities against allocations
      revertOnInvalidMintSignature(_msgSender(), _item);

      _logMintActivity(
        cart.items[i].uid,
        address(_msgSender()),
        cart.items[i].quantity
      );

      _quantity += _item.quantity;
      _cost += _item.price * _item.quantity;
    }

    if (_cost > 0) {
      if (_cost > msg.value) revert InsufficientFunds();
      address _wallet = ERC721AssetContract(assetTokenAddress)
        .receivingWallet();
      (bool sent, bytes memory data) = _wallet.call{ value: msg.value }("");
    }

    claimedTokens[_msgSender()] += (_quantity * (10**18));
    emit Earned(_msgSender(), _quantity);
  }

  /*///////////////////////////////////////////////////////////////
                                Context
    //////////////////////////////////////////////////////////////*/

  function _msgSender()
    internal
    view
    virtual
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (address sender)
  {
    return ERC2771ContextUpgradeable._msgSender();
  }

  function _msgData()
    internal
    view
    virtual
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (bytes calldata)
  {
    return ERC2771ContextUpgradeable._msgData();
  }

  /// @dev Returns the type of the contract.
  function assetContract() external view returns (address) {
    return assetTokenAddress;
  }

  //Upgrades

  mapping(string => mapping(address => uint256)) public mintedByID;
  error InsufficientFunds();
  event Earned(address indexed account, uint256 amount);

  function getMintedByUid(string calldata _uid, address _wallet)
    external
    view
    returns (uint256)
  {
    return mintedByID[_uid][_wallet];
  }

  uint256[46] private ___gap;
}

contract ERC721AssetContract {
  address public receivingWallet;

  function aggregateUnclaimedERC20TokenBalance(address holder)
    public
    view
    returns (uint256 erc20tokens)
  {}
}