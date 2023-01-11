// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.6.12;

import "./IERC5192.sol";

contract Soul is IERC5192 {
  
  mapping (uint256 => bool) public lockedTokens;

  function _lockToken(uint256 tokenId) internal {
    lockedTokens[tokenId] = true;
    emit Locked(tokenId);
  }

  function _unlockToken(uint256 tokenId) internal {
    lockedTokens[tokenId] = false;
    emit Unlocked(tokenId);
  }

  function locked(uint256 tokenId)
    external
    view
    override(IERC5192)
    returns (bool)
  {
    return lockedTokens[tokenId];
  }
}