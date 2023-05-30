// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";


/**
 * @dev Contract that models each crew member as an ERC721, non-fungible token.
 */
contract CrewToken is ERC165, IERC721, IERC721Metadata, Ownable, Pausable {
  using Address for address;
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdTracker;

  // Mapping from tokenId to owner address
  mapping (uint => address) private _tokenOwners;

  // Mapping from address to number of owned tokens
  mapping (address => uint) private _balances;

  // Mapping from token ID to approved address
  mapping (uint => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) private _operatorApprovals;

  // Mapping indicating allowed managers
  mapping (address => bool) private _managers;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Base URI
  string private _baseURI;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  constructor (string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(type(IERC721).interfaceId);
    _registerInterface(type(IERC721Metadata).interfaceId);

    // Start our ids from 1
    _tokenIdTracker.increment();
  }

  // Modifier to check if calling contract has the correct minting role
  modifier onlyManagers {
    require(isManager(_msgSender()), "CrewToken: Only managers can call this function");
    _;
  }

  /**
   * @dev Add a new account / contract that can mint / burn crew members
   * @param _manager Address of the new manager
   */
  function addManager(address _manager) external onlyOwner {
    _managers[_manager] = true;
  }

  /**
   * @dev Remove a current manager
   * @param _manager Address of the manager to be removed
   */
  function removeManager(address _manager) external onlyOwner {
    _managers[_manager] = false;
  }

  /**
   * @dev Checks if an address is a manager
   * @param _manager Address of contract / account to check
   */
  function isManager(address _manager) public view returns (bool) {
    return _managers[_manager];
  }

  /**
   * @dev Pauses the contract and prevents transfers / burns
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev Unpauses the contract allowing transfers / burns
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @dev Allowed managers (including sale contract) can mint initial asterodis
   * @param _to The purchaser's address
   */
  function mint(address _to) external onlyManagers returns (uint) {
    uint currentId = _tokenIdTracker.current();
    _safeMint(_to, currentId);
    _tokenIdTracker.increment();
    return currentId;
  }

  /**
   * @dev Burns a token
   * @param _tokenId uint256 ID of the token being burned
   */
  function burn(uint256 _tokenId) external onlyManagers {
    _burn(_tokenId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balances[owner];
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
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    string memory base = baseURI();
    return string(abi.encodePacked(base, tokenId.toString()));
  }


  /**
   * @dev External interface to set the base URI for all token IDs.
   */
  function setBaseURI(string memory baseURI_) external onlyOwner {
    _setBaseURI(baseURI_);
  }

  /**
  * @dev Returns the base URI set via {_setBaseURI}. This will be
  * automatically added as a prefix in {tokenURI} to each token's URI, or
  * to the token ID if no specific URI is set for that token ID.
  */
  function baseURI() public view returns (string memory) {
    return _baseURI;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}. Enumerable extension is not implemented fully,
   * but totalSupply is included for better compatibility.
   */
  function totalSupply() public view returns (uint256) {
    return _tokenIdTracker.current() - 1;
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public override {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");
    require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721: approve to caller");
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
  function transferFrom(address from, address to, uint256 tokenId) public override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) public override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
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
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`).
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return _tokenOwners[tokenId] != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received},
   * which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(address to, uint256 tokenId, bytes memory _data) internal onlyManagers {
    _mint(to, tokenId);
    require(_checkOnERC721Received(address(0), to, tokenId, _data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
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
  function _mint(address to, uint256 tokenId) internal whenNotPaused {
    require(tokenId > 0, "ERC721: invalid token ID");
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");
    _balances[to]++;
    _tokenOwners[tokenId] = to;
    emit Transfer(address(0), to, tokenId);
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
  function _transfer(address from, address to, uint256 tokenId) internal whenNotPaused {
    require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");
    require(_balances[from] > 0); // Avoid overflows

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _tokenOwners[tokenId] = to;
    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal whenNotPaused {
    require(_exists(tokenId), "ERC721: token not minted yet");
    address owner = ownerOf(tokenId);
    require(_balances[owner] > 0); // Avoid overflow

    // Clear approvals
    _approve(address(0), tokenId);

    _balances[owner] -= 1;
    delete _tokenOwners[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }

  /**
   * @dev Internal function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI},
   * or to the token ID if {tokenURI} is empty.
   */
  function _setBaseURI(string memory baseURI_) internal {
    _baseURI = baseURI_;
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
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          // solhint-disable-next-line no-inline-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  function _approve(address to, uint256 tokenId) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }
}