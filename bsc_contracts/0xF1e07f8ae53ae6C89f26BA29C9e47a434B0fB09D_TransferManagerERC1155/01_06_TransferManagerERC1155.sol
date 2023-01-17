// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ITransferManagerNFT} from "./interfaces/ITransferManagerNFT.sol";

/**
 * @title TransferManagerERC1155
 * @notice It allows the transfer of ERC1155 tokens.
 */
contract TransferManagerERC1155 is ITransferManagerNFT, Initializable {
    address public joepegExchange;

    /**
     * @notice Initializer
     * @param _joepegExchange address of the Joepeg exchange
     */
    function initialize(address _joepegExchange) public initializer {
        joepegExchange = _joepegExchange;
    }

    /**
     * @notice Transfer ERC1155 token(s)
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @param amount amount of tokens (1 and more for ERC1155)
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override {
        require(msg.sender == joepegExchange, "Transfer: Only JoepegExchange");
        // https://docs.openzeppelin.com/contracts/3.x/api/token/erc1155#IERC1155-safeTransferFrom-address-address-uint256-uint256-bytes-
        IERC1155(collection).safeTransferFrom(from, to, tokenId, amount, "");
    }
}