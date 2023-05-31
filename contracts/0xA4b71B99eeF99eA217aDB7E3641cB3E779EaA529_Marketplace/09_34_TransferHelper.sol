// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "./TokenTransferrer.sol";

import {AssetType} from "../Enums.sol";
import {Asset} from "../Structs.sol";

/**
 * @title  LQTTransfer
 * @notice LQTTransfer is a library for performing optimized ETH, ERC20,
 *         ERC721, ERC1155 and batch ERC1155 transfers.
 */
contract TransferHelper is Ownable, TokenTransferrer {
    /**
     * @dev internal function to transfer of native token to a given recipient
     *
     * @param to      the recipient of the transfer.
     * @param amount  the amount to transfer.
     */
    function _performNativeTransfer(address to, uint256 amount) internal {
        // Utilize assembly to perform an optimized ERC20 token transfer.
        bool success;
        assembly {
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "Native transfer failed");
    }

    /**
     * @dev internal function to perform assets transfer
     *
     * @param from        address from which fees and payment is taken
     * @param to          address who receives payment
     * @param assetType   asset type (Native, ERC20, ERC721, ERC1155)
     * @param collection  token address, if payment performed in native coin then address(0) can be used
     * @param id          token id for ERC721 and ERC1155 tokens
     * @param amount      amount of tokens only applied if asset type is ERC1155 or ERC20
     */
    function _transfer(
        address from,
        address to,
        AssetType assetType,
        address collection,
        uint256 id,
        uint256 amount
    ) internal {
        if (assetType == AssetType.ERC721) {
            return _performERC721Transfer(collection, from, to, id);
        }
        if (assetType == AssetType.ERC1155) {
            return _performERC1155Transfer(collection, from, to, id, amount);
        }
        if (assetType == AssetType.ERC20) {
            return _performERC20Transfer(collection, from, to, amount);
        }
        return _performNativeTransfer(to, amount);
    }

    /**
     * @dev external function to perform assets transfer
     *
     * @param to address who receives payment
     */
    function transfer(address to, Asset[] calldata assets) external {
        for (uint256 i = 0; i < assets.length; ) {
            _transfer(
                msg.sender,
                to,
                assets[i].assetType,
                assets[i].collection,
                assets[i].id,
                assets[i].amount
            );

            unchecked {
                ++i;
            }
        }
    }

    function _burn(Asset calldata asset) internal {
        if (asset.assetType == AssetType.ERC721) {
            ERC721Burnable token = ERC721Burnable(asset.collection);
            require(
                token.ownerOf(asset.id) == msg.sender,
                "Burn: wrong sender"
            );
            return token.burn(asset.id);
        }

        return
            ERC1155Burnable(asset.collection).burn(
                msg.sender,
                asset.id,
                asset.amount
            );
    }

    /**
     * @dev external function to perform assets burning
     *
     * @param assets  array of assets to burn
     */
    function burn(Asset[] calldata assets) external {
        for (uint256 i = 0; i < assets.length; ) {
            _burn(assets[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev emergency withdraw funds from the contract
     */
    function withdrawFunds() external onlyOwner {
        _performNativeTransfer(msg.sender, address(this).balance);
    }
}