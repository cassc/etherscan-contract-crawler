// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IAsteroidToken is IERC721 {
  function addManager(address _manager) external;

  function removeManager(address _manager) external;

  function isManager(address _manager) external view returns (bool);

  function mint(address _to, uint256 _tokenId) external;

  function burn(address _owner, uint256 _tokenId) external;
}