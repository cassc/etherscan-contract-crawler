//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';

import './ERC721Upgradeable.sol';

contract Fenix is OwnableUpgradeable, ERC721Upgradeable {
  uint256 public constant MAX_SUPPLY = 5252;
  uint16 public constant MAX_TOTAL_BATCH_SIZE = 20;

  uint256 public constant PRICE_AL = 0.025 ether;
  uint256 public constant PRICE_PUBLIC = 0.029 ether;

  uint256 public SALE_STARTED_AT_AL;
  uint256 public SALE_STARTED_AT_PUBLIC;

  uint256 public supply;

  address private _verifier;

  string private _baseTokenURI;

  struct TokenMeta {
    address owner;
    uint16 batch;
    uint8 locationId;
    uint72 meta;
  }

  mapping(uint256 => TokenMeta) public tokenState;

  struct TokenOwnerState {
    uint16 startTokenId;
    uint16 batch;
    uint16 balance;
    uint208 meta;
  }

  mapping(address => TokenOwnerState) public tokenOwnerState;

  mapping(address => bool) private _operators;

  function initialize(address verifier_) public initializer {
    __ERC721_init('FENIX', 'FNX');
    __Ownable_init();

    _verifier = verifier_;

    _operators[_msgSender()] = true;
  }

  /**
   * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
   */
  function _msgSender() internal view override returns (address sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
          mload(add(array, index)),
          0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }

  function isOwnerOf(uint256 tokenId, address wallet_)
    public
    view
    virtual
    override
    returns (bool)
  {
    address tokenOwner = tokenState[tokenId].owner;

    if (tokenOwner != address(0)) {
      return tokenOwner == wallet_;
    }

    TokenOwnerState storage ownerState = tokenOwnerState[wallet_];

    return (ownerState.startTokenId + ownerState.batch) >= tokenId;
  }

  function actualOwnerOf(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId), 'ERC721: token does not exist');

    uint256 curr = tokenId;

    while (tokenState[curr].owner == address(0)) {
      curr--;
    }

    return tokenState[curr].owner;
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner_)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(owner_ != address(0), 'ERC721: balance query for the zero address');

    return tokenOwnerState[owner_].balance;
  }

  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    return actualOwnerOf(tokenId);
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId)
    internal
    view
    virtual
    override
    returns (bool)
  {
    return tokenId <= supply;
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    require(isOwnerOf(tokenId, from), 'ERC721: transfer from incorrect owner');
    require(to != address(0), 'ERC721: transfer to the zero address');

    require(to != from, "ERC721: can't transfer themself");

    require(
      tokenState[tokenId].locationId == 0,
      "FNX: token can't be transferred"
    );

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    uint256 nextTokenId = tokenId + 1;
    if (_exists(nextTokenId) && tokenState[nextTokenId].owner == address(0)) {
      tokenState[nextTokenId].owner = from;
    }

    tokenOwnerState[from].balance -= 1;
    tokenOwnerState[to].balance += 1;

    tokenState[tokenId].owner = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId);
  }

  function _recoverSigner(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    return
      ECDSAUpgradeable.recover(
        ECDSAUpgradeable.toEthSignedMessageHash(hash),
        signature
      );
  }

  function _mintTokens(address minter_, uint16 amount_) internal {
    require((supply + amount_) <= MAX_SUPPLY, 'FNX: exceed supply');
    require(
      tokenOwnerState[minter_].startTokenId == 0,
      'FNX: wallet already minted'
    );

    // start tokenId from 1
    uint256 tokenId = 1 + supply;

    tokenState[tokenId] = TokenMeta({
      owner: minter_,
      batch: amount_,
      locationId: 0,
      meta: 0
    });

    tokenOwnerState[minter_] = TokenOwnerState({
      startTokenId: uint16(tokenId),
      batch: amount_,
      balance: amount_ + tokenOwnerState[minter_].balance,
      meta: 0
    });

    uint256 endTokenId = tokenId + amount_;
    for (tokenId; tokenId < endTokenId; tokenId++) {
      emit Transfer(address(0), minter_, tokenId);
    }

    supply += amount_;
  }

  function _mintTokensAgain(address minter_, uint16 amount_) internal {
    require((supply + amount_) <= MAX_SUPPLY, 'FNX: exceed supply');
    require(
      tokenOwnerState[minter_].startTokenId != 0,
      'FNX: wallet didnt mint yet'
    );

    // start tokenId from 1
    uint256 tokenId = 1 + supply;
    uint256 endTokenId = tokenId + amount_;

    for (tokenId; tokenId < endTokenId; tokenId++) {
      tokenState[tokenId] = TokenMeta({
        owner: minter_,
        batch: 1,
        locationId: 0,
        meta: 0
      });

      emit Transfer(address(0), minter_, tokenId);
    }

    tokenOwnerState[minter_].balance += amount_;
    supply += amount_;
  }

  function _mintBase(
    uint8 mintType_,
    uint16 amount_,
    uint16 payableAmount_,
    uint256 timestamp_,
    bytes memory sig_
  ) internal {
    require(block.timestamp < timestamp_, 'FNX: outdated transaction');
    require(amount_ <= MAX_TOTAL_BATCH_SIZE, 'FNX: invalid amount');

    address minter_ = _msgSender();

    bytes32 hash = keccak256(
      abi.encodePacked(minter_, mintType_, amount_, payableAmount_, timestamp_)
    );

    require(_verifier == _recoverSigner(hash, sig_), 'FNX: invalid signature');

    if (tokenOwnerState[minter_].startTokenId == 0) {
      _mintTokens(minter_, amount_);
    } else {
      _mintTokensAgain(minter_, amount_);
    }
  }

  function mintAL(
    uint16 amount_,
    uint16 payableAmount_,
    uint256 timestamp_,
    bytes memory sig_
  ) external payable {
    require(SALE_STARTED_AT_AL > 0, 'FNX: AL sale should be active');
    require(msg.value >= (payableAmount_ * PRICE_AL), 'FNX: not enough funds');

    _mintBase(1, amount_, payableAmount_, timestamp_, sig_);
  }

  function mintPublic(
    uint16 amount_,
    uint16 payableAmount_,
    uint256 timestamp_,
    bytes memory sig_
  ) external payable {
    require(SALE_STARTED_AT_PUBLIC > 0, 'FNX: public sale should be active');
    require(
      msg.value >= (payableAmount_ * PRICE_PUBLIC),
      'FNX: not enough funds'
    );

    _mintBase(2, amount_, payableAmount_, timestamp_, sig_);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view virtual returns (uint256) {
    return supply;
  }

  /* onlyOwner */

  modifier onlyOperator() {
    require(_operators[_msgSender()] == true, 'Caller is not the operator');
    _;
  }

  function setOperator(address operatorAddress, bool value) public onlyOwner {
    _operators[operatorAddress] = value;
  }

  function setVerifier(address verifier_) external onlyOwner {
    _verifier = verifier_;
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    _baseTokenURI = baseURI_;
  }

  function withdraw(uint256 amount) public onlyOwner {
    (bool success, ) = _msgSender().call{value: amount}('');
    require(success, 'Withdraw failed');
  }

  function withdrawAll() external onlyOwner {
    withdraw(address(this).balance);
  }

  function mintReserved(address wallet_, uint16 amount_) external onlyOwner {
    address receiver = wallet_ == address(0) ? _msgSender() : wallet_;

    _mintTokens(receiver, amount_);
  }

  function setState(bool alSaleState_, bool publicSaleState_)
    external
    onlyOwner
  {
    SALE_STARTED_AT_AL = alSaleState_ ? block.timestamp : 0;

    SALE_STARTED_AT_PUBLIC = publicSaleState_ ? block.timestamp : 0;
  }
}