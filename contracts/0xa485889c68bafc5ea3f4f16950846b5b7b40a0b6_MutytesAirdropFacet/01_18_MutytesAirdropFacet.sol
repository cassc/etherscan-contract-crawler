// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableController } from "../../core/access/ownable/OwnableController.sol";
import { erc721BaseStorage, ERC721BaseStorage } from "../../core/token/ERC721/base/ERC721BaseStorage.sol";
import { ERC721MintableController } from "../../core/token/ERC721/mintable/ERC721MintableController.sol";
import { ERC721TokenUtils } from "../../core/token/ERC721/utils/ERC721TokenUtils.sol";
import { ERC721InventoryUtils } from "../../core/token/ERC721/utils/ERC721InventoryUtils.sol";
import { BitmapUtils } from "../../core/utils/BitmapUtils.sol";

/**
 * @title Mutytes airdrop facet
 */
contract MutytesAirdropFacet is OwnableController, ERC721MintableController {
    using ERC721TokenUtils for address;
    using ERC721InventoryUtils for uint256;
    using BitmapUtils for uint256;

    /**
     * @notice Airdrop a token to recipients
     * @param recipients The recipient addresses
     */
    function airdrop(address[] calldata recipients) external virtual onlyOwner {
        ERC721BaseStorage storage es = erc721BaseStorage();
        uint256 inventory = es.inventories[msg.sender];
        uint256 amount = recipients.length;
        uint256 burnIndex = inventory.current() - amount;
        uint256 burnTokenId = msg.sender.toTokenId() | burnIndex;

        unchecked {
            es.inventories[msg.sender] = _removeFromInventory(
                inventory,
                burnIndex,
                amount
            );

            for (uint256 i; i < amount; i++) {
                emit Transfer(msg.sender, address(0), burnTokenId + i);
                address to = recipients[i];
                uint256 mintTokenId = to.toTokenId() | _mintBalanceOf(to);
                es.inventories[to] = es.inventories[to].add(1);
                emit Transfer(address(0), to, mintTokenId);
            }
        }
    }

    /**
     * @notice Airdrop tokens to a recipient
     * @param to The recipient address
     * @param amount The amount of tokens to airdrop
     */
    function airdrop(address to, uint256 amount) external virtual onlyOwner {
        ERC721BaseStorage storage es = erc721BaseStorage();
        uint256 inventory = es.inventories[msg.sender];
        uint256 burnIndex = inventory.current() - amount;
        uint256 burnTokenId = msg.sender.toTokenId() | burnIndex;
        uint256 mintTokenId = to.toTokenId() | _mintBalanceOf(to);
        es.inventories[to] = es.inventories[to].add(amount);

        unchecked {
            es.inventories[msg.sender] = _removeFromInventory(
                inventory,
                burnIndex,
                amount
            );

            for (uint256 i; i < amount; i++) {
                emit Transfer(msg.sender, address(0), burnTokenId + i);
                emit Transfer(address(0), to, mintTokenId + i);
            }
        }
    }

    function _removeFromInventory(
        uint256 inventory,
        uint256 offset,
        uint256 amount
    ) internal pure virtual returns (uint256) {
        return
            inventory.unsetRange(ERC721InventoryUtils.BITMAP_OFFSET + offset, amount) -
            (amount << ERC721InventoryUtils.BALANCE_BITSIZE) -
            amount;
    }
}