// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "IERC721.sol";

interface INFT is IERC721 {
    function kindOf(uint256 id) external view returns (uint32);

    function mint(address to, uint32 kind) external returns (uint256);
}