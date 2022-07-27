// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../lib/Blacklist.sol";

abstract contract ERC721Blacklisted is ERC721, Blacklist {
  /**
   * @dev Override {ERC721-_beforeTokenTransfer}
   * Disable token transfer for blacklisted wallets
   */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256
  ) internal virtual override {
    require(!blacklist[_from] && !blacklist[_to], "ERC721Blacklisted: TOKEN_TRANSFER_DISABLED");
  }
}