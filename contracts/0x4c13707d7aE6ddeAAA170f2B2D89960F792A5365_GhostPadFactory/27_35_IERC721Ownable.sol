// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IERC721Ownable is IERC721 {
    function owner() external view returns (address);
}