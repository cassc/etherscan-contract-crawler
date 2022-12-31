// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVCGNFT {
    function getCreator(uint256 _tokenId) external view returns (address);
}