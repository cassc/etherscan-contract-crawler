// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/INFTMarketplace.sol";
import "./royalties/RoyaltiesV2.sol";

contract NFTMarketplace is
    INFTMarketplace,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    bytes4 public constant ROYALTIES_INTERFACE_ID = 0xcad96cca;
    bytes32 public constant MARKETPLACE_WALLET = keccak256("MARKETPLACE_WALLET");
    uint256 public constant basisPoints = 10000;

    /// @notice percentage fee taken from each side (buyer, seller)
    /// example:
    /// protocolFee = 10, price = 100 formula is price * protocolFee / basisPoints
    /// 100 * 10 / 1000 => 1%
    uint256 public protocolFee;
    address payable public theosProtocolAddress;

    mapping(bytes32 => Item) public orders;

    function initialize(address payable _theosProtocolAddress, uint256 _theosProtocolFee) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        theosProtocolAddress = _theosProtocolAddress;
        protocolFee = _theosProtocolFee;
    }

    /// @notice Changes Theos protocol address
    /// @param _newProtocolAddress new address
    function setTheosProtocolAddress(address payable _newProtocolAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        theosProtocolAddress = _newProtocolAddress;
        emit TheosProtocolAddressChanged(_newProtocolAddress);
    }

    /// @notice Changes Theos protocol fee
    /// @param _newProtocolFee new protocol fee
    function setTheosProtocolFee(uint256 _newProtocolFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        protocolFee = _newProtocolFee;
        emit TheosProtocolFeeChanged(_newProtocolFee);
    }

    /// @notice Used to list item, or update the price for an existing listing
    /// @param tokenAddress NFT Collection address
    /// @param tokenId token id
    /// @param price ask price in wei
    function listItem(
        address tokenAddress,
        uint256 tokenId,
        uint256 price
    ) external {
        Item memory item = Item(msg.sender, tokenAddress, tokenId, price);

        _validateListing(item);

        // update if we already have an order listed
        Item storage existingOrder = orders[_generateUniqueOrderHash(item.tokenAddress, item.tokenId)];
        if (existingOrder.owner != address(0)) {
            existingOrder.owner = msg.sender;
            existingOrder.price = price;
            emit ItemUpdated(msg.sender, tokenAddress, tokenId, price + _calculateFee(price, protocolFee));
            return;
        }

        orders[_generateUniqueOrderHash(item.tokenAddress, item.tokenId)] = item;

        // Emit event with actual buy price
        emit ItemListed(msg.sender, tokenAddress, tokenId, price + _calculateFee(price, protocolFee));
    }

    /// @notice Used to unlist the item from a marketplace
    /// @dev Only NFT owner / Marketplace can unlist the item
    /// @param tokenAddress NFT Collection address
    /// @param tokenId token id
    function unlistItem(address tokenAddress, uint256 tokenId) external {
        (Item memory item, bytes32 orderHash) = _getOrder(tokenAddress, tokenId);

        if (msg.sender != item.owner && !hasRole(MARKETPLACE_WALLET, msg.sender)) {
            revert Unauthorized();
        }

        delete orders[orderHash];

        emit ItemUnlisted(msg.sender, tokenAddress, tokenId);
    }

    /// @notice Allow marketplace to do a batch unlist
    /// @param items array of items [tokenAddress, tokenId]
    function unlistItems(ItemToUnlist[] calldata items) external onlyRole(MARKETPLACE_WALLET) {
        for (uint256 i = 0; i < items.length; i++) {
            delete orders[_generateUniqueOrderHash(items[i].tokenAddress, items[i].tokenId)];
            emit ItemUnlisted(msg.sender, items[i].tokenAddress, items[i].tokenId);
        }
    }

    /// @notice Used to check what is the buy item price
    function getItemPriceWithFee(address tokenAddress, uint256 tokenId) external view returns (uint256) {
        (Item memory item, ) = _getOrder(tokenAddress, tokenId);
        return item.price + _calculateFee(item.price, protocolFee);
    }

    /// @notice Used to buy the item
    /// @dev Make sure to send correct amount of ETH
    /// @param tokenAddress NFT Collection address
    /// @param tokenId token id
    function buyItem(address tokenAddress, uint256 tokenId) public payable virtual {
        (Item memory item, bytes32 orderHash) = _getOrder(tokenAddress, tokenId);

        // we are taking fee from both buyer and seller
        // because of that value for the item must be different
        uint256 fee = _calculateFee(item.price, protocolFee);

        if (msg.value != item.price + fee) {
            revert InvalidAmount();
        }

        // 2 is because we are taking protocolFee from buyer and seller
        uint256 theosFee = 2 * fee;
        theosProtocolAddress.transfer(theosFee);

        // set new price for calculations, we're not using theosFee, because buyer and seller are splitting the bill
        item.price = item.price - fee;

        delete orders[orderHash];

        // transfer NFT to new owner
        IERC721 token = IERC721(item.tokenAddress);
        token.safeTransferFrom(item.owner, msg.sender, item.tokenId);

        if (token.supportsInterface(ROYALTIES_INTERFACE_ID)) {
            uint256 royaltiesPercentage;
            LibPart.Part[] memory royalties = RoyaltiesV2(item.tokenAddress).getRaribleV2Royalties(tokenId);
            if (royalties.length > 0) {
                royaltiesPercentage = royalties[0].value;
            }

            if (royaltiesPercentage > 0) {
                // pay royalties + seller
                uint256 royaltyValue = _calculateFee(item.price, royaltiesPercentage);
                royalties[0].account.transfer(royaltyValue);
                payable(item.owner).transfer(item.price - royaltyValue);
            } else {
                // only pay seller
                payable(item.owner).transfer(item.price);
            }
        } else {
            // only pay seller
            payable(item.owner).transfer(item.price);
        }

        emit ItemSold(msg.sender, tokenAddress, tokenId, item.price + fee);
    }

    /// @notice Wrapper for grant role
    function addMarketplaceWalletRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MARKETPLACE_WALLET, account);
    }

    /// @dev Reverts if order is not found
    function _getOrder(address tokenAddress, uint256 tokenId) internal view returns (Item memory, bytes32) {
        bytes32 orderHash = _generateUniqueOrderHash(tokenAddress, tokenId);

        Item memory item = orders[orderHash];

        if (item.tokenAddress == address(0)) {
            revert InvalidOrder("Zero address");
        }

        return (item, orderHash);
    }

    /// @dev Generates unique order hash
    function _generateUniqueOrderHash(address tokenAddress, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenAddress, tokenId));
    }

    /// @dev Valdiates the listing
    /// making sure that the owner is actually listing the item, that he approved it to NFTMarketplace
    /// and that the price is not 0
    function _validateListing(Item memory item) internal view {
        if (item.price < 1) {
            revert InvalidOrder("Invalid price");
        }

        IERC721 tokenAddress = IERC721(item.tokenAddress);

        // check that the sender actually owns the nft
        if (msg.sender != tokenAddress.ownerOf(item.tokenId)) {
            revert InvalidOrder("Not the owner");
        }

        if (tokenAddress.getApproved(item.tokenId) != address(this)) {
            revert NFTNotApproved();
        }
    }

    /// @dev Used to calculate fee
    function _calculateFee(uint256 price, uint256 fee) internal pure returns (uint256) {
        // handle 'no fee' scenario
        if (fee == 0) return 0;
        return (price * fee) / basisPoints;
    }

    // eslint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    uint256[50] private ______gap;
}