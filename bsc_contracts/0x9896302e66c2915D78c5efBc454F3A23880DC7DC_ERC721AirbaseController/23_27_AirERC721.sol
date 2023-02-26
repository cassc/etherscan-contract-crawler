// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IAirERC721.sol";
import "../../Ownable.sol";

contract AirERC721 is Ownable, ERC165, IAirERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Token counter
  uint256 private _tokenCounter;

  // Minter
  mapping(address => bool) private _minters;

  // Default allow transfer
  bool private _transferable = true;

  // Base token URI
  string private _baseURI;

  modifier onlyMinter() {
    require(_minters[msg.sender], "ERC721:must-be-minter");
    _;
  }

  modifier onlyTransferable() {
    require(_transferable, "ERC721:is-not-transferable");
    _;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_,
    address _minter,
    bool transferable_
  ) Ownable(msg.sender) {
    _name = name_;
    _symbol = symbol_;
    _minters[_minter] = true;
    _transferable = transferable_;
    _baseURI = baseURI_;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) 
    public 
    view 
    virtual 
    override 
    returns (uint256) 
    {
    require(owner != address(0), "ERC721:owner-must-be-non-zero-address");
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    address owner = _owners[tokenId];
    require(owner != address(0), "ERC721:invalid-token-id");
    return owner;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    _requireMinted(tokenId);

    return
      bytes(_baseURI).length > 0
        ? string(abi.encodePacked(_baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = AirERC721.ownerOf(tokenId);
    require(to != owner, "ERC721:cannot-approve-to-current-owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721:caller-must-be-token-owner-or-approved-all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    _requireMinted(tokenId);

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721:caller-must-be-token-owner-or-approved"
    );

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721:caller-must-be-token-owner-or-approved"
    );
    _safeTransfer(from, to, tokenId, data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, data),
      "ERC721:target-cannot-receive-ERC721"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    address owner = AirERC721.ownerOf(tokenId);
    return (spender == owner ||
      isApprovedForAll(owner, spender) ||
      getApproved(tokenId) == spender);
  }

  function mint(address to) external override onlyMinter {
    require(to != address(0), "ERC721:receiver-must-be-non-zero-address");
    _tokenCounter = _tokenCounter + 1;
    _balances[to] += 1;
    _owners[_tokenCounter] = to;

    require(
      _checkOnERC721Received(address(0), to, _tokenCounter, ""),
      "ERC721:target-cannot-receive-ERC721"
    );

    emit Transfer(address(0), to, _tokenCounter);
  }

  function mintBatch(address to, uint256 amount) external override onlyMinter {
    require(to != address(0), "ERC721:receiver-must-be-non-zero-address");

    for (uint256 i = 1; i <= amount; i++) {
      uint256 tokenId = _tokenCounter + i;
      _owners[tokenId] = to;
      emit Transfer(address(0), to, tokenId);
    }

    _balances[to] += amount;
    _tokenCounter = _tokenCounter + amount;
  }

  function burn(address account, uint256 tokenId) external override onlyMinter {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721:caller-must-be-token-owner-or-be-approved-by-token-owner"
    );

    address owner = ownerOf(tokenId);

    require(account == owner, "ERC721:must-be-token-owner");

    // Clear approvals
    _approve(address(0), tokenId);

    _balances[owner] -= 1;
    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }

  function burnBatch(address account, uint256[] calldata tokenIds)
    external
    override
    onlyMinter
  {
    _balances[account] -= tokenIds.length;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(
        _isApprovedOrOwner(_msgSender(), tokenId),
        "ERC721:caller-must-be-token-owner-or-be-approved-by-token-owner"
      );
      address owner = ownerOf(tokenId);

      require(account == owner, "ERC721:must-be-token-owner");
      // Clear approvals
      _approve(address(0), tokenId);

      delete _owners[tokenId];
      emit Transfer(account, address(0), tokenId);
    }
  }

  function setBaseURI(string calldata newURI) external onlyOwner {
    _baseURI = newURI;
  }

  function setTransferable(bool transferable_) external onlyOwner {
    _transferable = transferable_;
  }

  function setName(string calldata name_) external onlyOwner {
    _name = name_;
  }

  function setSymbol(string calldata symbol_) external onlyOwner {
    _symbol = symbol_;
  }

  /**
   * @dev Add a new minter.
   */
  function addMinter(address minter) external onlyOwner {
    require(minter != address(0), "ERC721:minter-must-be-non-zero-address");
    require(!_minters[minter], "ERC721:minter-already-added");
    _minters[minter] = true;
    emit AddMinter(minter);
  }

  /**
   * @dev Remove a old minter.
   */
  function removeMinter(address minter) external onlyOwner {
    require(_minters[minter], "ERC721:must-be-minter");
    delete _minters[minter];
    emit RemoveMinter(minter);
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
  ) internal virtual {
    require(AirERC721.ownerOf(tokenId) == from, "ERC721:must-be-token-owner");
    require(to != address(0), "ERC721:target-must-be-non-zero-address");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(AirERC721.ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits an {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, "ERC721:owner-must-be-different-from-operator");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _requireMinted(uint256 tokenId) internal view virtual {
    require(_exists(tokenId), "ERC721:invalid-token-id");
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721:target-cannot-receive-ERC721");
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }
}