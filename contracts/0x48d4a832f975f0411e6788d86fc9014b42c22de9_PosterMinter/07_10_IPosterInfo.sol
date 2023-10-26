// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IPosterInfo {
  error NotPosterMinter();
  error OwnerAlreadyMinted();

  /**
   * @notice Emitted when the poster info is set for the first time.
   */
  event FirstPosterMinted(uint256 indexed tokenId, uint256 expiry);

  function setPosterInfoWithMintPeriod(
    bytes32 _mintHash,
    uint256 _tokenId,
    bool _ownerMint,
    uint256 mintEndsAt
  ) external;

  function setPosterInfo(bytes32 _mintHash, uint256 _tokenId, bool _ownerMint) external;

  function isPosterHashUsed(bytes32 mintHash) external view returns (bool);

  function posterExpiryTimestamp(uint256 tokenId) external view returns (uint256);

  function isMintActive(uint256 tokenId) external view returns (bool);

  function ownerMinted(uint256 tokenId) external view returns (bool);
}