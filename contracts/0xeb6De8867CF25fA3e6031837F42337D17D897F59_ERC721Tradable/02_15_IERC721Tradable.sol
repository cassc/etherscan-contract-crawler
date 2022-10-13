// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.8 <0.8.10;

interface IERC721Tradable {
  function setBaseMetadataURI(string memory _baseMetadataURI) external;

  function mintTo(address _to, uint256 _newTokenId) external;

  function isExist(uint256 _tokenId) external view returns (bool);
}