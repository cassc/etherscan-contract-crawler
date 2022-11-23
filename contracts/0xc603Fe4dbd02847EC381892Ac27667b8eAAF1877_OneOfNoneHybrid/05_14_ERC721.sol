pragma solidity ^0.8.8;

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";


// solhint-disable-next-line indent
abstract contract ERC721 is IERC721Metadata, IERC721Enumerable, Context {
  using Address for address;

  mapping(uint256 => address) internal _owners;
  mapping (uint256 => address) internal _idToApproval;
  mapping (address => mapping (address => bool)) internal _ownerToOperators;

  uint256 internal _maxTokenId;

  /**
   * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
   * Based on 0xcert framework error codes.
   */
  string constant ZERO_ADDRESS = "003001";
  string constant NOT_VALID_NFT = "003002";
  string constant NOT_OWNER_OR_OPERATOR = "003003";
  string constant NOT_OWNER_APPROVED_OR_OPERATOR = "003004";
  string constant NOT_ABLE_TO_RECEIVE_NFT = "003005";
  string constant NFT_ALREADY_EXISTS = "003006";
  string constant NOT_OWNER = "003007";
  string constant IS_OWNER = "003008";

  /**
 * @dev Magic value of a smart contract that can receive NFT.
   * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
   */
  bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  constructor() {}

  /// @notice MARK: Useful modifiers

  /**
   * @dev Guarantees that the _msgSender() is an owner or operator of the given NFT.
   * @param tokenId ID of the NFT to validate.
   */
  modifier canOperate(uint256 tokenId) {
    address tokenOwner = _owners[tokenId];
    require(
      tokenOwner == _msgSender() || _ownerToOperators[tokenOwner][_msgSender()],
      NOT_OWNER_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that the _msgSender() is allowed to transfer NFT.
   * @param tokenId ID of the NFT to transfer.
   */
  modifier canTransfer(uint256 tokenId) {
    address tokenOwner = _owners[tokenId];

    require(
      tokenOwner == _msgSender()
      || _idToApproval[tokenId] == _msgSender()
      || _ownerToOperators[tokenOwner][_msgSender()],
      NOT_OWNER_APPROVED_OR_OPERATOR
    );
    _;
  }

  /**
   * @dev Guarantees that _tokenId is a valid Token.
   * @param tokenId ID of the NFT to validate.
   */
  modifier validNFToken(uint256 tokenId) {
    require(_exists(tokenId), NOT_VALID_NFT);
    _;
  }

  /// @notice Returns a number of decimal points
  /// @return Number of decimal points
  function decimals() public pure virtual returns (uint256) {
    return 0;
  }

  /// @notice MARK: ERC721 Implementation

  /// @notice Count all NFTs assigned to an owner
  /// @dev NFTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param owner An address for whom to query the balance
  /// @return balance The number of NFTs owned by `owner`, possibly zero
  function balanceOf(address owner) public view virtual returns (uint256 balance) {
    require(owner != address(0),  ZERO_ADDRESS);

    for (uint256 i; i <= _maxTokenId; i++) {
      if (_owners[i] == owner) {
        balance++;
      }
    }

    return balance;
  }

  /// @notice Find the owner of an NFT
  /// @dev NFTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param tokenId The identifier for an NFT
  /// @return owner The address of the owner of the NFT
  function ownerOf(uint256 tokenId) external view returns (address owner) {
    owner = _owners[tokenId];
    require(owner != address(0), NOT_VALID_NFT);
  }

  /// @notice Change or reaffirm the approved address for an NFT
  /// @dev The zero address indicates there is no approved address.
  ///  Throws unless `_msgSender()` is the current NFT owner, or an authorized
  ///  operator of the current owner.
  /// @param approved The new approved NFT controller
  /// @param tokenId The NFT to approve
  function approve(address approved, uint256 tokenId) external canOperate(tokenId) validNFToken(tokenId) {
    address tokenOwner = _owners[tokenId];
    require(approved != tokenOwner, IS_OWNER);

    _idToApproval[tokenId] = approved;
    emit Approval(tokenOwner, approved, tokenId);
  }

  /// @notice Get the approved address for a single NFT
  /// @dev Throws if `tokenId` is not a valid NFT.
  /// @param tokenId The NFT to find the approved address for
  /// @return The approved address for this NFT, or the zero address if there is none
  function getApproved(uint256 tokenId) external view validNFToken(tokenId) returns (address) {
    return _idToApproval[tokenId];
  }

  /// @notice Enable or disable approval for a third party ("operator") to manage
  ///  all of `_msgSender()`'s assets
  /// @dev Emits the ApprovalForAll event. The contract MUST allow
  ///  multiple operators per owner.
  /// @param operator Address to add to the set of authorized operators
  /// @param approved True if the operator is approved, false to revoke approval
  function setApprovalForAll(address operator, bool approved) external {
    _ownerToOperators[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /// @notice Query if an address is an authorized operator for another address
  /// @param owner The address that owns the NFTs
  /// @param operator The address that acts on behalf of the owner
  /// @return True if `operator` is an approved operator for `owner`, false otherwise
  function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
    return _ownerToOperators[owner][operator];
  }

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev This works identically to the other function with an extra data parameter,
  ///  except this function just sets data to "".
  /// @param from The current owner of the NFT
  /// @param to The new owner
  /// @param tokenId The NFT to transfer
  function safeTransferFrom(address from, address to, uint256 tokenId) external virtual {
    _safeTransferFrom(from, to, tokenId, '');
  }

  /// @notice Transfers the ownership of an NFT from one address to another address
  /// @dev Throws unless `_msgSender()` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `from` is
  ///  not the current owner. Throws if `to` is the zero address. Throws if
  ///  `tokenId` is not a valid NFT. When transfer is complete, this function
  ///  checks if `to` is a smart contract (code size > 0). If so, it calls
  ///  `onERC721Received` on `to` and throws if the return value is not
  ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
  /// @param from The current owner of the NFT
  /// @param to The new owner
  /// @param tokenId The NFT to transfer
  /// @param data Additional data with no specified format, sent in call to `to`
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external canTransfer(tokenId) validNFToken(tokenId) {
    _safeTransferFrom(from, to, tokenId, data);
  }

  /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
  ///  TO CONFIRM THAT `to` IS CAPABLE OF RECEIVING NFTS OR ELSE
  ///  THEY MAY BE PERMANENTLY LOST
  /// @dev Throws unless `_msgSender()` is the current owner, an authorized
  ///  operator, or the approved address for this NFT. Throws if `from` is
  ///  not the current owner. Throws if `to` is the zero address. Throws if
  ///  `tokenId` is not a valid NFT.
  /// @param from The current owner of the NFT
  /// @param to The new owner
  /// @param tokenId The NFT to transfer
  function transferFrom(address from, address to, uint256 tokenId) external canTransfer(tokenId) validNFToken(tokenId) {
    address tokenOwner = _owners[tokenId];
    require(tokenOwner == from, NOT_OWNER);
    require(to != address(0), ZERO_ADDRESS);

    _transfer(to, tokenId);
  }

  /// @notice MARK: ERC721Enumerable

  /// @notice Count NFTs tracked by this contract
  /// @return total A count of valid NFTs tracked by this contract, where each one of
  ///  them has an assigned and queryable owner not equal to the zero address
  function totalSupply() public view returns (uint256 total) {
    for (uint256 i; i <= _maxTokenId; i++) {
      if (_owners[i] != address(0)) {
        total++;
      }
    }

    return total;
  }

  /// @notice Enumerate NFTs assigned to an owner
  /// @dev Throws if `index` >= `balanceOf(owner)` or if
  ///  `owner` is the zero address, representing invalid NFTs.
  /// @param owner An address where we are interested in NFTs owned by them
  /// @param index A counter less than `balanceOf(owner)`
  /// @return The token identifier for the `index`th NFT assigned to `owner`,
  ///   (sort order not specified)
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
    uint256 balance = balanceOf(owner);

    uint256[] memory tokens = new uint256[](balance);
    uint256 idx;

    for (uint256 i; i <= _maxTokenId; i++) {
      if (_owners[i] == owner) {
        tokens[idx] = i;
        idx++;
      }
    }

    return tokens[index];
  }

  /// @notice Enumerate valid NFTs
  /// @dev Throws if `index` >= `totalSupply()`.
  /// @param index A counter less than `totalSupply()`
  /// @return The token identifier for the `index`th NFT,
  ///  (sort order not specified)
  function tokenByIndex(uint256 index) external view returns (uint256) {
    uint256 supply = totalSupply();

    uint256[] memory tokens = new uint256[](supply);
    uint256 idx;
    for (uint256 i; i <= _maxTokenId; i++) {
      if (_owners[i] != address(0)) {
        tokens[idx] = i;
        idx++;
      }
    }

    return tokens[index];
  }

  /// @notice MARK: ERC165 Implementation

  /// @notice Query if a contract implements an interface
  /// @param interfaceId The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceId` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    if (interfaceId == 0xffffffff) {
      return false;
    }

    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Receiver).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId;
  }

  /// MARK: Private methods
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0), ZERO_ADDRESS);
    require(!_exists(tokenId), NFT_ALREADY_EXISTS);

    _owners[tokenId] = to;

    if (tokenId > _maxTokenId) {
      _maxTokenId = tokenId;
    }

    emit Transfer(address(0), to, tokenId);

    if (to.isContract()) {
      bytes4 retval = IERC721Receiver(to).onERC721Received(address(this), address(0), tokenId, "");
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  function _burn(uint256 tokenId) internal virtual validNFToken(tokenId) canTransfer(tokenId) {
    address tokenOwner = _owners[tokenId];

    _clearApproval(tokenId);
    delete _owners[tokenId];

    emit Transfer(tokenOwner, address(0), tokenId);
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _clearApproval(uint256 tokenId) private {
    delete _idToApproval[tokenId];
  }

  /**
   * @dev Actually perform the safeTransferFrom.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
  private
  canTransfer(_tokenId)
  validNFToken(_tokenId)
  {
    address tokenOwner = _owners[_tokenId];
    require(tokenOwner == _from, NOT_OWNER);
    require(_to != address(0), ZERO_ADDRESS);

    _transfer(_to, _tokenId);

    if (_to.isContract()) {
      bytes4 retval = IERC721Receiver(_to).onERC721Received(_msgSender(), _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED, NOT_ABLE_TO_RECEIVE_NFT);
    }
  }

  function _transfer(address to, uint256 tokenId) internal virtual {
    address from = _owners[tokenId];

    _beforeTransfer(from, to, tokenId);

    _clearApproval(tokenId);
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _beforeTransfer(address from, address to, uint256 tokenId) internal virtual {}
}