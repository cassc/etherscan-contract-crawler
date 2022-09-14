// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface ITokensOfConcord is IERC1155Upgradeable {
    function bestowTokens(address[] memory _to, uint256 _token, uint256 _quantity) external;

    function bestowTokensMany(address[] memory _to, uint256[] memory _tokens, uint256[] memory _amounts) external;
}