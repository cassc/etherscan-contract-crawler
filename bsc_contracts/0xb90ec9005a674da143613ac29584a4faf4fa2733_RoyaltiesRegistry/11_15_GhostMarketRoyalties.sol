// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract GhostMarketRoyalties {
    struct Royalty {
        address payable recipient;
        uint256 value;
    }

    function getRoyalties(uint256 tokenId) external view returns (Royalty[] memory) {}
}