// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TokenDelegate is Ownable {
  // Whether an address is allowed to call `spendFrom()`.
  mapping(address => bool) public authorized;

  modifier onlyAuthorized() {
    require(authorized[msg.sender], "only authorized");
    _;
  }

  // Grant an address or revoke the ability to call `spendFrom()`.
  // `admin` should do this for new versions of protocol contracts.
  function setAuthority(address authority, bool enabled) external onlyOwner {
    authorized[authority] = enabled;
  }

  function spendFrom(IERC721 token, address from, address to, uint256 tokenId) external onlyAuthorized {
    token.safeTransferFrom(from, to, tokenId);
  }
}