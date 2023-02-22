// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC4973 } from "./ERC4973.sol";

struct Link {
    uint64 tokenIndex;
    uint192 expiration;
    address holder;
}

interface ITether is IERC4973 {
    event Tether(address holder, address operator, uint256 tokenId);
    event Untether(address holder, address operator);

    function refresh(uint256 tokenId, uint256 validityPeriod_) external;

    function isActive(uint256 tokenId) external view returns (bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function exists(address active, address passive)
        external
        view
        returns (bool);

    function tokenId(address active, address passive)
        external
        view
        returns (uint256);

    function links(uint256 tokenId) external view returns (Link memory);
}