// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC1155Base} from "ERC1155Base.sol";
import {ERC1155Enumerable} from "ERC1155Enumerable.sol";
import {ERC1155EnumerableInternal} from "ERC1155EnumerableInternal.sol";
import {IKomonERC1155} from "IKomonERC1155.sol";
import {KomonAccessControlBaseStorage} from "KomonAccessControlBaseStorage.sol";

/**
 * @title Komon ERC1155 implementation
 */
abstract contract KomonERC1155 is
    IKomonERC1155,
    ERC1155Base,
    ERC1155Enumerable
{
    function _removeRemainedMaxSupply(uint256 tokenId, uint256 leftTokens)
        internal
    {
        uint256 tokenMaxSupply = maxSupply(tokenId);
        uint256 tokenTotalSupply = totalSupply(tokenId);
        require(
            tokenTotalSupply + leftTokens <= tokenMaxSupply,
            "Token lefts can't add more supply to the original max supply."
        );

        uint256 supplyToRemove = (tokenMaxSupply - tokenTotalSupply) -
            leftTokens;
        require(supplyToRemove > 0, "There is not supply left to remove.");

        removeMaxSupply(tokenId, supplyToRemove);
    }
}
