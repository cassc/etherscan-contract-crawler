//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IYouByPeaceRenderer {
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}