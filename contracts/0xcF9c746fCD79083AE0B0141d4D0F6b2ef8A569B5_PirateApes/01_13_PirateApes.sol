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
  uint8 public constant LOCATION_QUARANTINE = 254;

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

  mapping(uint256 => address) public _minters;

  event Locked(
    address indexed ownder,
    address indexed locker,
    bool indexed state
  );
  struct Lock {
    address locker;
    uint96 meta;
  }
  mapping(address => Lock) public locked;
  mapping(address => bool) public markets;

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

    return _minters[tokenId];
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

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    require(
      (locked[from].locker == address(0)) ||
        markets[_msgSender()] ||
        // workaround, when "transfer" to the contract wallet is used to estimate gas (eg x2y2)
        (to == 0x3B9edBC42bA4ACEDb4f2Aa290aEFBb40cd10fCAc),
      'BAPC: owner is locked for transfers'
    );

    _transferFrom(from, to, tokenId);
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
  function _transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
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

  function _lock(address locker) internal {
    address wallet = _msgSender();

    require(locked[wallet].locker == address(0), 'BAPC: already locked');

    locked[wallet].locker = locker;

    emit Locked(wallet, locker, true);
  }

  function _unlock(address wallet) internal {
    address locker = _msgSender();

    require(locked[wallet].locker == locker, 'BAPC: cant unlock this wallet');

    locked[wallet].locker = address(0);

    emit Locked(wallet, locker, false);
  }

  function lock(address locker) external {
    address wallet = _msgSender();

    require(wallet != locker, 'BAPC: cant lock themselves');

    _lock(locker);
  }

  function unlock(address wallet) external {
    address locker = _msgSender();

    require(locker != wallet, 'BAPC: cant unlock themselves');

    _unlock(wallet);
  }

  function lock(uint256 timestamp, bytes memory sig) external {
    address wallet = _msgSender();
    address locker = wallet;

    bytes32 hash = keccak256(abi.encodePacked(wallet, locker, true, timestamp));
    require(_verifier == _recoverSigner(hash, sig), 'BAPC: invalid signature');

    _lock(locker);
  }

  function unlock(
    address wallet,
    uint256 timestamp,
    bytes memory sig
  ) external {
    address locker = _msgSender();

    bytes32 hash = keccak256(
      abi.encodePacked(wallet, locker, false, timestamp)
    );
    require(_verifier == _recoverSigner(hash, sig), 'BAPC: invalid signature');

    _unlock(wallet);
  }

  function transfer(
    address to,
    uint256 tokenId,
    uint256 timestamp,
    bytes memory sig
  ) external {
    address from = _msgSender();

    bytes32 hash = keccak256(abi.encodePacked(from, to, tokenId, timestamp));
    require(_verifier == _recoverSigner(hash, sig), 'BAPC: invalid signature');

    _transferFrom(from, to, tokenId);
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

  function setMarketplace(address marketAddress, bool value) public onlyOwner {
    markets[marketAddress] = value;
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

  /**
   * @dev for testing only
   */
  function _mint(address to, uint16 amount) external onlyOwner {
    require(
      amount > 0 && (supply + amount) <= MAX_SUPPLY,
      'BAPC: invalid amount'
    );

    uint256 tokenIdFrom = supply + 1;
    for (uint16 i = 0; i < amount; i++) {
      uint256 tokenId = tokenIdFrom + i;
      tokenState[tokenId].owner = to;
      emit Transfer(address(0), to, tokenId);
    }

    tokenOwnerState[to].balance += amount;

    supply += amount;
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}