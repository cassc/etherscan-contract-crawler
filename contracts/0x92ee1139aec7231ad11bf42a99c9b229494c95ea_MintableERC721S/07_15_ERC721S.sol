// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Gas-efficient implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard,
 * including the Metadata extension and the Enumerable extension
 *
 * @dev Only allows token IDs are minted serially starting from token ID 1
 *
 * @dev Does not support burning tokens or in any way changing the ownership of a token
 *      to address(0)
 */
contract ERC721S is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
  using Address for address;
  using Strings for uint256;

  /**
   * @dev Stores the name of the token as specified in the constructor
   */
  string private _name;

  /**
   * @dev Stores the symbol of the token as specified in the constructor
   */
  string private _symbol;

  /**
   * @dev Maps token ID to address owner
   *
   * @dev `_owners[0] == address(0)` will always be true since minting
   *      starts from token ID 1
   *
   * @dev If `_owners[n] == address(0)` and also `nextId > n`, then ownership
   *      of `n` is attributed to the owner of the previous token ID `_owners[n - 1]`
   */
  mapping(uint256 => address) private _owners;

  /**
   * @dev Maps token ID to approved address
   *
   * @dev Token owners can call {approve} to approve
   *      an address to trade their token on their behalf
   *
   * @dev Is reset each time an NFTs gets transfered
   */
  mapping(uint256 => address) private _tokenApprovals;

  /**
   * @dev Maps owners to operator approvals that can transfer
   *      any of the owner's tokens on his behalf
   *
   * @dev Mutated via {setApprovalForAll}
   */
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev Next sequential token ID to be minted
   *
   * @dev Starts at 1 and is incremented by {_mint}
   */
  uint256 public nextId = 1;

  /**
   * @dev Initializes the contract by setting a `name` and `symbol` to the token collection.
   *
   * @param name_ Name of token
   * @param name_ Symbol of token
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(owner != address(0), "ERC721S: balance query for the zero address");

    uint256 count = 0;

    for(uint256 i = 1; _exists(i); i++) {
      if(_owners[i] == owner) {
        count++;
        if(_owners[i + 1] == address(0) && _exists(i + 1)) count++;
      }
    }

    return count;
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    require(_exists(tokenId), "ERC721S: owner query for nonexistent token");

    return _owners[tokenId] != address(0) ? _owners[tokenId] : _owners[tokenId - 1];
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
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721S: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721S: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    require(_exists(tokenId), "ERC721S: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
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
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721S: transfer caller is not owner nor approved");

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
    bytes memory _data
  ) public virtual override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721S: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 Srotocol to prevent tokens from being forever locked.
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
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721S: transfer to non ERC721Receiver implementer");
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return tokenId != 0 && tokenId < nextId;
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    require(_exists(tokenId), "ERC721S: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  /**
   * @dev Safely mints the token with next consecutive ID and transfers it to `to`. Setting
   *      `amount` to `true` will mint another nft.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `maxTotalSupply` maximum total supply has not been reached
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, bool amount) internal virtual {
    _safeMint(to, amount, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    bool amount,
    bytes memory _data
  ) internal virtual {
    _mint(to, amount);

    uint256 n = !amount ? 1 : 2;

    for(uint256 i = 0; i < n; i++) {
      require(
        _checkOnERC721Received(address(0), to, nextId - i - 1, _data),
        "ERC721S: transfer to non ERC721Receiver implementer"
      );
    }
  }

  /**
   * @dev Mints the token with next consecutive ID and transfers it to `to`. Setting
   *      `amount` to `true` will mint another nft.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `maxTotalSupply` maximum total supply has not been reached
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, bool amount) internal virtual {
    // The below calculations do not depend on user input and
    // are very hard to overflow (nextId must be >= 2^256-2 for
    // that to happen) so using `unchecked` as a means of saving
    // gas is safe here
    unchecked {
      require(to != address(0), "ERC721S: mint to the zero address");

      uint256 n = !amount ? 1 : 2;

      _owners[nextId] = to;

      for(uint256 i = 0; i < n; i++) {
        _beforeTokenTransfer(address(0), to, nextId + i);
        emit Transfer(address(0), to, nextId + i);
      }

      nextId += n;
    }
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
    // The below calculations are very hard to overflow (nextId must
    // be = 2^256-1 for that to happen) so using `unchecked` as
    // a means of saving gas is safe here
    unchecked {
      require(
        ownerOf(tokenId) == from,
        "ERC721S: transfer of token that is not own"
      );
      require(to != address(0), "ERC721S: transfer to the zero address");

      _beforeTokenTransfer(from, to, tokenId);

      // Clear approvals from the previous owner
      _approve(address(0), tokenId);

      if(_owners[tokenId] == address(0)) {
        _owners[tokenId] = to;
      } else {
        _owners[tokenId] = to;

        if(_exists(tokenId + 1) && _owners[tokenId + 1] == address(0)) {
          _owners[tokenId + 1] = from;
        }
      }

      emit Transfer(from, to, tokenId);
    }
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
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
    require(owner != operator, "ERC721S: approve to caller");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
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
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721S: transfer to non ERC721Receiver implementer");
        } else {
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
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  /**
   * @dev See {IEnumerableERC721-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return nextId - 1;
  }

  /**
   * @dev See {IEnumerableERC721-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) external view returns (uint256) {
    require(_exists(index + 1), "ERC721S: global index out of bounds");

    return index + 1;
  }

  /**
   * @dev See {IEnumerableERC721-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
    require(owner != address(0), "ERC721S: balance query for the zero address");

    uint256 count = 0;
    uint256 i = 1;

    for(; _exists(i) && count < index + 1; i++) {
      if(_owners[i] == owner) {
        count++;
        if(_owners[i + 1] == address(0) && count < index + 1 && _exists(i + 1)) {
          count++;
          i++;
        }
      }
    }

    if(count == index + 1) return i - 1;
    else revert("ERC721S: owner index out of bounds");
  }
}