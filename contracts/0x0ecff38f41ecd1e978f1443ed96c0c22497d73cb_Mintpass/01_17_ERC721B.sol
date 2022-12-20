// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error InvalidCall();
error BalanceQueryZeroAddress();
error NonExistentToken();
error ApprovalToCurrentOwner();
error ApprovalOwnerIsOperator();
error NotERC721Receiver();
error ERC721ReceiverNotReceived();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] 
 * Non-Fungible Token Standard, including the Metadata extension and 
 * token Auto-ID generation.
 *
 * You must provide `name()` `symbol()` and `tokenURI(uint256 tokenId)`
 * to conform with IERC721Metadata
 */
abstract contract ERC721B is Context, ERC165, IERC721 {

  // ============ Storage ============

  // The last token id minted
  uint256 private _lastTokenId;
  // Mapping from token ID to owner address
  mapping(uint256 => address) internal _owners;
  // Mapping owner address to token count
  mapping(address => uint256) internal _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;
  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // ============ Read Methods ============

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) 
    public view virtual override returns(uint256) 
  {
    if (owner == address(0)) revert BalanceQueryZeroAddress();
    return _balances[owner];
  }

  /**
   * @dev Shows the overall amount of tokens generated in the contract
   */
  function totalSupply() public view virtual returns(uint256) {
    return _lastTokenId;
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) 
    public view virtual override returns(address) 
  {
    unchecked {
      //this is the situation when _owners normalized
      uint256 id = tokenId;
      if (_owners[id] != address(0)) {
        return _owners[id];
      }
      //this is the situation when _owners is not normalized
      if (id > 0 && id <= _lastTokenId) {
        //there will never be a case where token 1 is address(0)
        while(true) {
          id--;
          if (id == 0) {
            break;
          } else if (_owners[id] != address(0)) {
            return _owners[id];
          }
        }
      }
    }

    revert NonExistentToken();
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) 
    public view virtual override(ERC165, IERC165) returns(bool) 
  {
    return interfaceId == type(IERC721).interfaceId
      || super.supportsInterface(interfaceId);
  }

  // ============ Approval Methods ============

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721B.ownerOf(tokenId);
    if (to == owner) revert ApprovalToCurrentOwner();

    address sender = _msgSender();
    if (sender != owner && !isApprovedForAll(owner, sender)) 
      revert ApprovalToCurrentOwner();

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) 
    public view virtual override returns(address) 
  {
    if (!_exists(tokenId)) revert NonExistentToken();
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) 
    public view virtual override returns (bool) 
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) 
    public virtual override 
  {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId, address owner) 
    internal virtual 
  {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev transfers token considering approvals
   */
  function _approveTransfer(
    address spender, 
    address from, 
    address to, 
    uint256 tokenId
  ) internal virtual {
    if (!_isApprovedOrOwner(spender, tokenId, from)) 
      revert InvalidCall();

    _transfer(from, to, tokenId);
  }

  /**
   * @dev Safely transfers token considering approvals
   */
  function _approveSafeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _approveTransfer(_msgSender(), from, to, tokenId);
    //see: @openzep/utils/Address.sol
    if (to.code.length > 0
      && !_checkOnERC721Received(from, to, tokenId, _data)
    ) revert ERC721ReceiverNotReceived();
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(
    address spender, 
    uint256 tokenId, 
    address owner
  ) internal view virtual returns(bool) {
    return spender == owner 
      || getApproved(tokenId) == spender 
      || isApprovedForAll(owner, spender);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits a {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    if (owner == operator) revert ApprovalOwnerIsOperator();
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  // ============ Mint Methods ============

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} 
   * whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(
    address to,
    uint256 amount,
    bytes memory _data,
    bool safeCheck
  ) private {
    if(amount == 0 || to == address(0)) revert InvalidCall();
    uint256 startTokenId = _lastTokenId + 1;
    
    _beforeTokenTransfers(address(0), to, startTokenId, amount);
    
    unchecked {
      _lastTokenId += amount;
      _balances[to] += amount;
      _owners[startTokenId] = to;

      _afterTokenTransfers(address(0), to, startTokenId, amount);

      uint256 updatedIndex = startTokenId;
      uint256 endIndex = updatedIndex + amount;
      //if do safe check and,
      //check if contract one time (instead of loop)
      //see: @openzep/utils/Address.sol
      if (safeCheck && to.code.length > 0) {
        //loop emit transfer and received check
        do {
          emit Transfer(address(0), to, updatedIndex);
          if (!_checkOnERC721Received(address(0), to, updatedIndex++, _data))
            revert ERC721ReceiverNotReceived();
        } while (updatedIndex != endIndex);
        return;
      }

      do {
        emit Transfer(address(0), to, updatedIndex++);
      } while (updatedIndex != endIndex);
    }
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement 
   *   {IERC721Receiver-onERC721Received}, which is called upon a 
   *   safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 amount) internal virtual {
    _safeMint(to, amount, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], 
   * with an additional `data` parameter which is forwarded in 
   * {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 amount,
    bytes memory _data
  ) internal virtual {
    _mint(to, amount, _data, true);
  }

  // ============ Transfer Methods ============

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    _approveTransfer(_msgSender(), from, to, tokenId);
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
    bytes memory _data
  ) public virtual override {
    _approveSafeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} 
   * on a target address. The call is not executed if the target address 
   * is not a contract.
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try IERC721Receiver(to).onERC721Received(
      _msgSender(), from, tokenId, _data
    ) returns (bytes4 retval) {
      return retval == IERC721Receiver.onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert NotERC721Receiver();
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via 
   * {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return tokenId > 0 && tokenId <= _lastTokenId;
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking 
   * first that contract recipients are aware of the ERC721 protocol to 
   * prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is 
   * sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can 
   * be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as 
   * signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement 
   *   {IERC721Receiver-onERC721Received}, which is called upon a 
   *   safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    //see: @openzep/utils/Address.sol
    if (to.code.length > 0
      && !_checkOnERC721Received(from, to, tokenId, _data)
    ) revert ERC721ReceiverNotReceived();
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`. As opposed to 
   * {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(address from, address to, uint256 tokenId) private {
    //if transfer to null or not the owner
    if (to == address(0) || from != ERC721B.ownerOf(tokenId)) 
      revert InvalidCall();

    _beforeTokenTransfers(from, to, tokenId, 1);
    
    // Clear approvals from the previous owner
    _approve(address(0), tokenId, from);

    unchecked {
      //this is the situation when _owners are normalized
      _balances[to] += 1;
      _balances[from] -= 1;
      _owners[tokenId] = to;
      //this is the situation when _owners are not normalized
      uint256 nextTokenId = tokenId + 1;
      if (nextTokenId <= _lastTokenId && _owners[nextTokenId] == address(0)) {
        _owners[nextTokenId] = from;
      }
    }

    _afterTokenTransfers(from, to, tokenId, 1);
    emit Transfer(from, to, tokenId);
  }

  // ============ TODO Methods ============

  /**
   * @dev Hook that is called before a set of serially-ordered token ids 
   * are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * amount - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` 
   *   will be transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids 
   * have been transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * amount - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 amount
  ) internal virtual {}
}