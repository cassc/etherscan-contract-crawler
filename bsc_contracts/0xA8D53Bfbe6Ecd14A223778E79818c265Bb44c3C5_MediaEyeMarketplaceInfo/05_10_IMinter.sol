// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMinter {
    function getCreator(uint256 _tokenId)
        external
        view
        returns (address);
}