//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import {IEye} from "./IEye.sol";

interface IEyeMetadata {
    error InvalidTokenID();
    error NotEnoughPixelData();

    function tokenURI(uint256 tokenId) external view returns (string memory);
}