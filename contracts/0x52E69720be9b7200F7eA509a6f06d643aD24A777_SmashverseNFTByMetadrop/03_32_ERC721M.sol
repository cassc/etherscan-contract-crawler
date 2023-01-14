// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
// EPS implementation
import "../EPS/IEPS_DR.sol";
import "../EPS/IEPS_CT.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721M is Context, ERC165, IERC721, IERC721Metadata, ERC2981 {
  using Address for address;
  using Strings for uint256;

  // EPS Compose This
  IEPS_CT public epsComposeThis;
  // EPS Delegation Register
  IEPS_DR public epsDeligateRegister;

  // Use of a burn address other than address(0) to allow easy enumeration
  // of burned tokens
  address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  uint256 public immutable maxSupply;

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

  // Vesting mapping
  mapping(uint256 => uint256) public vestingEndDateForToken;

  // Staking mapping
  mapping(uint256 => uint256) public stakingEndDateForToken;

  uint256 public remainingSupply;

  error CallerNotTokenOwnerOrApproved();
  error CannotStakeForZeroDays();
  error InvalidToken();
  error QuantityExceedsRemainingSupply();

  /**
   * @dev Emitted when `owner` stakes a token
   */
  event TokenStaked(
    address indexed staker,
    uint256 indexed tokenId,
    uint256 indexed stakingEndDate
  );

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxSupply_,
    address epsDeligateRegister_,
    address epsComposeThis_
  ) {
    _name = name_;
    _symbol = symbol_;
    maxSupply = maxSupply_;
    remainingSupply = maxSupply_;
    epsDeligateRegister = IEPS_DR(epsDeligateRegister_);
    epsComposeThis = IEPS_CT(epsComposeThis_);
  }

  /**
   * ================================
   * @dev ERC721M new functions begins
   * ================================
   */

  /**
   *
   *
   * @dev Returns total supply (minted - burned)
   *
   *
   */
  function totalSupply() external view returns (uint256) {
    return totalMinted() - totalBurned();
  }

  /**
   * @dev Returns the remaining supply
   */
  function totalUnminted() public view returns (uint256) {
    return remainingSupply;
  }

  /**
   * @dev Returns the total number of tokens ever minted
   */
  function totalMinted() public view returns (uint256) {
    return (maxSupply - remainingSupply);
  }

  /**
   * @dev Returns the count of tokens sent to the burn address
   */
  function totalBurned() public view returns (uint256) {
    return ERC721M.balanceOf(BURN_ADDRESS);
  }

  /**
   * @dev _setTokenVestingDate
   */
  function _setTokenVestingDate(uint256 tokenId_, uint256 vestingDuration_)
    internal
    virtual
  {
    if (vestingDuration_ != 0) {
      uint256 vestingEndDate = block.timestamp + (vestingDuration_ * 1 days);
      vestingEndDateForToken[tokenId_] = vestingEndDate;
      epsComposeThis.triggerMetadataUpdate(
        block.chainid,
        address(this),
        tokenId_,
        vestingEndDate
      );
    }
  }

  /**
   * @dev _setTokenStakingDate
   */
  function _setTokenStakingDate(uint256 tokenId_, uint256 stakingDuration_)
    internal
    virtual
  {
    if (!(_isApprovedOrOwner(_msgSender(), tokenId_))) {
      revert CallerNotTokenOwnerOrApproved();
    }

    // Clear token level approval if it exists. ApprovalForAll will not be
    // valid while staked as this contract will be the owner, but token level
    // approvals would persist, so must be removed
    if (_tokenApprovals[tokenId_] != address(0)) {
      _approve(address(0), tokenId_);
    }

    if (stakingDuration_ == 0) {
      revert CannotStakeForZeroDays();
    }

    uint256 stakingEndDate = block.timestamp + (stakingDuration_ * 1 days);
    stakingEndDateForToken[tokenId_] = stakingEndDate;
    epsComposeThis.triggerMetadataUpdate(
      block.chainid,
      address(this),
      tokenId_,
      stakingEndDate
    );
    emit TokenStaked(_msgSender(), tokenId_, stakingEndDate);
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function stakedOwnerOf(uint256 tokenId)
    public
    view
    virtual
    returns (address)
  {
    if (stakingEndDateForToken[tokenId] > block.timestamp) {
      address tokenOwner = _owners[tokenId];
      if (tokenOwner == address(0)) {
        revert InvalidToken();
      }
      return tokenOwner;
    } else {
      return address(0);
    }
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function vestedOwnerOf(uint256 tokenId)
    public
    view
    virtual
    returns (address)
  {
    if (vestingEndDateForToken[tokenId] > block.timestamp) {
      address tokenOwner = _owners[tokenId];
      if (tokenOwner == address(0)) {
        revert InvalidToken();
      }
      return tokenOwner;
    } else {
      return address(0);
    }
  }

  /**
   * @dev _mintIdWithoutBalanceUpdate
   */
  function _mintIdWithoutBalanceUpdate(address to, uint256 tokenId) private {
    _beforeTokenTransfer(address(0), to, tokenId);

    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  /**
   * @dev _mintSequential
   */
  function _mintSequential(
    address to_,
    uint256 quantity_,
    uint256 vestingDuration_
  ) internal virtual {
    if (quantity_ > remainingSupply) {
      revert QuantityExceedsRemainingSupply();
    }

    require(_checkOnERC721Received(address(0), to_, 1, ""), "Not receiver");

    uint256 tokenId = maxSupply - remainingSupply;

    for (uint256 i = 0; i < quantity_; ) {
      _mintIdWithoutBalanceUpdate(to_, tokenId + i);

      _setTokenVestingDate(tokenId + i, vestingDuration_);

      unchecked {
        i++;
      }
    }

    remainingSupply = remainingSupply - quantity_;
    _balances[to_] += quantity_;
  }

  /**
   * ================================
   * @dev ERC721M new functions end
   * ================================
   */

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165, ERC2981)
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
    require(owner != address(0), "Address 0");
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
    // Check for staking or vesting:
    if (
      stakingEndDateForToken[tokenId] > block.timestamp ||
      vestingEndDateForToken[tokenId] > block.timestamp
    ) {
      return (address(this));
    } else {
      address tokenOwner = _owners[tokenId];
      if (tokenOwner == address(0)) {
        revert InvalidToken();
      }
      return tokenOwner;
    }
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

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721M.ownerOf(tokenId);
    require(to != owner, "Approval to owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "Not owner or approved"
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
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved");

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
    require(_isApprovedOrOwner(_msgSender(), tokenId), "Not owner or approved");
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
    require(_checkOnERC721Received(from, to, tokenId, data), "Not receiver");
  }

  /**
   * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
   */
  function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
    return _owners[tokenId];
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
    return _ownerOf(tokenId) != address(0);
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
    address owner = ERC721M.ownerOf(tokenId);
    return (spender == owner ||
      isApprovedForAll(owner, spender) ||
      getApproved(tokenId) == spender);
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, data),
      "Not receiver"
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
  function _mint(address to, uint256 tokenId) internal virtual {
    require(to != address(0), "Mint to 0 address");
    require(!_exists(tokenId), "Exists");

    _beforeTokenTransfer(address(0), to, tokenId);

    // Check that tokenId was not minted by `_beforeTokenTransfer` hook
    require(!_exists(tokenId), "Exists");

    unchecked {
      // Will not overflow unless all 2**256 token ids are minted to the same owner.
      // Given that tokens are minted one by one, it is impossible in practice that
      // this ever happens. Might change if we allow batch minting.
      // The ERC fails to describe this case.
      _balances[to] += 1;
    }

    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   * This is an internal function that does not check if the sender is authorized to operate on the token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address tokenOwner = ERC721M.ownerOf(tokenId);

    _beforeTokenTransfer(tokenOwner, BURN_ADDRESS, tokenId);

    // Clear approvals
    delete _tokenApprovals[tokenId];

    _balances[tokenOwner] -= 1;
    _owners[tokenId] = BURN_ADDRESS;
    _balances[BURN_ADDRESS] += 1;

    emit Transfer(tokenOwner, BURN_ADDRESS, tokenId);

    _afterTokenTransfer(tokenOwner, BURN_ADDRESS, tokenId);
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
    require(ERC721M.ownerOf(tokenId) == from, "Not owner");
    require(to != address(0), "Tfr to 0 address");

    _beforeTokenTransfer(from, to, tokenId);

    // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
    require(ERC721M.ownerOf(tokenId) == from, "Not owner");

    // Clear approvals from the previous owner
    delete _tokenApprovals[tokenId];

    unchecked {
      // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
      // `from`'s balance is the number of token held, which is at least one before the current
      // transfer.
      // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
      // all 2**256 token ids to be minted, which in practice is impossible.
      _balances[from] -= 1;
      _balances[to] += 1;
    }
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721M.ownerOf(tokenId), to, tokenId);
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
    require(owner != operator, "Approve to caller");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _requireMinted(uint256 tokenId) internal view virtual {
    require(_exists(tokenId), "Invalid Token");
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
          revert("ERC721: transfer to non ERC721Receiver implementer");
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

  /**
   * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
   * - When `from` is zero, the tokens will be minted for `to`.
   * - When `to` is zero, ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  /**
   * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
   * - When `from` is zero, the tokens were minted for `to`.
   * - When `to` is zero, ``from``'s tokens were burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}