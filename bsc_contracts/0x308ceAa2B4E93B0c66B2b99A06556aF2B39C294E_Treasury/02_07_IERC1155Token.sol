// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface IERC1155Token {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256);

  function setURI(string memory newuri) external;

  function pause() external;

  function unpause() external;

  function transferOwnership(address newOwner) external;

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external;

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external;
}