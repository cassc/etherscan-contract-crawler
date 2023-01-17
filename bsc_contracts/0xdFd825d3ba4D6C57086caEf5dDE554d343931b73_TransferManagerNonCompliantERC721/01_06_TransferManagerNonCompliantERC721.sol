// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ITransferManagerNFT} from "./interfaces/ITransferManagerNFT.sol";

/**
 * @title TransferManagerNonCompliantERC721
 * @notice It allows the transfer of ERC721 tokens without safeTransferFrom.
 */
contract TransferManagerNonCompliantERC721 is
    ITransferManagerNFT,
    Initializable
{
    address public joepegExchange;

    /**
     * @notice Initializer
     * @param _joepegExchange address of the Joepeg exchange
     */
    function initialize(address _joepegExchange) public initializer {
        joepegExchange = _joepegExchange;
    }

    /**
     * @notice Transfer ERC721 token
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) external override {
        require(msg.sender == joepegExchange, "Transfer: Only JoepegExchange");
        IERC721(collection).transferFrom(from, to, tokenId);
    }
}