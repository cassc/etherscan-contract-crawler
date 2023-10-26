// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMintable {
    function mint (
        address receiver,
        uint256 tokenId,
        string calldata individualURI
    ) external;
}