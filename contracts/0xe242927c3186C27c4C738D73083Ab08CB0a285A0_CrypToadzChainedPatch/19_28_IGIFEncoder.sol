// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "./GIF.sol";

interface IGIFEncoder {
    function getDataUri(GIF memory gif) external pure returns (string memory);
}