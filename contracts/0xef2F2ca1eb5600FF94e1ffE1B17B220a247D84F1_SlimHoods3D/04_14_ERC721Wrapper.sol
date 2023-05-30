// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract ERC721Wrapper is ERC721, IERC721Receiver {
  error NotTokenOwnerError();

  IERC721 public collection;

  mapping(uint256 => bool) internal _hasBeenWrappedBefore;

  constructor(string memory name, string memory symbol, address collectionAddress) ERC721(name, symbol) {
    collection = IERC721(collectionAddress);
  }

  function _wrap(uint256 id) internal {
    if (collection.ownerOf(id) != _msgSender()) revert NotTokenOwnerError();

    collection.safeTransferFrom(_msgSender(), address(this), id);

    if (_exists(id)) {
      _safeTransfer(address(this), _msgSender(), id, "");
    } else {
      _hasBeenWrappedBefore[id] = true;
      _safeMint(_msgSender(), id);
    }
  }

  function _unwrap(uint256 id) internal {
    if (ownerOf(id) != _msgSender()) revert NotTokenOwnerError();

    _safeTransfer(_msgSender(), address(this), id, "");
    collection.safeTransferFrom(address(this), _msgSender(), id);
  }

  // IERC721Receiver

  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}