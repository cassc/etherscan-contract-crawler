// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TokenOwnerChecker} from "src/contracts/utils/TokenOwnerChecker.sol";
import {ITokenRecoverable} from "./ITokenRecoverable.sol";

abstract contract TokenRecoverable is TokenOwnerChecker, ITokenRecoverable {
    // Using safeTransfer since interacting with other ERC20s
    using SafeERC20 for IERC20;

    address public admin;

    constructor(address _admin) {
        admin = _admin;
    }

    modifier isAdmin() {
        require(msg.sender == admin, "TokenRecoverable: Caller not admin");
        _;
    }

    /**
     * Only allows a syndicate address to access any ERC20 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC20` event.
     *
     * Requirements:
     * - None
     * @param recipient Address that erroneously sent the ERC20 token(s)
     * @param erc20 Erroneously-sent ERC20 token to recover
     * @param amount Amount to recover
     */
    function recoverERC20(
        address recipient,
        address erc20,
        uint256 amount
    ) external isAdmin {
        IERC20(erc20).safeTransfer(recipient, amount);
        emit TokenRecoveredERC20(recipient, erc20, amount);
    }

    /**
     * Only allows a syndicate address to access any ERC721 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC721` event.
     *
     * Requirements:
     * - None
     * @param recipient Address that erroneously sent the ERC721 token
     * @param erc721 Erroneously-sent ERC721 token to recover
     * @param tokenId The tokenId to recover
     */
    function recoverERC721(
        address recipient,
        address erc721,
        uint256 tokenId
    ) external isAdmin {
        IERC721(erc721).transferFrom(address(this), recipient, tokenId);
        emit TokenRecoveredERC721(recipient, erc721, tokenId);
    }
}