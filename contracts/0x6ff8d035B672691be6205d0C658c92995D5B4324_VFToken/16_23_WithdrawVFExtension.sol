// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

abstract contract WithdrawVFExtension is Context {
    constructor() {}

    /**
     * @dev Withdraw balance on contact to msg sender
     *
     * Requirements:
     *
     * - the caller must be an admin role
     */
    function _withdrawMoney() internal {
        address payable to = payable(_msgSender());
        to.transfer(address(this).balance);
    }

    /**
     * @dev Withdraw token if we need to refund
     *
     * Requirements:
     *
     * - `contractAddress` must support the IVFToken interface
     * - the caller must be an admin role
     */
    function _withdrawToken(
        address contractAddress,
        address to,
        uint256 tokenId
    ) internal {
        IERC721(contractAddress).transferFrom(address(this), to, tokenId);
    }
}