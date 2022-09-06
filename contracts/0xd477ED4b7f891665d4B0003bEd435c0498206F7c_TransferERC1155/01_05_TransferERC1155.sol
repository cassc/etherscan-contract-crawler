// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {ITransfer, IERC1155} from "../interfaces/ITransfer.sol";

/**
 * @title TransferERC1155
 * @notice It allows the transfer of ERC1155 tokens.
 */
contract TransferERC1155 is ITransfer {
    function transferNonFungibleToken(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override returns (bool) {
        // https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155-safeTransferFrom-address-address-uint256-uint256-bytes-
        IERC1155(token).safeTransferFrom(from, to, tokenId, amount, "");
        return true;
    }
}