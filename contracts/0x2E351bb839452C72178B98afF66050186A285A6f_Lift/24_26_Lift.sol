// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./utils/Ownable.sol";
import "./utils/LiftErrors.sol";

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface IEtch {
  function addLift(
    uint256 _etchId,
    uint256 _liftId,
    bytes32 _entropy
  ) external;

  function getGen(uint256 _etchId) external view returns (uint128);

  function getEntropy(uint256 _etchId) external view returns (bytes32);

  function getArweaveId(uint256 _etchId) external view returns (string memory);

  function exists(uint256 _etchId) external view returns (bool);
}

/// @title Lift
/// @author @llio (Deca)
contract Lift is
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

  event LiftCreated(
    address _recipient,
    uint256 indexed _liftId,
    uint256 indexed _etchId
  );

  event LiftInitalized(
    address indexed etchAddress,
    uint256 priceEth,
    uint256 priceErc20
  );

  // Internal tokenID tracker
  uint256 public totalSupply;

  // Price in Erc20
  uint256 public priceErc20;

  // Price in ETH
  uint256 public priceEth;

  // Erc20 address
  IERC20Upgradeable public erc20;

  address payable public treasury;

  // Address used for signing hashes on our end
  address public signer;

  // Etch address
  address public etch;

  bool public liftEthPayments;

  bool public liftErc20Payments;

  bool public liftBurnPayments;

  string public baseUri;

  mapping(uint256 => LiftInfo) public lifts;

  struct LiftInfo {
    bytes32 entropy;
    uint256 etchId;
    uint128 gen;
    uint128 multiplier;
    uint256 gift;
    string arweaveId;
    string mediaId;
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
    address _etch
  ) external initializer onlyProxy {
    if (_etch == address(0) || _treasury == address(0) || _signer == address(0))
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
    etch = _etch;
    emit LiftInitalized(address(this), _priceEth, _priceErc20);
  }

  function _authorizeUpgrade(address)
    internal
    view
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {}

  function toggleLiftEthPayments() external onlyRole(DEFAULT_ADMIN_ROLE) {
    liftEthPayments = !liftEthPayments;
  }

  function toggleLiftErc20Payments() external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (address(erc20) == address(0)) revert AddressNotSet();
    liftErc20Payments = !liftErc20Payments;
  }

  function toggleLiftBurnPayments() external onlyRole(DEFAULT_ADMIN_ROLE) {
    liftBurnPayments = !liftBurnPayments;
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

  function setEtchAddress(address _newEtch)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    if (_newEtch == address(0)) revert AddressNotSet();
    if (!IERC721Upgradeable(_newEtch).supportsInterface(0x80ac58cd))
      revert NotErc721();
    etch = _newEtch;
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

  function getInfo(uint256 _liftId)
    external
    view
    returns (
      bytes32 _entropy,
      uint256 _etchId,
      uint128 _gen,
      uint128 _multiplier,
      uint256 _gift,
      string memory _arweaveId,
      string memory _mediaId
    )
  {
    _entropy = lifts[_liftId].entropy;
    _etchId = lifts[_liftId].etchId;
    _gen = lifts[_liftId].gen;
    _multiplier = lifts[_liftId].multiplier;
    _gift = lifts[_liftId].gift;
    _arweaveId = lifts[_liftId].arweaveId;
    _mediaId = lifts[_liftId].mediaId;
  }

  // Makes a Lift of a given etchID
  function lift(
    address _recipient,
    uint256 _etchId,
    uint128 _multiplier,
    uint256 _gift,
    string memory _mediaId,
    uint256 _expiry,
    bytes memory _signature
  ) private returns (uint256 liftId) {
    if (!IEtch(etch).exists(_etchId)) revert NonexistentToken();
    if (block.number > _expiry) revert ExpiredSignature();
    if (
      !verify(
        keccak256(
          abi.encodePacked(
            _recipient,
            _etchId,
            _multiplier,
            _gift,
            _mediaId,
            _expiry,
            msg.sender
          )
        ),
        _signature
      )
    ) revert ProofInvalid();
    liftId = totalSupply++;

    lifts[liftId].etchId = _etchId;
    lifts[liftId].multiplier = _multiplier;
    lifts[liftId].gift = _gift;
    lifts[liftId].mediaId = _mediaId;
    lifts[liftId].gen = IEtch(etch).getGen(_etchId);
    lifts[liftId].entropy = IEtch(etch).getEntropy(_etchId);
    lifts[liftId].arweaveId = IEtch(etch).getArweaveId(_etchId);

    _mint(_recipient, liftId);

    emit LiftCreated(_recipient, liftId, _etchId);

    IEtch(etch).addLift(
      _etchId,
      liftId,
      keccak256(
        abi.encodePacked(liftId, lifts[liftId].gen, msg.sender, block.timestamp)
      )
    );
  }

  function mintLiftEth(
    address _recipient,
    uint256 _etchId,
    uint128 _multiplier,
    uint256 _gift,
    string calldata _mediaId,
    uint256 _expiry,
    bytes calldata _signature
  ) external payable nonReentrant returns (uint256 liftId) {
    if (!liftEthPayments) revert EthDisabled();
    address ownerAddress = IERC721Upgradeable(etch).ownerOf(_etchId);
    if (ownerAddress == address(this) || ownerAddress == address(0))
      revert EtchBurned();
    uint256 fee = priceEth * _multiplier;
    if (msg.value < (fee + _gift)) revert InsufficientPayment();
    liftId = lift(
      _recipient,
      _etchId,
      _multiplier,
      _gift,
      _mediaId,
      _expiry,
      _signature
    );
    uint256 feeDividedBy3 = fee / 3;
    (bool sentTreasury, ) = treasury.call{value: feeDividedBy3}("");
    (bool sentOwner, ) = payable(ownerAddress).call{
      value: msg.value - feeDividedBy3
    }("");
    if (!sentTreasury || !sentOwner) revert TransferFailed();
  }

  function mintLiftErc20(
    address _recipient,
    uint256 _etchId,
    uint128 _multiplier,
    uint256 _gift,
    string calldata _mediaId,
    uint256 _expiry,
    bytes calldata _signature
  ) external nonReentrant returns (uint256 liftId) {
    if (!liftErc20Payments) revert Erc20Disabled();
    address ownerAddress = IERC721Upgradeable(etch).ownerOf(_etchId);
    if (ownerAddress == address(this) || ownerAddress == address(0))
      revert EtchBurned();
    uint256 fee = priceErc20 * _multiplier;
    if (erc20.allowance(msg.sender, address(this)) < fee + _gift)
      revert InsufficientAllowance();
    liftId = lift(
      _recipient,
      _etchId,
      _multiplier,
      _gift,
      _mediaId,
      _expiry,
      _signature
    );
    SafeERC20Upgradeable.safeTransferFrom(erc20, msg.sender, treasury, fee / 3);
    SafeERC20Upgradeable.safeTransferFrom(
      erc20,
      msg.sender,
      ownerAddress,
      ((fee * 2) / 3) + _gift
    );
  }

  function mintLiftBurn(
    address _recipient,
    uint256 _etchId,
    uint128 _multiplier,
    string calldata _mediaId,
    uint256 _expiry,
    bytes calldata _signature
  ) external payable nonReentrant returns (uint256 liftId) {
    if (!liftBurnPayments) revert BurnDisabled();
    if (IERC721Upgradeable(etch).ownerOf(_etchId) != msg.sender)
      revert NotTheOwner();
    if (msg.value < (((priceEth * _multiplier) - priceEth) / 3))
      revert InsufficientPayment();
    liftId = lift(
      _recipient,
      _etchId,
      _multiplier,
      0,
      _mediaId,
      _expiry,
      _signature
    );
    (bool sentTreasury, ) = treasury.call{value: msg.value}("");
    if (!sentTreasury) revert TransferFailed();
    IERC721Upgradeable(etch).transferFrom(msg.sender, address(this), _etchId);
  }

  function verify(bytes32 messageHash, bytes memory signature)
    internal
    view
    returns (bool)
  {
    return
      signer ==
      ECDSAUpgradeable.recover(
        ECDSAUpgradeable.toEthSignedMessageHash(messageHash),
        signature
      );
  }

  function tokenURI(uint256 _liftId)
    public
    view
    override(ERC721Upgradeable)
    returns (string memory)
  {
    if (!_exists(_liftId)) revert NonexistentToken();
    return super.tokenURI(_liftId);
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

  function burn(uint256 _liftId) external {
    _burn(_liftId);
  }

  function _burn(uint256 _liftId) internal override(ERC721Upgradeable) {
    if (!_exists(_liftId)) revert NonexistentToken();
    if (msg.sender != ownerOf(_liftId)) revert NotTheOwner();
    super._burn(_liftId);
  }

  function setOwnership(address newOwner)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    _setOwnership(newOwner);
  }

  receive() external payable {}
}