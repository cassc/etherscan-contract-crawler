// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC1155} from "IERC1155.sol";
import {IERC1155Base} from "IERC1155Base.sol";
import {ERC1155BaseStorage} from "ERC1155BaseStorage.sol";

/**
 * @title Base ERC1155 contract
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
abstract contract ERC1155Base is IERC1155Base {
    /**
     * @notice gets the max mintable supply for a token
     * @param tokenId token id
     * @return uint256 as a token id
     */
    function maxSupply(uint256 tokenId)
        internal
        view
        virtual
        returns (uint256)
    {
        return ERC1155BaseStorage.layout().tokenInfo[tokenId].maxSupply;
    }

    /**
     * @notice removes remained max supply
     * @param tokenId token id
     * @param tokenId token id
     */
    function removeMaxSupply(uint256 tokenId, uint256 supplyToRemove) internal {
        ERC1155BaseStorage.Layout storage lay = ERC1155BaseStorage.layout();
        uint256 actualMaxSupply = lay.tokenInfo[tokenId].maxSupply;
        uint256 newMaxSupply = actualMaxSupply - supplyToRemove;
        lay.tokenInfo[tokenId].maxSupply = newMaxSupply;

        emit MaxSupplyRemoved(tokenId, actualMaxSupply, newMaxSupply);
    }
}
