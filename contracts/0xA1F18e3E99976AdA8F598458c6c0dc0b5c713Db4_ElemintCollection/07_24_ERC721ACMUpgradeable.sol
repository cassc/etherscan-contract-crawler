// SPDX-License-Identifier: MIT
// Creator: Elemint Team

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./IERC721ConsecutiveTransfer.sol";

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721ACMUpgradeable is
  Initializable,
  ContextUpgradeable,
  ERC165Upgradeable,
  IERC721Upgradeable,
  IERC721MetadataUpgradeable,
  IERC721EnumerableUpgradeable,
  IERC721ConsecutiveTransfer
{
  using AddressUpgradeable for address;
  using StringsUpgradeable for uint256;

  enum URIType {
    FULL,
    BASE,
    CID,
    EMPTY
  }

  // Compiler will pack this into a single 256bit word.
  struct TokenOwnership {
    // The address of the owner.
    address addr;
    // indexOfTokenInOwner
    uint64 indexInOwner;
  }

  struct TokenURIData {
    // empty string mean URI is URI of the last prev tokenId
    // if URI start by `ipfs://` or `http://` `https://` and end by / => this is baseURI
    // if URI start by `ipfs://` or `http://` `https://` and not end by / => this is full URI
    // if URI not start by `ipfs://` or `http://` `https://`  => this is CID
    string baseURI;
    // this make metadata file name can be start from 0 for each batch
    uint64 startIndex;
  }

  /// @dev This is max empty segment length can be in `_tokensURI`
  // this will impact batch mint gas fee
  uint16 private _baseUriBacktrackLength;

  // Default owner
  address private _defaultOwner;

  // DefaultOwner balance; NOTE: defaultOwner have it own mechanic to manage balance and NFT
  uint64 private _defaultOwnerBalance;

  // The tokenId of the next token to be minted.
  uint256 internal _currentIndex;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) internal _ownerships;

  // old _addressData slot
  //slither-disable-next-line constable-states
  uint256 private _emptySlot;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Mapping from tokenId to ipfs URI
  mapping(uint256 => TokenURIData) private _tokensURI;

  // Mapping from owner to tokenId array list
  mapping(address => uint64[]) private _tokensOfOwner;

  uint256 public baseTokenId;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  //solhint-disable-next-line func-name-mixedcase
  function __ERC721ACM_init(
    string memory name_,
    string memory symbol_,
    address defaultOwner,
    uint16 baseUriBacktrackLength,
    uint256 baseTokenId_
  ) internal onlyInitializing {
    _name = name_;
    _symbol = symbol_;
    _defaultOwner = defaultOwner;
    _baseUriBacktrackLength = baseUriBacktrackLength;
    baseTokenId = baseTokenId_;
    _currentIndex = baseTokenId_;
  }

  function _setDefaultOwner(address nextDefaultOwner) internal {
    require(nextDefaultOwner != address(0));
    _defaultOwner = nextDefaultOwner;

    /// @dev move all NFT of nextDefaultOwner to defaultOwner store
    for (uint64 i = 0; i < _tokensOfOwner[nextDefaultOwner].length; i++) {
      uint64 tokenId = _tokensOfOwner[nextDefaultOwner][i];
      _ownerships[tokenId].addr = address(0);
      _tokensOfOwner[nextDefaultOwner][i] = 0;
    }

    // inc balance of defaultOwner
    _defaultOwnerBalance += uint64(_tokensOfOwner[nextDefaultOwner].length);

    // clear array `_tokensOfOwner[nextDefaultOwner]` to empty
    uint64[] storage temp = _tokensOfOwner[nextDefaultOwner];
    //solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(temp.slot, 0)
    }
  }

  function _getDefaultOwner() internal view returns (address) {
    return _defaultOwner;
  }

  function _setName(string memory name_) internal {
    _name = name_;
  }

  function _setSymbol(string memory symbol_) internal {
    _symbol = symbol_;
  }

  function _setBaseUriBacktrackLength(uint16 baseUriBacktrackLength) internal {
    _baseUriBacktrackLength = baseUriBacktrackLength;
  }

  function _getBaseUriBacktrackLength() internal view returns (uint16) {
    return _baseUriBacktrackLength;
  }

  function _getTokensURIMap(uint64 tokenId) internal view returns (string memory, uint64) {
    return (_tokensURI[tokenId].baseURI, _tokensURI[tokenId].startIndex);
  }

  function _setTokensURIMap(
    uint64 tokenId,
    string memory uri,
    uint64 startIndex
  ) internal {
    _tokensURI[tokenId].baseURI = uri;
    _tokensURI[tokenId].startIndex = startIndex;
  }

  /**
   * @dev .
   */
  function totalSupply() public view returns (uint256) {
    unchecked {
      return _currentIndex - baseTokenId;
    }
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    if (index >= totalSupply()) revert TokenIndexOutOfBounds();

    return index + baseTokenId;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is heavy with defaultOwner.
   * If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
    if (owner != _defaultOwner) {
      return _tokensOfOwner[owner][index];
    } else {
      unchecked {
        uint64 tokenIdsIdx = 0;
        for (uint256 tokenId = baseTokenId; tokenId < _currentIndex; tokenId++) {
          if (_ownerships[tokenId].addr == address(0) || _ownerships[tokenId].addr == _defaultOwner) {
            if (tokenIdsIdx == index) {
              return tokenId;
            }
            tokenIdsIdx++;
          }
        }
      }
    }
    revert();
  }

  /**
   * @dev this function use to optimize get NFT list of default owner
   */
  function tokenOfDefaultOwner(uint256 startSearchTokenId) public view returns (uint256) {
    if (startSearchTokenId < baseTokenId || startSearchTokenId >= _currentIndex) revert TokenIndexOutOfBounds();
    unchecked {
      for (uint256 tokenId = startSearchTokenId; tokenId < _currentIndex; tokenId++) {
        if ((_ownerships[tokenId].addr == address(0) || _ownerships[tokenId].addr == _defaultOwner)) {
          return tokenId;
        }
      }
    }
    revert();
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165Upgradeable, IERC165Upgradeable)
    returns (bool)
  {
    return
      interfaceId == type(IERC721Upgradeable).interfaceId ||
      interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
      interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    if (owner == address(0)) revert BalanceQueryForZeroAddress();
    if (owner == _defaultOwner) {
      return _defaultOwnerBalance;
    } else {
      return uint256(_tokensOfOwner[owner].length);
    }
  }

  /**
   *
   */
  function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
    if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

    TokenOwnership memory ownership = _ownerships[tokenId];
    if (ownership.addr == address(0)) {
      ownership.addr = _defaultOwner;
      return ownership;
    }
    return ownership;
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return _ownershipOf(tokenId).addr;
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

  function getURIType(bytes memory uri) internal pure returns (URIType) {
    if (uri.length == 0) return URIType.EMPTY;
    bytes4 protocol = bytes4(uri);
    if (protocol == bytes4("ipfs") || protocol == bytes4("http")) {
      if (uri[uri.length - 1] == bytes1("/")) {
        return URIType.BASE;
      } else {
        return URIType.FULL;
      }
    }
    return URIType.CID;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
    bytes memory uri = bytes(_tokensURI[tokenId].baseURI);
    uint256 metadataIndex = _tokensURI[tokenId].startIndex;
    if (uri.length == 0) {
      // backtrack search
      unchecked {
        bytes memory uriTmp;
        for (uint256 i = tokenId - 1; i >= baseTokenId; i--) {
          uriTmp = bytes(_tokensURI[i].baseURI);
          URIType uriTypeTmp = getURIType(bytes(uriTmp));
          if (uriTypeTmp == URIType.BASE || uriTypeTmp == URIType.CID) {
            uri = uriTmp;
            metadataIndex = _tokensURI[i].startIndex + (tokenId - i);
            break;
          }
        }
      }
    }

    URIType uriType = getURIType(bytes(uri));

    if (uriType == URIType.BASE) {
      return string(abi.encodePacked(uri, metadataIndex.toString()));
    } else if (uriType == URIType.CID) {
      return string(abi.encodePacked("ipfs://", uri, "/", metadataIndex.toString()));
    } else if (uriType == URIType.FULL) {
      return string(uri);
    }

    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ownerOf(tokenId);
    if (to == owner) revert ApprovalToCurrentOwner();

    if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
      revert ApprovalCallerNotOwnerNorApproved();
    }

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    if (operator == _msgSender()) revert ApproveToCaller();

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
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
    _transfer(from, to, tokenId);
    if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
      revert TransferToNonERC721ReceiverImplementer();
    }
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return (tokenId >= baseTokenId) && (tokenId < _currentIndex);
  }

  function _safeMint(
    address to,
    uint32 quantity,
    string memory uri,
    bool noConsecutiveTransfer
  ) internal {
    _safeMint(to, quantity, uri, "", noConsecutiveTransfer);
  }

  /**
   * @dev Safely mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, 
            it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint32 quantity,
    string memory uri,
    bytes memory _data,
    bool noConsecutiveTransfer
  ) internal {
    _mint(to, quantity, uri, _data, true, noConsecutiveTransfer);
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
        This will be expensive when mint to address that is not defaultowner
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} or {ConsecutiveTransfer} event.
   */
  function _mint(
    address to,
    uint32 quantity,
    string memory uri,
    bytes memory _data,
    bool safe,
    bool noConsecutiveTransfer
  ) internal {
    uint256 startTokenId = _currentIndex;
    if (to == address(0)) revert MintToZeroAddress();
    if (quantity == 0) revert MintZeroQuantity();
    require(bytes(uri).length > 0);

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    // Overflows are incredibly unrealistic.
    // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
    // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
    unchecked {
      if (to == _defaultOwner) {
        _defaultOwnerBalance += quantity;
      }

      // write URI
      for (uint64 i = 0; i < quantity; i += _baseUriBacktrackLength) {
        _tokensURI[startTokenId + i].baseURI = uri;
        _tokensURI[startTokenId + i].startIndex = i;
      }

      // modify _tokensOfOwner and _indexOfTokenInOwner if `to` is not defaultOwner
      if (to != _defaultOwner) {
        uint64 oldLength = uint64(_tokensOfOwner[to].length);
        for (uint64 tokenId = uint64(startTokenId); tokenId < startTokenId + quantity; tokenId++) {
          _ownerships[tokenId].addr = to;
          _ownerships[tokenId].indexInOwner = uint64(oldLength);
          _tokensOfOwner[to].push(tokenId);

          if (safe && to.isContract()) {
            if (!_checkContractOnERC721Received(address(0), to, tokenId, _data)) {
              revert TransferToNonERC721ReceiverImplementer();
            }
          }

          oldLength++;
        }
      }

      // increase `_currentIndex` and emit EVENT
      uint256 updatedIndex = startTokenId + quantity;
      URIType uriType = getURIType(bytes(uri));
      if (quantity > 1) {
        require(uriType == URIType.BASE || uriType == URIType.CID);
        if (noConsecutiveTransfer) {
          for (uint64 tokenId = uint64(startTokenId); tokenId < updatedIndex; tokenId++) {
            emit Transfer(address(0), to, tokenId);
          }
        } else {
          emit ConsecutiveTransfer(startTokenId, updatedIndex - 1, address(0), to);
        }
      } else {
        require(uriType == URIType.FULL || uriType == URIType.CID);
        emit Transfer(address(0), to, startTokenId);
      }
      _currentIndex = updatedIndex;
    }
    _afterTokenTransfers(address(0), to, startTokenId, uint64(quantity));
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
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
  ) private {
    TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

    if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

    bool isApprovedOrOwner = (_msgSender() == from ||
      isApprovedForAll(from, _msgSender()) ||
      getApproved(tokenId) == _msgSender());

    if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
    if (to == address(0)) revert TransferToZeroAddress();

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
    unchecked {
      if (from == _defaultOwner) {
        _defaultOwnerBalance -= 1;
      } else {
        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // update token in `from` list
        uint64 currentIndex = _ownerships[tokenId].indexInOwner;
        uint64 lastTokenOfFrom = _tokensOfOwner[from][_tokensOfOwner[from].length - 1];
        _tokensOfOwner[from][currentIndex] = lastTokenOfFrom;
        _ownerships[lastTokenOfFrom].indexInOwner = currentIndex;
        _tokensOfOwner[from].pop();
      }

      if (to == _defaultOwner) {
        _defaultOwnerBalance += 1;
        _ownerships[tokenId].addr = address(0);
      } else {
        // update token into `to` list
        _tokensOfOwner[to].push(uint64(tokenId));
        _ownerships[tokenId].addr = to;
        _ownerships[tokenId].indexInOwner = uint64(_tokensOfOwner[to].length) - 1;
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  //slither-disable-next-line unused-return
  function _checkContractOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
      return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert TransferToNonERC721ReceiverImplementer();
      } else {
        //solhint-disable-next-line no-inline-assembly
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. 
          This includes minting.
   * And also called before burning one token.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, `tokenId` will be burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   * And also called after one token has been burned.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
   * transferred to `to`.
   * - When `from` is zero, `tokenId` has been minted for `to`.
   * - When `to` is zero, `tokenId` has been burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}