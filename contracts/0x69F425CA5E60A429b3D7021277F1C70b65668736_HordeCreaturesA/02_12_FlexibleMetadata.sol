// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

abstract contract FlexibleMetadata {
    function _unrevealedBaseURI() external virtual view returns (string memory);
    function _flaggedBaseURI() external virtual view returns (string memory);
    function _revealedBaseURI() external virtual view returns (string memory);
}