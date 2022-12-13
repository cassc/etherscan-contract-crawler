// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./utils/Ownable.sol";
import "./utils/EtchUtils.sol";
import "./utils/EtchErrors.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title Etch
/// @author @llio (Deca)
contract EtchV2 is
  Ownable,
  ReentrancyGuardUpgradeable,
  ERC721Upgradeable,
  UUPSUpgradeable,
  AccessControlUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  event BaseUriUpdated(string newBaseUri);

  event TreasuryUpdated(address indexed newTreasury);

  event SignerUpdated(address indexed newSigner);

  event Erc20Updated(IERC20Upgradeable indexed newErc20);

  event Erc20PriceUpdated(uint256 indexed newPriceErc20);

  event EthPriceUpdated(uint256 indexed newPriceEth);

  event EtchCreated(
    address _recipient,
    uint256 indexed _etchId,
    address indexed _contract,
    uint256 indexed _id,
    string _arweaveId
  );

  event CustomCreated(
    address _recipient,
    uint256 indexed _etchId,
    string indexed _target,
    string _arweaveId
  );

  event LiftAdded(
    uint256 _etchId,
    uint256 _liftId,
    uint256 _gen,
    bytes32 _entropy
  );

  event EtchInitalized(
    address indexed etchAddress,
    uint256 priceEth,
    uint256 priceErc20
  );

  bytes32 public constant LIFT_ROLE = keccak256("LIFT_ROLE");

  // Internal tokenID tracker
  uint256 public totalSupply;

  // Price in Erc20
  uint256 public priceErc20;

  // Price in ETH
  uint256 public priceEth;

  // Erc20 address
  IERC20Upgradeable public erc20;

  // Fee management contract
  address payable public treasury;

  // Address used for signing hashes
  address public signer;

  bool public etchEthPayments;

  bool public etchErc20Payments;

  bool public customEthPayments;

  bool public customErc20Payments;

  bool public repliesEnabled;

  string public baseUri;

  // EtchID to EtchData
  mapping(uint256 => EtchData) public etches;

  mapping(uint256 => Native) public natives;

  mapping(uint256 => string) public customs;

  mapping(uint256 => uint256[]) public liftIds;

  // Used signatures
  mapping(bytes => bool) public usedSignature;

  mapping(address => mapping(uint256 => uint256[])) public children;

  // Custom strings to array of etchIDs of that string
  mapping(bytes32 => uint256[]) public customChildren;

  enum EtchType {
    NATIVE,
    CUSTOM
  }

  // Common Etch information
  struct EtchData {
    bytes32 entropy;
    uint128 gen;
    EtchType etchType;
    string arweaveId;
  }

  struct Native {
    uint256 id;
    address contract_;
    Ownership ownership;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    string calldata _tokenName,
    string calldata _tokenSymbol,
    IERC20Upgradeable _erc20,
    uint256 _priceErc20,
    uint256 _priceEth,
    address payable _treasury,
    address _signer,
    string calldata _baseUri
  ) external initializer onlyProxy {
    if (_treasury == address(0) || _signer == address(0))
      revert AddressNotSet();
    __ERC721_init(_tokenName, _tokenSymbol);
    __AccessControl_init();
    __UUPSUpgradeable_init();
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    __ReentrancyGuard_init();
    erc20 = _erc20;
    priceErc20 = _priceErc20;
    priceEth = _priceEth;
    treasury = _treasury;
    signer = _signer;
    baseUri = _baseUri;
    emit EtchInitalized(address(this), _priceEth, _priceErc20);
  }

  function _authorizeUpgrade(address)
    internal
    view
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {}

  function toggleEtchEthPayments() external onlyRole(DEFAULT_ADMIN_ROLE) {
    etchEthPayments = !etchEthPayments;
  }

  function toggleEtchErc20Payments() external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (address(erc20) == address(0)) revert AddressNotSet();
    etchErc20Payments = !etchErc20Payments;
  }

  function toggleCustomEthPayments() external onlyRole(DEFAULT_ADMIN_ROLE) {
    customEthPayments = !customEthPayments;
  }

  function toggleCustomErc20Payments() external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (address(erc20) == address(0)) revert AddressNotSet();
    customErc20Payments = !customErc20Payments;
  }

  function toggleReplies() external onlyRole(DEFAULT_ADMIN_ROLE) {
    repliesEnabled = !repliesEnabled;
  }

  function setBaseUri(string calldata _newBaseUri)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    baseUri = _newBaseUri;
    emit BaseUriUpdated(_newBaseUri);
  }

  function setTreasuryAddress(address payable _newTreasury)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (_newTreasury == address(0)) revert AddressNotSet();
    treasury = _newTreasury;
    emit TreasuryUpdated(_newTreasury);
  }

  function setSignerAddress(address _newSigner)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (_newSigner == address(0)) revert AddressNotSet();
    signer = _newSigner;
    emit SignerUpdated(_newSigner);
  }

  function setErc20Address(IERC20Upgradeable _newErc20)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (address(_newErc20) == address(0)) revert AddressNotSet();
    erc20 = _newErc20;
    emit Erc20Updated(_newErc20);
  }

  function setPriceErc20(uint256 _newPriceErc20)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    priceErc20 = _newPriceErc20;
    emit Erc20PriceUpdated(_newPriceErc20);
  }

  function setPriceEth(uint256 _newPriceEth)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    priceEth = _newPriceEth;
    emit EthPriceUpdated(_newPriceEth);
  }

  function addLift(
    uint256 _etchId,
    uint256 _liftId,
    bytes32 _entropy
  ) external onlyRole(LIFT_ROLE) {
    if (!_exists(_etchId)) revert NonexistentToken();
    liftIds[_etchId].push(_liftId);
    etches[_etchId].entropy = _entropy;
    etches[_etchId].gen++;
    emit LiftAdded(_etchId, _liftId, etches[_etchId].gen, _entropy);
  }

  function withdrawEth() external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
    if (treasury == address(0)) revert AddressNotSet();
    (bool sentTreasury, ) = treasury.call{value: address(this).balance}("");
    return sentTreasury;
  }

  function withdrawErc20() external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (treasury == address(0) || address(erc20) == address(0))
      revert AddressNotSet();
    SafeERC20Upgradeable.safeApprove(
      erc20,
      address(this),
      erc20.balanceOf(address(this))
    );
    SafeERC20Upgradeable.safeTransferFrom(
      erc20,
      address(this),
      treasury,
      erc20.balanceOf(address(this))
    );
  }

  function getInfo(uint256 _etchId)
    external
    view
    returns (
      bytes32 _entropy,
      uint128 _gen,
      EtchType _etchType,
      string memory _arweaveId,
      Ownership _ownership,
      address _contract,
      uint256 _id,
      string memory _target
    )
  {
    if (!_exists(_etchId)) revert NonexistentToken();
    _entropy = etches[_etchId].entropy;
    _gen = etches[_etchId].gen;
    _etchType = etches[_etchId].etchType;
    _arweaveId = etches[_etchId].arweaveId;
    _ownership = natives[_etchId].ownership;
    _contract = natives[_etchId].contract_;
    _id = natives[_etchId].id;
    _target = customs[_etchId];
  }

  function getChildren(address _contract, uint256 _tokenId)
    external
    view
    returns (uint256[] memory)
  {
    if (children[_contract][_tokenId].length == 0) revert NonexistentToken();
    return children[_contract][_tokenId];
  }

  // Returns array of all etchIDs associated with a given Custom
  function getCustomChildren(string calldata _target)
    external
    view
    returns (uint256[] memory)
  {
    if (customChildren[keccak256(bytes(_target))].length == 0)
      revert NonexistentToken();
    return customChildren[keccak256(bytes(_target))];
  }

  function getLiftIds(
    uint256 _etchId,
    uint256 _cursor,
    uint256 _entries
  ) external view returns (uint256[] memory ids, uint256 newCursor) {
    if (!_exists(_etchId)) revert NonexistentToken();
    uint256 len = _entries;
    if (len > liftIds[_etchId].length - _cursor) {
      len = liftIds[_etchId].length - _cursor;
    }
    ids = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      ids[i] = liftIds[_etchId][_cursor + i];
    }
    newCursor = _cursor + len;
  }

  function getType(uint256 _etchId) external view returns (EtchType) {
    if (!_exists(_etchId)) revert NonexistentToken();
    return etches[_etchId].etchType;
  }

  function getGen(uint256 _etchId) external view returns (uint128) {
    if (!_exists(_etchId)) revert NonexistentToken();
    return etches[_etchId].gen;
  }

  function getEntropy(uint256 _etchId) external view returns (bytes32) {
    if (!_exists(_etchId)) revert NonexistentToken();
    return etches[_etchId].entropy;
  }

  function getArweaveId(uint256 _etchId) external view returns (string memory) {
    if (!_exists(_etchId)) revert NonexistentToken();
    return etches[_etchId].arweaveId;
  }

  function exists(uint256 _etchId) external view returns (bool) {
    return _exists(_etchId);
  }

  function storeBasic(
    uint256 _etchId,
    EtchType _etchType,
    string memory _arweaveId,
    bytes memory _signature
  ) private {
    etches[_etchId].etchType = _etchType;
    etches[_etchId].arweaveId = _arweaveId;
    usedSignature[_signature] = true;
  }

  // Takes a contract and tokenID and etches
  function etch(
    address _recipient,
    address _contract,
    uint256 _id,
    string memory _arweaveId,
    uint256 _expiry,
    bytes memory _signature
  ) private returns (uint256 etchId) {
    if (block.number > _expiry) revert ExpiredSignature();
    if (usedSignature[_signature]) revert ProofInvalid();
    if (_contract == address(this) && !repliesEnabled) revert RepliesDisabled();
    if (
      !EtchUtils.verify(
        keccak256(
          abi.encodePacked(
            _recipient,
            _contract,
            _id,
            _arweaveId,
            _expiry,
            msg.sender
          )
        ),
        _signature,
        signer
      )
    ) revert ProofInvalid();
    etchId = totalSupply++;

    storeBasic(etchId, EtchType.NATIVE, _arweaveId, _signature);
    children[_contract][_id].push(etchId);
    natives[etchId].contract_ = _contract;
    natives[etchId].id = _id;
    natives[etchId].ownership = isOwnedV2(_contract, _id, msg.sender);

    if (_contract == address(this)) {
      etches[_id].entropy = keccak256(
        abi.encodePacked(etchId, etches[_id].gen, msg.sender, block.timestamp)
      );
      etches[_id].gen++;
    }
    _mint(_recipient, etchId);

    emit EtchCreated(_recipient, etchId, _contract, _id, _arweaveId);
  }

  function mintEtchEth(
    address _recipient,
    address _contract,
    uint256 _id,
    string calldata _arweaveId,
    uint256 _expiry,
    bytes calldata _signature
  ) external payable nonReentrant returns (uint256 etchId) {
    if (!etchEthPayments) revert EthDisabled();
    if (msg.value < priceEth) revert InsufficientPayment();
    etchId = etch(_recipient, _contract, _id, _arweaveId, _expiry, _signature);
    (bool sentTreasury, ) = treasury.call{value: msg.value}("");
    if (!sentTreasury) revert TransferFailed();
  }

  function mintEtchErc20(
    address _recipient,
    address _contract,
    uint256 _id,
    string calldata _arweaveId,
    uint256 _expiry,
    bytes calldata _signature
  ) external nonReentrant returns (uint256 etchId) {
    if (!etchErc20Payments) revert Erc20Disabled();
    if (erc20.allowance(msg.sender, address(this)) < priceErc20)
      revert InsufficientAllowance();
    etchId = etch(_recipient, _contract, _id, _arweaveId, _expiry, _signature);
    SafeERC20Upgradeable.safeTransferFrom(
      erc20,
      msg.sender,
      treasury,
      priceErc20
    );
  }

  // Takes a string and Etches it
  function custom(
    address _recipient,
    string memory _target,
    string memory _arweaveId,
    uint256 _expiry,
    bytes memory _signature
  ) private returns (uint256 customId) {
    if (block.number > _expiry) revert ExpiredSignature();
    if (usedSignature[_signature]) revert ProofInvalid();
    if (
      !EtchUtils.verify(
        keccak256(
          abi.encodePacked(_recipient, _target, _arweaveId, _expiry, msg.sender)
        ),
        _signature,
        signer
      )
    ) revert ProofInvalid();
    customId = totalSupply++;

    storeBasic(customId, EtchType.CUSTOM, _arweaveId, _signature);
    customs[customId] = _target;
    customChildren[keccak256(bytes(_target))].push(customId);

    _mint(_recipient, customId);

    emit CustomCreated(_recipient, customId, _target, _arweaveId);
  }

  function mintCustomEth(
    address _recipient,
    string calldata _target,
    string calldata _arweaveId,
    uint256 _expiry,
    bytes calldata _signature
  ) external payable nonReentrant returns (uint256 customId) {
    if (!customEthPayments) revert EthDisabled();
    if (msg.value < priceEth) revert InsufficientPayment();
    customId = custom(_recipient, _target, _arweaveId, _expiry, _signature);
    (bool sentTreasury, ) = treasury.call{value: msg.value}("");
    if (!sentTreasury) revert TransferFailed();
  }

  function mintCustomErc20(
    address _recipient,
    string calldata _target,
    string calldata _arweaveId,
    uint256 _expiry,
    bytes calldata _signature
  ) external nonReentrant returns (uint256 customId) {
    if (!customErc20Payments) revert Erc20Disabled();
    if (erc20.allowance(msg.sender, address(this)) < priceErc20)
      revert InsufficientAllowance();
    customId = custom(_recipient, _target, _arweaveId, _expiry, _signature);
    SafeERC20Upgradeable.safeTransferFrom(
      erc20,
      msg.sender,
      treasury,
      priceErc20
    );
  }

  function tokenURI(uint256 _etchId)
    public
    view
    override(ERC721Upgradeable)
    returns (string memory)
  {
    if (!_exists(_etchId)) revert NonexistentToken();
    return super.tokenURI(_etchId);
  }

  function _baseURI()
    internal
    view
    override(ERC721Upgradeable)
    returns (string memory)
  {
    return baseUri;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function burn(uint256 _etchId) external {
    _burn(_etchId);
  }

  function _burn(uint256 _etchId) internal override(ERC721Upgradeable) {
    if (!_exists(_etchId)) revert NonexistentToken();
    if (msg.sender != ownerOf(_etchId)) revert NotTheOwner();
    super._burn(_etchId);
  }

  function setOwnership(address newOwner)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setOwnership(newOwner);
  }

  receive() external payable {}

  function isOwnedV2(
    address _contract,
    uint256 _id,
    address _sender
  ) internal view returns (Ownership) {
    if (!AddressUpgradeable.isContract(_contract)) revert NonContract();
    bytes memory call;
    if (_contract == 0x9DFE69c0C52fa76d47Eef3f5aaE3e0Bcf73F7EE1) {
      call = abi.encodeWithSignature("punkIndexToAddress(uint256)", _id);
    } else {
      call = abi.encodeWithSignature("ownerOf(uint256)", _id);
    }
    (, bytes memory result) = address(_contract).staticcall(call);
    address nftOwner = abi.decode(result, (address));
    return nftOwner == _sender ? Ownership.OWNED : Ownership.UNOWNED;
  }
}