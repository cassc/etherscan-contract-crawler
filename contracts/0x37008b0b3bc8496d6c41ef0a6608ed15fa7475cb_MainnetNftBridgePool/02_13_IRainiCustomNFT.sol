// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IRainiCustomNFT {
  function onTransfered(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
  function onMerged(uint256 _newTokenId, uint256[] memory _tokenId, address _nftContractAddress, uint256[] memory data) external;
  function onMinted(address _to, uint256 _tokenId, uint256 _cardId, uint256 _cardLevel, uint256 _amount, bytes1 _mintedContractChar, uint256 _number, uint256[] memory _data) external;
  
  function setTokenStates(uint256[] memory id, bytes[] memory state) external;

  function getTokenState(uint256 id) external view returns (bytes memory);
  function uri(uint256 id) external view returns (string memory);
}