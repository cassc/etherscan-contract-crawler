// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import 'OpenZeppelin/[email protected]/contracts/access/AccessControlUpgradeable.sol';
import 'OpenZeppelin/[email protected]/contracts/access/OwnableUpgradeable.sol';
import 'OpenZeppelin/[email protected]/contracts/token/ERC721/ERC721Upgradeable.sol';
import 'OpenZeppelin/[email protected]/contracts/security/ReentrancyGuardUpgradeable.sol';
import '../interfaces/IZaapERC721Factory.sol';

contract ZaapERC721 is
  ERC721Upgradeable,
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable
{
  //#########################################
  // public variable
  //#########################################

  // Create `owner role` that has `MINTER_ROLE`
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  mapping(address => uint) public mintedAmounts; // mapping user address to minted token amount

  uint public maxSupply; // maximum token supply
  uint public publicMintPrice; // public mint price
  uint public feeBPS; // sale fee bps (scale of 10_000)
  uint public maxMintPerAddress; // max token mints per address

  address public factory; // factory address
  address public claimer; // claimer address

  bool public isPublicMintActive; // is public mint active
  bool public isPublicMintStart; // has the first public mint been minted

  //#########################################
  // private variable
  //#########################################

  uint private curTokenId; // current ERC721 token id
  string private _baseTokenURI; // base token URI

  //#########################################
  // event
  //#########################################

  event WithdrawETH(address indexed receiver, address indexed feeReceiver, uint amount, uint fee);
  event SetPublicMintStatus(bool isPublicMintActive);
  event PublicMint(address indexed minter, uint amount);
  event SetFeeBPS(uint feeBPS);
  event SetPublicMintPrice(uint price);
  event SetMaxSupply(uint maxSupply);
  event SetMaxMintPerAddress(uint maxMintPerAddress);
  event SetBaseURI(string baseURI);
  event SetClaimer(address claimer);

  //#########################################
  // modifier
  //#########################################

  /// @dev throw if called by any account other than externally owned account
  modifier onlyEOA() {
    require(msg.sender == tx.origin, 'ZaapERC721: not eoa');
    _;
  }

  /// @dev throw if called by any account other than claimer
  modifier onlyClaimer() {
    require(msg.sender == claimer, 'ZaapERC721: not claimer');
    _;
  }

  /// @dev throw if called by any account other than ZaapERC721Factory
  modifier onlyFactory() {
    require(msg.sender == factory, 'ZaapERC721: not factory');
    _;
  }

  //#########################################
  // init
  //#########################################

  /// @dev initialize zaap erc721 config from encoded data
  /// @param _data encoded data to initialize
  function initialize(bytes calldata _data) external initializer {
    (
      string memory name,
      string memory symbol,
      string memory baseURI_,
      uint _maxSupply,
      uint _maxMintPerAddress,
      uint _publicMintPrice,
      address _claimer
    ) = abi.decode(_data, (string, string, string, uint, uint, uint, address));
    __ReentrancyGuard_init();
    __ERC721_init(name, symbol);
    __Ownable_init();

    uint _feeBPS = IZaapERC721Factory(msg.sender).feeBPS(); // gas saving

    require(_maxSupply > 0, 'ZaapERC721: invalid maxSupply');
    require(_maxMintPerAddress > 0, 'ZaapERC721: invalid maxPerAddress');
    require(_feeBPS <= 10000, 'ZaapERC721: invalid feeBPS');
    require(_claimer != address(this), 'ZaapERC721: invalid claimer');

    factory = msg.sender;
    publicMintPrice = _publicMintPrice;
    maxSupply = _maxSupply;
    feeBPS = _feeBPS;
    maxMintPerAddress = _maxMintPerAddress;
    _baseTokenURI = baseURI_;
    claimer = _claimer;

    emit SetPublicMintPrice(_publicMintPrice);
    emit SetMaxSupply(_maxSupply);
    emit SetFeeBPS(_feeBPS);
    emit SetMaxMintPerAddress(_maxMintPerAddress);
    emit SetBaseURI(baseURI_);
    emit SetClaimer(_claimer);
  }

  //#########################################
  // execute function
  //#########################################

  /// @dev mint directly by `minter` contract
  /// @param _to address to receive nft
  /// @param _amount nft amount to mint
  function zaapMint(address _to, uint _amount) external payable onlyRole(MINTER_ROLE) {
    require(_amount > 0, 'ZaapERC721: amount == 0');
    _batchMint(_to, _amount);
  }

  /// @dev add new minters which can mint directly to this contract
  /// @param _minters a list of minter contracts
  function addMinters(address[] calldata _minters) external onlyOwner {
    for (uint i = 0; i < _minters.length; i++) {
      _grantRole(MINTER_ROLE, _minters[i]);
    }
  }

  /// @dev remove minters which can mint directly to this contract
  /// @param _minters a list of minter contracts
  function revokeMinters(address[] calldata _minters) external onlyOwner {
    for (uint i = 0; i < _minters.length; i++) {
      _revokeRole(MINTER_ROLE, _minters[i]);
    }
  }

  /// @dev mint nft by anyone
  /// @param _amount nft amount to mint
  function publicMint(uint _amount) external payable onlyEOA {
    require(_amount > 0, 'ZaapERC721: amount == 0');
    require(isPublicMintActive, 'ZaapERC721: public mint is not active');
    require(msg.value == _amount * publicMintPrice, 'ZaapERC721: wrong ETH amount');
    if (!isPublicMintStart) {
      isPublicMintStart = true;
    }
    _batchMint(msg.sender, _amount);

    emit PublicMint(msg.sender, _amount);
  }

  /// @dev withdraw ETH from sale
  function withdrawETH() external onlyClaimer nonReentrant {
    // calculate amount
    address _feeReceiver = IZaapERC721Factory(factory).feeReceiver(); // gas saving
    address _claimer = claimer; // gas saving

    uint balance = address(this).balance;
    uint fee = _feeReceiver == address(0) ? 0 : (balance * feeBPS) / 10000;

    // transfer ETH to owner and fee receiver
    if (fee > 0) _sendETH(_feeReceiver, fee);
    if (balance - fee > 0) _sendETH(_claimer, balance - fee);

    emit WithdrawETH(_claimer, _feeReceiver, balance - fee, fee);
  }

  //#########################################
  // setter function
  //#########################################

  /// @dev set public mint status to active or pause
  /// @param _status a flag whether anyone can call public mint function
  function setPublicMintStatus(bool _status) external onlyOwner {
    isPublicMintActive = _status;
    emit SetPublicMintStatus(_status);
  }

  /// @dev set tokens base uri
  /// @param baseURI_ base uri for nft
  function setBaseURI(string memory baseURI_) external onlyOwner {
    _baseTokenURI = baseURI_;
    emit SetBaseURI(baseURI_);
  }

  /// @dev set sale fee bps (only factory can set)
  /// @param _feeBPS fee BPS (scale of 10_000)
  function setFeeBPS(uint _feeBPS) external onlyFactory {
    require(_feeBPS <= 10000, 'ZaapERC721: invalid feeBPS');
    feeBPS = _feeBPS;
    emit SetFeeBPS(feeBPS);
  }

  /// @dev set public mint price (can only call before someone call `publicMint`)
  /// @param _price set public mint price
  function setPublicMintPrice(uint _price) external onlyFactory {
    require(!isPublicMintStart, 'ZaapERC721: public mint has already started');
    publicMintPrice = _price;
    emit SetPublicMintPrice(_price);
  }

  //#########################################
  // internal function
  //#########################################

  function _sendETH(address _to, uint _amount) internal {
    if (_amount > 0) {
      (bool success, ) = _to.call{value: _amount}('');
      require(success, 'ZaapERC721: transfer not success');
    }
  }

  /// @dev mint token start from `curTokenId` to `curTokenId` + `amount`
  /// @param _to address to receive nft
  /// @param _amount nft amount to mint
  function _batchMint(address _to, uint _amount) internal {
    uint _curTokenId = curTokenId; // gas saving
    require(_curTokenId + _amount <= maxSupply, 'ZaapERC721: exceeds maximum supply');

    // check amount exceeds max per address
    uint newMintedAmount = mintedAmounts[_to] + _amount;
    require(newMintedAmount <= maxMintPerAddress, 'ZaapERC721: exceeds max per address');

    // mint nft tokens
    uint toTokenId = _curTokenId + _amount;
    while (_curTokenId < toTokenId) {
      _safeMint(_to, _curTokenId);
      unchecked {
        ++_curTokenId;
      }
    }

    // assign new current token id;
    curTokenId = toTokenId;

    // assign updated user minted amount
    mintedAmounts[_to] = newMintedAmount;
  }

  //#########################################
  // view function
  //#########################################

  /// @dev get total supply of nft contract
  /// @return uint total supply of nft contract
  function totalSupply() external view returns (uint) {
    return curTokenId;
  }

  /// @dev get base URI of nft contract
  /// @return string base URI of nft contract
  function baseURI() external view returns (string memory) {
    return _baseURI();
  }

  /// @dev internal: get base URI of nft contract
  /// @return string base URI of nft contract
  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlUpgradeable, ERC721Upgradeable)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Upgradeable).interfaceId ||
      interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}