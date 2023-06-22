// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract MultiLockERC721 is Ownable, ERC721Holder {
  struct LockedToken {
    address tokenContract;
    uint256 tokenId;
    uint256 releaseTime;
  }

  mapping(uint256 => LockedToken) public lockedTokens;
  uint256 public nextLockId;

  constructor() {}

  function lock(
    address _tokenContract,
    uint256 _tokenId,
    uint256 _releaseTime
  ) external onlyOwner returns (uint256 lockId) {
    require(_tokenContract != address(0), "Invalid address");

    IERC721 token = IERC721(_tokenContract);
    require(
      token.ownerOf(_tokenId) == msg.sender,
      "Not the owner of the token"
    );

    lockId = nextLockId;
    lockedTokens[lockId] = LockedToken({
      tokenContract: _tokenContract,
      tokenId: _tokenId,
      releaseTime: _releaseTime
    });

    nextLockId++;

    token.safeTransferFrom(msg.sender, address(this), _tokenId);
  }

  function unlock(uint256 lockId) external onlyOwner {
    require(lockId < nextLockId, "Invalid lockId");
    LockedToken storage lockedToken = lockedTokens[lockId];
    require(lockedToken.tokenContract != address(0), "Invalid address");
    require(block.timestamp > lockedToken.releaseTime, "Not unlockable yet");

    IERC721 token = IERC721(lockedToken.tokenContract);
    token.safeTransferFrom(address(this), owner(), lockedToken.tokenId);

    // Remove the locked token from the mapping
    delete lockedTokens[lockId];
  }
}