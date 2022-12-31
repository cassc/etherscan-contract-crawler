// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMultipleToken {
    function getRoyalty(uint256 tokenId) external returns (uint256);

    function getCreator(uint256 tokenId) external returns (address);

    function mint(string memory token_uri, uint256 amount, uint256 royalty) external;

    function burn(uint256 token_id, uint256 amount) external;
}