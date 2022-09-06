// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ITransfer, IERC721} from "../interfaces/ITransfer.sol";

/**
 * @title TransferERC721
 * @notice It allows the transfer of ERC721 tokens.
 */
contract TransferERC721 is ITransfer {
    function transferNonFungibleToken(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external override returns (bool) {
        IERC721(token).safeTransferFrom(from, to, tokenId);
        return true;
    }
}