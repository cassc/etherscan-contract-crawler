// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IMintPassURI {
    function getMintPassBaseURI() external view returns (string memory);
}