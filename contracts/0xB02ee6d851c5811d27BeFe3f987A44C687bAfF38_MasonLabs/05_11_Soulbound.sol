// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error TokenNotTransferrable();

abstract contract Soulbound is ERC721A, ERC721AQueryable, Ownable {
  bool public transferrable;

  function flipTransferrable() public onlyOwner {
    transferrable = !transferrable;
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721A) isTransferrable {
    ERC721A.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721A, IERC721A) isTransferrable {
    ERC721A.safeTransferFrom(from, to, tokenId, _data);
  }

  modifier isTransferrable() {
    if (!transferrable) revert TokenNotTransferrable();
    _;
  }
}