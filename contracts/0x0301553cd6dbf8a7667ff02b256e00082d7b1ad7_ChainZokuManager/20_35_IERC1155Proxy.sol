// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

// @author: miinded.com

interface IERC1155Proxy is IERC1155{
    function mint(address _wallet, uint256 _id, uint256 _count) external;
    function mintBatch(address _wallet, uint256[] memory _ids, uint256[] memory _counts) external;
    function burn(address _wallet, uint256 _id, uint256 _count) external;
    function burnBatch(address _wallet, uint256[] memory _id, uint256[] memory _count) external;
}