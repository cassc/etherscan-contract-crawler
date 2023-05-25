// SPDX-License-Identifier: MIT

/// @title Interface for MEGAMI ERC721 token

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMEGAMI is IERC721 {
    function mint(uint256 _tokenId, address _address) external;
}