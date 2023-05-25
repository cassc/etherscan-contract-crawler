// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC721} from "../interfaces/generic/IERC721.sol";

// Errors
import {ERC721TransferFromFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC721Transfer
 * @notice This contract contains low-level calls to transfer ERC721 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC721Transfer {
    /**
     * @notice Execute ERC721 transferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenId tokenId to transfer
     */
    function _executeERC721TransferFrom(address collection, address from, address to, uint256 tokenId) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(abi.encodeCall(IERC721.transferFrom, (from, to, tokenId)));

        if (!status) {
            revert ERC721TransferFromFail();
        }
    }
}