//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';

import './ERC721Upgradeable.sol';

/***
 *
 *            ##### ##
 *         ######  /###     #
 *        /#   /  /  ###   ###                            #
 *       /    /  /    ###   #                            ##
 *           /  /      ##                                ##
 *          ## ##      ## ###   ###  /###     /###     ######## /##
 *          ## ##      ##  ###   ###/ #### / / ###  / ######## / ###
 *        /### ##      /    ##    ##   ###/ /   ###/     ##   /   ###
 *       / ### ##     /     ##    ##       ##    ##      ##  ##    ###
 *          ## ######/      ##    ##       ##    ##      ##  ########
 *          ## ######       ##    ##       ##    ##      ##  #######
 *          ## ##           ##    ##       ##    ##      ##  ##
 *          ## ##           ##    ##       ##    /#      ##  ####    /
 *          ## ##           ### / ###       ####/ ##     ##   ######/
 *     ##   ## ##            ##/   ###       ###   ##     ##   #####
 *    ###   #  /
 *     ###    /
 *      #####/
 *        ###
 *
 *            ##
 *         /####
 *        /  ###
 *           /##
 *          /  ##
 *          /  ##          /###     /##       /###
 *         /    ##        / ###  / / ###     / #### /
 *         /    ##       /   ###/ /   ###   ##  ###/
 *        /      ##     ##    ## ##    ### ####
 *        /########     ##    ## ########    ###
 *       /        ##    ##    ## #######       ###
 *       #        ##    ##    ## ##              ###
 *      /####      ##   ##    ## ####    /  /###  ##
 *     /   ####    ## / #######   ######/  / #### /
 *    /     ##      #/  ######     #####      ###/
 *    #                 ##
 *     ##               ##
 *                      ##
 *                       ##
 */

contract PirateApes is OwnableUpgradeable, ERC721Upgradeable {
  uint256 public constant MAX_SUPPLY = 5700;
  uint16 public constant MAX_TOTAL_BATCH_SIZE = 10;

  uint8 public constant LOCATION_HEAVEN = 255;

  uint16 public constant FREE_AMOUNT_OG = 3;
  uint16 public constant FREE_AMOUNT_WL = 2;
  uint16 public constant FREE_AMOUNT_PUBLIC = 1;

  uint256 public constant PRICE_1_EXTRA = 0.04 ether;
  uint256 public constant PRICE_4_EXTRA = 0.14 ether;
  uint256 public constant PRICE_7_EXTRA = 0.21 ether;

  uint256 public SALE_STARTED_AT_OG;
  uint256 public SALE_STARTED_AT_WL;
  uint256 public SALE_STARTED_AT_PUBLIC;

  uint256 public supply;
  uint256 public burned;

  address private _proxyRegistryAddress;
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

  function initialize(address verifier_, address proxyRegistryAddress_)
    public
    initializer
  {
    __ERC721_init('PirateApes', 'BAPC');
    __Ownable_init();

    _verifier = verifier_;
    _proxyRegistryAddress = proxyRegistryAddress_;

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

  function actualOwnerOf(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId), 'ERC721: token does not exist');

    if (tokenState[tokenId].owner != address(0)) {
      return tokenState[tokenId].owner;
    }

    uint256 startTokenId = tokenId > MAX_TOTAL_BATCH_SIZE
      ? tokenId - MAX_TOTAL_BATCH_SIZE
      : 0;

    // todo: optimise
    for (uint256 i = tokenId; i > startTokenId; i--) {
      if (tokenState[i].batch != 0) {
        return tokenState[i].owner;
      }
    }

    revert('ERC721: invalid token ID');
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
    require(ownerOf(tokenId) == from, 'ERC721: transfer from incorrect owner');
    require(to != address(0), 'ERC721: transfer to the zero address');

    require(to != from, "ERC721: can't transfer themself");

    require(
      tokenState[tokenId].locationId == 0,
      "BAPC: token can't be transferred"
    );

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

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

  function _mintTokens(address sender_, uint16 batch_) internal {
    require(supply + batch_ <= MAX_SUPPLY, 'BAPC: exceed supply');
    require(
      tokenOwnerState[sender_].startTokenId == 0,
      'BAPC: Wallet already minted'
    );

    // start tokenId from 1
    uint256 tokenId = 1 + supply;

    tokenState[tokenId] = TokenMeta(sender_, batch_, 0, 0);
    tokenOwnerState[sender_] = TokenOwnerState(
      uint16(tokenId),
      batch_,
      batch_,
      0
    );

    uint256 endTokenId = tokenId + batch_;
    for (tokenId; tokenId < endTokenId; tokenId++) {
      emit Transfer(address(0), sender_, tokenId);
    }

    supply += batch_;
  }

  function _mint(
    uint16 freeAmount,
    uint16 paidAmount,
    uint256 timestamp,
    bytes memory sig
  ) internal {
    require(block.timestamp < timestamp, 'BAPC: Outdated transaction');

    if (paidAmount == 1) {
      require(msg.value >= PRICE_1_EXTRA, 'BAPC: Not enough funds for 1');
    } else if (paidAmount == 4) {
      require(msg.value >= PRICE_4_EXTRA, 'BAPC: Not enough funds for 4');
    } else if (paidAmount == 7) {
      require(msg.value >= PRICE_7_EXTRA, 'BAPC: Not enough funds for 7');
    } else if (paidAmount != 0) {
      revert('Invalid paid amount');
    }

    uint16 batch = freeAmount + paidAmount;

    require(batch <= MAX_TOTAL_BATCH_SIZE, 'BAPC: Too many tokens in batch');

    address sender = _msgSender();

    bytes32 hash = keccak256(
      abi.encodePacked(sender, timestamp, freeAmount, paidAmount)
    );

    require(_verifier == _recoverSigner(hash, sig), 'BAPC: invalid signature');

    _mintTokens(sender, batch);
  }

  function mintOG(
    uint16 paidAmount,
    uint256 timestamp,
    bytes memory sig
  ) public payable {
    require(SALE_STARTED_AT_OG > 0, 'BAPC: og sale should be active');

    _mint(3, paidAmount, timestamp, sig);
  }

  function mintWL(
    uint16 paidAmount,
    uint256 timestamp,
    bytes memory sig
  ) public payable {
    require(SALE_STARTED_AT_WL > 0, 'BAPC: wl sale should be active');

    _mint(2, paidAmount, timestamp, sig);
  }

  function mintPublic(
    uint16 paidAmount,
    uint256 timestamp,
    bytes memory sig
  ) public payable {
    require(SALE_STARTED_AT_PUBLIC > 0, 'BAPC: public sale should be active');

    _mint(1, paidAmount, timestamp, sig);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(address owner_, address operator_)
    public
    view
    override
    returns (bool)
  {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner_)) == operator_) {
      return true;
    }

    return super.isApprovedForAll(owner_, operator_);
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view virtual returns (uint256) {
    return supply - burned;
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

  function setState(
    bool ogSaleState_,
    bool wlSaleState_,
    bool publicSaleState_
  ) external onlyOwner {
    SALE_STARTED_AT_OG = ogSaleState_ ? block.timestamp : 0;

    SALE_STARTED_AT_WL = wlSaleState_ ? block.timestamp : 0;

    SALE_STARTED_AT_PUBLIC = publicSaleState_ ? block.timestamp : 0;
  }

  function withdraw(uint256 amount) public onlyOwner {
    (bool success, ) = _msgSender().call{value: amount}('');
    require(success, 'Withdraw failed');
  }

  function withdrawAll() external onlyOwner {
    withdraw(address(this).balance);
  }

  function mintReserved(address wallet, uint16 amount) external onlyOwner {
    address receiver = wallet == address(0) ? _msgSender() : wallet;

    _mintTokens(receiver, amount);
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}