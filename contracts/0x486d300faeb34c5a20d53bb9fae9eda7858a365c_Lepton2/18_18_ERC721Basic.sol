// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Basic is Context, ERC165, IERC721, IERC721Metadata {
  using SafeMath for uint256;
  using Address for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;

  // mapping from token ids to their owners
  mapping (uint256 => address) internal _tokenOwners;

  // mapping from owner to token balance
  mapping (address => uint256) internal _ownerBalance;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal _operatorApprovals;

  // Token name
  string internal _name;

  // Token symbol
  string internal _symbol;

  // Token Count
  uint256 internal _tokenCount;

  /*
    *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
    *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
    *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
    *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
    *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
    *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
    *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
    *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
    *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
    *
    *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
    *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
    */
  bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

  /*
    *     bytes4(keccak256('name()')) == 0x06fdde03
    *     bytes4(keccak256('symbol()')) == 0x95d89b41
    *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
    *
    *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
    */
  bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

  /**
    * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
    */
  constructor (string memory name, string memory symbol) public {
    _name = name;
    _symbol = symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
  }

  /**
    * @dev See {IERC721-balanceOf}.
    */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721:E-403");
    return _ownerBalance[owner];
  }

  /**
    * @dev See {IERC721-ownerOf}.
    */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return _tokenOwners[tokenId];
  }

  /**
    * @dev See {IERC721Metadata-name}.
    */
  function name() public view override returns (string memory) {
    return _name;
  }

  /**
    * @dev See {IERC721Metadata-symbol}.
    */
  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  /**
    * @dev See {IERC721Metadata-tokenURI}.
    */
  function tokenURI(uint256 /* tokenId */) public view virtual override returns (string memory) {
    return "";
  }

  /**
    * @dev See {IERC721-approve}.
    */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721:E-111");

    require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721:E-105");

    _approve(to, tokenId);
  }

  /**
    * @dev See {IERC721-getApproved}.
    */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721:E-405");
    return _tokenApprovals[tokenId];
  }

  /**
    * @dev See {IERC721-setApprovalForAll}.
    */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(operator != _msgSender(), "ERC721:E-111");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
    * @dev See {IERC721-isApprovedForAll}.
    */
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
    * @dev See {IERC721-transferFrom}.
    */
  function transferFrom(address from, address to, uint256 tokenId) public virtual override {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721:E-105");

    _transfer(from, to, tokenId);
  }

  /**
    * @dev See {IERC721-safeTransferFrom}.
    */
  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
    * @dev See {IERC721-safeTransferFrom}.
    */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721:E-105");
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
    * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
    * are aware of the ERC721 protocol to prevent tokens from being forever locked.
    *
    * `_data` is additional data, it has no specified format and it is sent in call to `to`.
    *
    * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
    * implement alternative mecanisms to perform token transfer, such as signature-based.
    *
    * Requirements:
    *
    * - `from` cannot be the zero address.
    * - `to` cannot be the zero address.
    * - `tokenId` token must exist and be owned by `from`.
    * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
    *
    * Emits a {Transfer} event.
    */
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721:E-402");
  }

  /**
    * @dev Returns whether `tokenId` exists.
    *
    * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
    *
    * Tokens start existing when they are minted (`_mint`),
    * and stop existing when they are burned (`_burn`).
    */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return _tokenOwners[tokenId] != address(0x0);
  }

  /**
    * @dev Returns whether `spender` is allowed to manage `tokenId`.
    *
    * Requirements:
    *
    * - `tokenId` must exist.
    */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    require(_exists(tokenId), "ERC721:E-405");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  /**
    * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
    * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
    */
  function _safeMint(address to, bytes memory _data) internal virtual returns (uint256) {
    uint256 tokenId = _mint(to);
    require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721:E-402");
    return tokenId;
  }

  /**
    * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
    * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
    */
  function _safeMintBatch(address to, uint256 count, bytes memory _data) internal virtual {
    uint256 startTokenId = _mintBatch(to, count);
    require(_checkOnERC721Received(address(0), to, startTokenId, _data), "ERC721:E-402");
  }

  /**
    * @dev Mints `tokenId` and transfers it to `to`.
    *
    * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
    *
    * Requirements:
    *
    * - `tokenId` must not exist.
    * - `to` cannot be the zero address.
    *
    * Emits a {Transfer} event.
    */
  function _mint(address to) internal virtual returns (uint256) {
    require(to != address(0), "ERC721:E-403");

    _tokenCount = _tokenCount.add(1);
    uint256 tokenId = _tokenCount;
    require(!_exists(tokenId), "ERC721:E-407");

    _tokenOwners[tokenId] = to;
    _ownerBalance[to] = _ownerBalance[to].add(1);

    emit Transfer(address(0), to, tokenId);
    return tokenId;
  }

  /**
    * @dev Mints `tokenId` and transfers it to `to`.
    *
    * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
    *
    * Requirements:
    *
    * - `tokenId` must not exist.
    * - `to` cannot be the zero address.
    *
    * Emits a {Transfer} event.
    */
  function _mintBatch(address to, uint256 count) internal virtual returns (uint256) {
    require(to != address(0), "ERC721:E-403");

    uint256 startTokenId = _tokenCount.add(1);
    for (uint i = 1; i <= count; i++) {
      uint256 tokenId = _tokenCount.add(i);
      _tokenOwners[tokenId] = to;
      emit Transfer(address(0), to, tokenId);
    }

    _tokenCount = _tokenCount.add(count);
    _ownerBalance[to] = _ownerBalance[to].add(count);
    return startTokenId;
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
  function _transfer(address from, address to, uint256 tokenId) internal virtual {
    require(ownerOf(tokenId) == from, "ERC721:E-102");
    require(to != address(0), "ERC721:E-403");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _tokenOwners[tokenId] = to;
    _ownerBalance[from] = _ownerBalance[from].sub(1);
    _ownerBalance[to] = _ownerBalance[to].add(1);

    emit Transfer(from, to, tokenId);
  }

  /**
    * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
    * The call is not executed if the target address is not a contract.
    *
    * @param from address representing the previous owner of the given token ID
    * @param to target address that will receive the tokens
    * @param tokenId uint256 ID of the token to be transferred
    * @param _data bytes optional data to send along with the call
    * @return bool whether the call correctly returned the expected magic value
    */
  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    internal returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes memory returndata = to.functionCall(abi.encodeWithSelector(
      IERC721Receiver(to).onERC721Received.selector,
      _msgSender(),
      from,
      tokenId,
      _data
    ), "ERC721:E-402");
    bytes4 retval = abi.decode(returndata, (bytes4));
    return (retval == _ERC721_RECEIVED);
  }

  function _approve(address to, uint256 tokenId) internal {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }
}