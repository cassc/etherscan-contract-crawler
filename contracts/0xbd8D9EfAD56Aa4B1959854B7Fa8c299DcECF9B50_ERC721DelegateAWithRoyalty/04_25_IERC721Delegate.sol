// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721Delegate {
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) external;

    function setBaseURI(string memory baseURI_) external;
}