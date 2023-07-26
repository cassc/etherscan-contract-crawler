// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";

interface IERC1155Tradable is IERC1155 {

    function create(address _initialOwner, uint256 _initialSupply) external returns (uint256);

    function mint(address _to, uint256 _id, uint256 _quantity) external;

    function batchMint( address _to, uint256[] memory _ids, uint256[] memory _quantities) external;

    function setCreator(address _to, uint256[] memory _ids) external;
}