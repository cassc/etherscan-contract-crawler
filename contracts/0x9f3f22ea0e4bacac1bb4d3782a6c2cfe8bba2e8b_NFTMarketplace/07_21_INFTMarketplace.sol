// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../order/LibOrder.sol";

interface INFTMarketplace {
    /// @dev Thrown when order listing is not valid
    error InvalidOrder(string msg);
    /// @dev Thrown if the owner did not add NFTMarketplace to transfer his token
    error NFTNotApproved();
    /// @dev Unauthorized
    error Unauthorized();
    /// @dev Unsuported ERC20 token
    error UnsupportedERC20Token();
    /// @dev Thrown if the buyer did not pay enough ERC20/ETH
    error InvalidAmount();

    /// @dev Emitted when Theos protocol address is changed
    event TheosProtocolAddressChanged(address newAddress);
    /// @dev Emitted when Theos protocol fee is changed
    event TheosProtocolFeeChanged(uint256 newFee);
    /// @dev Emitted when owner or marketplace unlists the item
    event ItemUnlisted(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId);
    /// @dev Emitted when owner lists his item for sale
    event ItemListed(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId, uint256 price);
    /// @dev Emitted when the listing got updated (e.g. price changed)
    event ItemUpdated(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId, uint256 price);
    /// @dev Emitted when the item is sold
    event ItemSold(address indexed newOwner, address indexed tokenAddress, uint256 indexed tokenId, uint256 price);

    /// @dev Item struct
    struct Item {
        address owner;
        address tokenAddress;
        uint256 tokenId;
        uint256 price;
    }

    /// @dev Struct for batch unlist by marketplace
    struct ItemToUnlist {
        address tokenAddress;
        uint256 tokenId;
    }

    // Admin only

    /// @notice Changes Theos protocol address
    /// @param _newProtocolAddress new address
    function setTheosProtocolAddress(address payable _newProtocolAddress) external;

    /// @notice Changes Theos protocol fee
    /// @param _newProtocolFee new protocol fee
    function setTheosProtocolFee(uint256 _newProtocolFee) external;

    /// @notice Wrapper for grant role
    function addMarketplaceWalletRole(address account) external;

    // ---------------------------------------------------------------------------------------

    // Marketplace wallet only

    /// @notice Allow marketplace to do a batch unlist
    /// @param items array of items [tokenAddress, tokenId]
    function unlistItems(ItemToUnlist[] calldata items) external;

    // ---------------------------------------------------------------------------------------

    // External

    /// @notice Used to list item, or update the price for an existing listing
    /// @param tokenAddress NFT Collection address
    /// @param tokenId token id
    /// @param price ask price in wei
    function listItem(
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    ) external;

    /// @notice Used to buy the item
    /// @dev Make sure to send correct amount of ETH
    /// @param tokenAddress NFT Collection address
    /// @param tokenId token id
    function buyItem(address tokenAddress, uint256 tokenId) external payable;

    /// @notice Used to unlist the item from a marketplace
    /// @dev Only NFT owner / Marketplace can unlist the item
    /// @param tokenAddress NFT Collection address
    /// @param tokenId token id
    function unlistItem(address tokenAddress, uint256 tokenId) external;

    /// @notice Used to check what is the buy item price
    function getItemPriceWithFee(address tokenAddress, uint256 tokenId) external view returns (uint256);
}