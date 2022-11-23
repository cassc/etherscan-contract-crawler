// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC1155} from "IERC1155.sol";
import {IERC1155Base} from "IERC1155Base.sol";
import {ERC1155BaseInternal, ERC1155BaseStorage} from "ERC1155BaseInternal.sol";

/**
 * @title Base ERC1155 contract
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155Base is IERC1155Base, ERC1155BaseInternal {
    function balanceOf(address account, uint256 id)
        internal
        view
        returns (uint256)
    {
        return _balanceOf(account, id);
    }

    /**
     * @notice gets the price for a token
     * @param tokenId token id
     * @return uint256 as token price in wei
     */
    function tokenPrice(uint256 tokenId) internal view returns (uint256) {
        return ERC1155BaseStorage.layout().tokenInfo[tokenId].tokenPrice;
    }

    /**
     * @notice gets the creator address owner of a token
     * @param tokenId token id
     * @return address as creator address owner
     */
    function creatorTokenOwner(uint256 tokenId)
        internal
        view
        returns (address)
    {
        return ERC1155BaseStorage.layout().tokenInfo[tokenId].creatorAccount;
    }

    /**
     * @notice gets the percentage assign to a token id
     * @param tokenId token id
     * @return uint8 percentage for token id
     */
    function tokenPercentage(uint256 tokenId) internal view returns (uint8) {
        return ERC1155BaseStorage.layout().tokenInfo[tokenId].percentage;
    }

    function calculateCreatorCut(uint256 tokenId, uint256 total)
        internal
        view
        returns (uint256)
    {
        uint8 percentage = tokenPercentage(tokenId);
        return (total * percentage) / 100;
    }

    /**
     * @notice gets the max mintable supply for a token
     * @param tokenId token id
     * @return uint256 as a token id
     */
    function maxSupply(uint256 tokenId) internal view returns (uint256) {
        return ERC1155BaseStorage.layout().tokenInfo[tokenId].maxSupply;
    }
}
