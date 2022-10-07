// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISingleToken {
    function getRoyalty(uint256 token_id) external returns (uint256);

    function getCreator(uint256 token_id) external returns (address);

    function mint(string memory token_uri, uint256 royalty) external;

    function burn(uint256 token_id) external;
}