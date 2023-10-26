// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC721.sol";

interface IERC721Cloneable is IERC721 {
    function initializeERC721(string calldata name_, string calldata symbol_, string calldata baseURI_) external;    
}