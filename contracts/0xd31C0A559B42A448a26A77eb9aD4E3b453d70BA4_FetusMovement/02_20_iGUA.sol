// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** @title GUA Interface
  * @author @0xAnimist
  * @notice A collaboration between Cai Guo-Qiang and Kanon
  */
interface iGUA {
  function getData(uint256 _tokenId) external view returns(bytes memory, bytes32 seed, bool queried, string memory encrypted);

  //function getGifs() external view returns(bytes[] memory);

  function tokenAPI(uint256 _tokenId) external view returns(string memory);

  function mint(address _owner, bytes32 _queryhash, uint256 _rand, string memory _encrypted) external returns(uint256 tokenId, bytes32 seed);

  function publishQuery(uint256 _tokenId, string memory _query) external returns (bool published);

  function redeemFortune(uint256 _tokenId, bytes32 _queryhash, uint256 _rand, string memory _encrypted) external returns(bool success);
}//end