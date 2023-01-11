// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

interface INFTToken {
  function transferController(address _newController) external;
  function mintNFT (address _receiver, uint256 _tokenId) external returns(uint256);
  function burn (uint256 _tokenId) external;
  function setBaseURI(string memory _uri) external;
}