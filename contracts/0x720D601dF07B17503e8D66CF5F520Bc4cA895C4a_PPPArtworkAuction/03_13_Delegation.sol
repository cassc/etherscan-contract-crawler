// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Fellowship

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IDelegationRegistry {
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

library Delegation {
    IDelegationRegistry public constant DELEGATION_REGISTRY =
        IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    function check(address operator, IERC721 contract_, uint256 tokenId) internal view returns (bool) {
        address owner = contract_.ownerOf(tokenId);
        return (operator == owner ||
            contract_.isApprovedForAll(owner, operator) ||
            contract_.getApproved(tokenId) == operator ||
            (address(DELEGATION_REGISTRY).code.length > 0 &&
                DELEGATION_REGISTRY.checkDelegateForToken(operator, owner, address(contract_), tokenId)));
    }
}