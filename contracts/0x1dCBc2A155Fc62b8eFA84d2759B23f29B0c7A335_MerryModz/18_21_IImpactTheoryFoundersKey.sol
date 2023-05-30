// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IImpactTheoryFoundersKey is IERC721Enumerable {
    struct Tier {
        uint256 id;
        string name;
    }

    function tokenTier(uint256)
        external
        view
        returns (uint256 tierId, string memory tierName);
}