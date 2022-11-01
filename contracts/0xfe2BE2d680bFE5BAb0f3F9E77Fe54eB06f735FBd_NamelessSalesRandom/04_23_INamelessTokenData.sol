// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface INamelessTokenData {
  function initialize ( address templateLibrary, address clonableTokenAddress, address initialAdmin, uint256 maxGenerationSize ) external;
  function getTokenURI(uint256 tokenId, address owner) external view returns (string memory);
  function beforeTokenTransfer(address from, address, uint256 tokenId) external returns (bool);
  function redeem(uint256 tokenId) external;
  function getFeeRecipients(uint256) external view returns (address payable[] memory);
  function getFeeBps(uint256) external view returns (uint256[] memory);
  function royaltyInfo(uint256 _tokenId, uint256 _value) external view returns (address _receiver, uint256 _royaltyAmount);
}