// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IGnGOffering.sol";

contract GnGOffering is IGnGOffering, Ownable, Pausable {
    mapping(address => bool) public supportedERC721Collections;
    mapping(address => bool) public supportedERC1155Collections;

    uint256 public maxAmountPerTx = 15;
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(address[] memory _supportedERC721Collections, address[] memory _supportedERC1155Collections) {
        _addERC721Collections(_supportedERC721Collections);
        _addERC1155Collections(_supportedERC1155Collections);
    }

    /**
     * @dev Offer the NFTs in supported ERC721 & ERC1155 collections to burn.
     * @dev The collections need to be approved by the owner first.
     * @dev `collections`, `tokenIds` and `amounts` should be in same length.
     * @param collections The list of contract addresses to offer
     * @param tokenIds The list of tokenIds for each collections to offer
     * @param amounts The list of amounts for each token to offer
     */
    function offer(
        address[] calldata collections,
        uint256[][] calldata tokenIds,
        uint256[][] calldata amounts
    ) external whenNotPaused {
        if (collections.length != tokenIds.length) revert InvalidInput("Invalid tokenIds length.");
        if (collections.length != amounts.length) revert InvalidInput("Invalid amounts length.");

        uint256 totalAmount = 0;
        uint256 maxAmount = maxAmountPerTx;

        for (uint256 i = 0; i < collections.length; ) {
            address collection = collections[i];
            uint256[] memory tokenIdList = tokenIds[i];
            uint256[] memory amountList = amounts[i];

            if (supportedERC721Collections[collection]) {
                totalAmount += tokenIdList.length;
                if (totalAmount > maxAmount) revert InvalidInput("Invalid amounts total.");

                _burnERC721(msg.sender, collection, tokenIdList);
            } else if (supportedERC1155Collections[collection]) {
                for (uint256 j = 0; j < amountList.length; ) {
                    totalAmount += amountList[j];
                    if (totalAmount > maxAmount) revert InvalidInput("Invalid amounts total.");

                    unchecked {
                        j++;
                    }
                }
                _burnERC1155(msg.sender, collection, tokenIdList, amountList);
            } else {
                revert InvalidInput("Unsupported collection.");
            }

            unchecked {
                i++;
            }
        }

        if (totalAmount == 0) revert InvalidInput("Total amount cannot be zero.");

        emit AmountOffered(msg.sender, totalAmount);
    }

    /**
     * @dev Transfer user's ERC721 tokens from `from` to burn address
     * @dev This is an internal function can only be called from this contract
     * @param from address representing the owner of the given NFTs
     * @param collection address representing the contract of the given NFTs
     * @param tokenIds The list of ids of the token to be transferred
     */
    function _burnERC721(
        address from,
        address collection,
        uint256[] memory tokenIds
    ) internal {
        for (uint256 i = 0; i < tokenIds.length; ) {
            IERC721(collection).safeTransferFrom(from, burnAddress, tokenIds[i]);
            unchecked {
                i++;
            }
        }
        emit ERC721Offered(from, collection, tokenIds);
    }

    /**
     * @dev Transfer user's ERC1155 tokens from `from` to burn address
     * @dev This is an internal function can only be called from this contract
     * @param from address representing the owner of the given NFTs
     * @param collection address representing the contract of the given NFTs
     * @param tokenIds The list of ids of the token to be transferred
     * @param amounts The list of amounts of the token to be transferred
     */
    function _burnERC1155(
        address from,
        address collection,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal {
        IERC1155(collection).safeBatchTransferFrom(from, burnAddress, tokenIds, amounts, "");
        emit ERC1155Offered(from, collection, tokenIds, amounts);
    }

    /**
     * @dev Add `collections` to supported ERC721 whitelist
     * @dev This is an internal function can only be called from this contract
     * @param collections The list of addresses representing NFT collections to add
     */
    function _addERC721Collections(address[] memory collections) internal {
        for (uint256 i = 0; i < collections.length; ) {
            supportedERC721Collections[collections[i]] = true;
            unchecked {
                i++;
            }
        }
        emit CollectionsAdded(msg.sender, TokenType.ERC721, collections);
    }

    /**
     * @dev Add `collections` to supported ERC1155 whitelist
     * @dev This is an internal function can only be called from this contract
     * @param collections The list of addresses representing NFT collections to add
     */
    function _addERC1155Collections(address[] memory collections) internal {
        for (uint256 i = 0; i < collections.length; ) {
            supportedERC1155Collections[collections[i]] = true;
            unchecked {
                i++;
            }
        }
        emit CollectionsAdded(msg.sender, TokenType.ERC1155, collections);
    }

    /**
     * @dev Add `collections` to supported ERC721 whitelist
     * @dev This function can only be called from contract owner
     * @param collections The list of addresses representing NFT collections to add
     */
    function addERC721Collections(address[] memory collections) external onlyOwner {
        _addERC721Collections(collections);
    }

    /**
     * @dev Add `collections` to supported ERC1155 whitelist
     * @dev This function can only be called from contract owner
     * @param collections The list of addresses representing NFT collections to add
     */
    function addERC1155Collections(address[] memory collections) external onlyOwner {
        _addERC1155Collections(collections);
    }

    /**
     * @dev Remove `collections` from supported ERC721 whitelist
     * @dev This function can only be called from contract owner
     * @param collections The list of addresses representing NFT collections to remove
     */
    function removeERC721Collections(address[] memory collections) external onlyOwner {
        for (uint256 i = 0; i < collections.length; ) {
            delete supportedERC721Collections[collections[i]];
            unchecked {
                i++;
            }
        }
        emit CollectionsRemoved(msg.sender, TokenType.ERC721, collections);
    }

    /**
     * @dev Remove `collections` from supported ERC1155 whitelist
     * @dev This function can only be called from contract owner
     * @param collections The list of addresses representing NFT collections to remove
     */
    function removeERC1155Collections(address[] memory collections) external onlyOwner {
        for (uint256 i = 0; i < collections.length; ) {
            delete supportedERC1155Collections[collections[i]];
            unchecked {
                i++;
            }
        }
        emit CollectionsRemoved(msg.sender, TokenType.ERC1155, collections);
    }

    /**
     * @dev Update maximum amount per transaction
     * @dev This function can only be called from contract owner
     * @param amount The amount to be updated
     */
    function setMaxAmountPerTx(uint256 amount) external onlyOwner {
        maxAmountPerTx = amount;
        emit MaxAmountUpdated(msg.sender, amount);
    }

    /**
     * @dev Pause the contract
     * @dev This function can only be called from contract owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     * @dev This function can only be called from contract owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}