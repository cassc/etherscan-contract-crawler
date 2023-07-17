// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IERC998ERC1155TopDown.sol";

contract ERC998TopDown is ERC721, IERC998ERC1155TopDown {
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

  // _balances[tokenId][child address][child tokenId] = amount
  mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
    internal _balances1155;

  mapping(uint256 => EnumerableSet.AddressSet) internal _child1155Contracts;
  mapping(uint256 => mapping(address => EnumerableSet.UintSet))
    internal _childrenForChild1155Contracts;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

  /**
   * @dev Gives child balance for a specific child 1155 contract and child id.
   */
  function child1155Balance(
    uint256 tokenId,
    address childContract,
    uint256 childTokenId
  ) public view override returns (uint256) {
    return _balances1155[tokenId][childContract][childTokenId];
  }

  /**
   * @dev Gives list of child 1155 contracts where token ID has childs.
   */
  function child1155ContractsFor(uint256 tokenId)
    public
    view
    override
    returns (address[] memory)
  {
    address[] memory childContracts = new address[](
      _child1155Contracts[tokenId].length()
    );

    for (uint256 i = 0; i < _child1155Contracts[tokenId].length(); i++) {
      childContracts[i] = _child1155Contracts[tokenId].at(i);
    }

    return childContracts;
  }

  /**
   * @dev Gives list of owned child IDs on a child 1155 contract by token ID.
   */
  function child1155IdsForOn(uint256 tokenId, address childContract)
    public
    view
    override
    returns (uint256[] memory)
  {
    uint256[] memory childTokenIds = new uint256[](
      _childrenForChild1155Contracts[tokenId][childContract].length()
    );

    for (
      uint256 i = 0;
      i < _childrenForChild1155Contracts[tokenId][childContract].length();
      i++
    ) {
      childTokenIds[i] = _childrenForChild1155Contracts[tokenId][childContract]
        .at(i);
    }

    return childTokenIds;
  }

  /**
   * @dev Transfers batch of child 1155 tokens from a token ID.
   */
  function _safeBatchTransferChild1155From(
    uint256 fromTokenId,
    address to,
    address childContract,
    uint256[] memory childTokenIds,
    uint256[] memory amounts,
    bytes memory data
  ) internal {
    require(
      childTokenIds.length == amounts.length,
      "ERC998: ids and amounts length mismatch"
    );
    require(to != address(0), "ERC998: transfer to the zero address");

    address operator = _msgSender();
    require(
      ownerOf(fromTokenId) == operator ||
        isApprovedForAll(ownerOf(fromTokenId), operator),
      "ERC998: caller is not owner nor approved"
    );

    for (uint256 i = 0; i < childTokenIds.length; ++i) {
      uint256 childTokenId = childTokenIds[i];
      uint256 amount = amounts[i];

      _removeChild1155(fromTokenId, childContract, childTokenId, amount);
    }

    ERC1155(childContract).safeBatchTransferFrom(
      address(this),
      to,
      childTokenIds,
      amounts,
      data
    );
    emit TransferBatchChild1155(
      fromTokenId,
      to,
      childContract,
      childTokenIds,
      amounts
    );
  }

  /**
   * @dev Receives a child token, the receiver token ID must be encoded in the
   * field data. Operator is the account who initiated the transfer.
   */
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual override returns (bytes4) {
    require(
      data.length == 32,
      "ERC998: data must contain the unique uint256 tokenId to transfer the child token to"
    );

    uint256 _receiverTokenId;
    uint256 _index = msg.data.length - 32;
    assembly {
      _receiverTokenId := calldataload(_index)
    }

    _receiveChild1155(_receiverTokenId, msg.sender, id, amount);
    emit ReceivedChild1155(from, _receiverTokenId, msg.sender, id, amount);

    return this.onERC1155Received.selector;
  }

  /**
   * @dev Receives a batch of child tokens, the receiver token ID must be
   * encoded in the field data. Operator is the account who initiated the transfer.
   */
  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] memory ids,
    uint256[] memory values,
    bytes memory data
  ) public virtual override returns (bytes4) {
    require(
      data.length == 32,
      "ERC998: data must contain the unique uint256 tokenId to transfer the child token to"
    );
    require(
      ids.length == values.length,
      "ERC1155: ids and values length mismatch"
    );

    uint256 _receiverTokenId;
    uint256 _index = msg.data.length - 32;
    assembly {
      _receiverTokenId := calldataload(_index)
    }

    for (uint256 i = 0; i < ids.length; i++) {
      _receiveChild1155(_receiverTokenId, msg.sender, ids[i], values[i]);
      emit ReceivedChild1155(
        from,
        _receiverTokenId,
        msg.sender,
        ids[i],
        values[i]
      );
    }

    return this.onERC1155BatchReceived.selector;
  }

  /**
   * @dev Update bookkeeping when a 998 is sent a child 1155 token.
   */
  function _receiveChild1155(
    uint256 tokenId,
    address childContract,
    uint256 childTokenId,
    uint256 amount
  ) internal virtual {
    if (!_child1155Contracts[tokenId].contains(childContract)) {
      _child1155Contracts[tokenId].add(childContract);
    }

    if (_balances1155[tokenId][childContract][childTokenId] == 0) {
      _childrenForChild1155Contracts[tokenId][childContract].add(childTokenId);
    }

    _balances1155[tokenId][childContract][childTokenId] += amount;
  }

  /**
   * @dev Update bookkeeping when a child 1155 token is removed from a 998.
   */
  function _removeChild1155(
    uint256 tokenId,
    address childContract,
    uint256 childTokenId,
    uint256 amount
  ) internal virtual {
    require(
      amount != 0 ||
        _balances1155[tokenId][childContract][childTokenId] >= amount,
      "ERC998: insufficient child balance for transfer"
    );

    _balances1155[tokenId][childContract][childTokenId] -= amount;
    if (_balances1155[tokenId][childContract][childTokenId] == 0) {
      _childrenForChild1155Contracts[tokenId][childContract].remove(
        childTokenId
      );
      if (
        _childrenForChild1155Contracts[tokenId][childContract].length() == 0
      ) {
        _child1155Contracts[tokenId].remove(childContract);
      }
    }
  }
}