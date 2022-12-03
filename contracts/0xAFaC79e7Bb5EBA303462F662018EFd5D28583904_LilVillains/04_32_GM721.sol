// SPDX-License-Identifier: MIT
// GM2 Contracts (last updated v0.0.1)

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '../errors/GM721Errors.sol';

contract GM721 is ERC721, ERC721Burnable {
  using Address for address;
  uint256 internal _supply = 0;

  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  function totalSupply() public view returns (uint256) {
    return _supply;
  }

  function _batchMint(address to, uint256[] calldata tokenIds) internal {
    _beforeBatchMint(to, tokenIds);

    uint256 tokensToMint = tokenIds.length;

    _supply += tokensToMint;
    for (uint256 index = 0; index < tokensToMint; index = _increment(index)) {
      _safeMint(to, tokenIds[index]);
    }
  }

  function burn(uint256 tokenId) public override {
    super.burn(tokenId);
    _supply--;
  }

  function _beforeBatchMint(address, uint256[] calldata) internal virtual {}

  function _increment(uint256 i) internal pure returns (uint256) {
    return i = i + 1;
  }

  function _checkERC721Compatibility(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal returns (bool) {
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert TransferIsNotSupported(to, tokenId);
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
}