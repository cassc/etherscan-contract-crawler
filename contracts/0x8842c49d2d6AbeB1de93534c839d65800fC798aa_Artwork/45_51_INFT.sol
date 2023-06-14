// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

interface INFT is IERC721Enumerable {
  function mint(address _bonder) external returns (uint256);

  function getBondAmount(uint256 _tokenID) external view returns (uint256 amount);

  function getBondStartTime(uint256 _tokenID) external view returns (uint256 startTime);

  function getBondEndTime(uint256 _tokenID) external view returns (uint256 endTime);

  function getBondStatus(uint256 _tokenID) external view returns (uint8 status);
}