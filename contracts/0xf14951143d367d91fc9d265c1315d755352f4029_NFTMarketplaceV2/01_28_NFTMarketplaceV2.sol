// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./interfaces/INFTMarketplace.sol";
import "./interfaces/INFTMarketplaceV2.sol";
import "./NFTMarketplace.sol";
import "./EIP712.sol";
import "./royalties/RoyaltiesV2.sol";
import "./order/LibOrder.sol";

/// @title NFT Marketplace for THEOS Protocol
contract NFTMarketplaceV2 is INFTMarketplaceV2, NFTMarketplace, PausableUpgradeable, EIP712 {
    using ECDSAUpgradeable for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Marketplace contract version
    string public constant version = "2";
    /// @notice Contract name
    string public constant contractName = "TheosMarketplace";

    /// @dev If a buyer wants to cancel the order, he needs to make a transaction
    /// Hash of that order is then saved to this mapping
    mapping(bytes32 => bool) internal canceledBids;

    /// @notice EIP712 initializer
    function initializeV2() external onlyRole(DEFAULT_ADMIN_ROLE) {
        initializeEIP712(contractName, version);
    }

    /// @notice Modifier that checks if it i admin or marketplace wallet
    /// It is used to pause / unpause contract
    modifier adminOrMarketplace() {
        bool allowed = hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(MARKETPLACE_WALLET, msg.sender);
        if (!allowed) {
            revert("Unauthorized");
        }
        _;
    }

    /// @notice Unpause smart contract
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Pause smart contract
    function pause() external adminOrMarketplace {
        _pause();
    }

    /// @notice Used to buy the item
    /// @dev Make sure to send correct amount of ETH
    /// You can check that amount by calling getItemPriceWithFee function
    /// @param tokenAddress NFT Collection address
    /// @param tokenId token id
    function buyItem(address tokenAddress, uint256 tokenId)
        public
        payable
        override(INFTMarketplace, NFTMarketplace)
        nonReentrant
        whenNotPaused
    {
        NFTMarketplace.buyItem(tokenAddress, tokenId);
    }

    /// @notice Intended to be called by the whitelisted marketplace account
    /// @dev NFT Selller is the first parameter
    /// Seller needs to approve ERC721 Token to this contract
    /// Buyer needs to approve ERC20 token to this contract
    /// @param makerOrder Seller's order
    /// @param makerSignature Seller's signature EIP712
    /// @param takerOrder Buyer's order
    /// @param takerSignature Buyer's signature EIP712
    function matchOrders(
        LibOrder.Order calldata makerOrder,
        bytes calldata makerSignature,
        LibOrder.Order calldata takerOrder,
        bytes calldata takerSignature
    ) external nonReentrant whenNotPaused onlyRole(MARKETPLACE_WALLET) {
        bytes32 takerOrderKeyHash = LibOrder.keyHash(takerOrder);

        // TODO: eventually remove requires and uncomment code
        // Check if the orders are actually cancelled
        if (canceledBids[takerOrderKeyHash]) {
            revert("Taker canceled");
        }

        bytes32 makerOrderKeyHash = LibOrder.keyHash(makerOrder);

        if (canceledBids[makerOrderKeyHash]) {
            revert("Maker canceled");
        }

        // Only ERC721 <=> ERC20 is supported
        if (
            makerOrder.makeAsset.typ != LibOrder.AssetType.ERC721 ||
            makerOrder.takeAsset.typ != takerOrder.makeAsset.typ ||
            takerOrder.makeAsset.typ != LibOrder.AssetType.ERC20
        ) {
            revert("Not supported");
        }

        if (
            (takerOrder.deadline != 0 && takerOrder.deadline < block.timestamp) ||
            (makerOrder.deadline != 0 && makerOrder.deadline < block.timestamp)
        ) {
            revert("Deadline passed");
        }

        // Signature can be valid and show that it came from address(0)
        // Because of that we check that maker/taker aren't address(0)
        if (makerOrder.maker == address(0) || takerOrder.maker == address(0)) {
            revert("Unauthorized");
        }

        // Check that the orders are signed
        if (_hashTypedDataV4(LibOrder.hash(makerOrder)).recover(makerSignature) != makerOrder.maker) {
            revert("Unauthorized");
        }

        if (_hashTypedDataV4(LibOrder.hash(takerOrder)).recover(takerSignature) != takerOrder.maker) {
            revert("Unauthorized");
        }

        {
            (address nftAddress, uint256 tokenId) = abi.decode(makerOrder.makeAsset.data, (address, uint256));

            // Transfer NFT
            IERC721(nftAddress).safeTransferFrom(makerOrder.maker, takerOrder.maker, tokenId);

            // Transfer ERC20
            _transferERC20Tokens(
                makerOrder,
                takerOrder,
                IERC721(nftAddress).supportsInterface(ROYALTIES_INTERFACE_ID),
                RoyaltiesV2(nftAddress).getRaribleV2Royalties(tokenId)
            );

            emit Match(nftAddress, tokenId, takerOrder.maker);

            // Cancel orders so that signatures can't be reused
            canceledBids[makerOrderKeyHash] = true;
            canceledBids[takerOrderKeyHash] = true;
        }
    }

    /// @notice Cancel order (Auctions only)
    function cancelOrder(LibOrder.Order calldata order) external {
        canceledBids[LibOrder.keyHash(order)] = true;
        emit Cancel(order);
    }

    function _transferERC20Tokens(
        LibOrder.Order calldata makerOrder,
        LibOrder.Order calldata takerOrder,
        bool nftSupportsRoyalties,
        LibPart.Part[] memory royalties
    ) internal {
        (address makerTakeAssetAddress, uint256 makerTakeAssetAmount) = abi.decode(
            makerOrder.takeAsset.data,
            (address, uint256)
        );
        (address tokenAddress, uint256 takerPrice) = abi.decode(takerOrder.makeAsset.data, (address, uint256));

        if (makerTakeAssetAddress != tokenAddress) {
            revert("Assets don't match");
        }

        if (makerTakeAssetAmount > takerPrice) {
            revert("Invalid ERC20 amount");
        }

        // protocolFee * 2, is because in auctions we are taking the whole amount in one transaction (from buyer)
        uint256 theosFee = _calculateFee(takerPrice, protocolFee * 2);

        IERC20Upgradeable erc20 = IERC20Upgradeable(tokenAddress);
        erc20.safeTransferFrom(takerOrder.maker, theosProtocolAddress, theosFee);

        // set new price for calculations
        uint256 askPrice = takerPrice - theosFee;

        if (nftSupportsRoyalties) {
            uint256 royaltiesPercentage;
            if (royalties.length > 0) {
                royaltiesPercentage = royalties[0].value;
            }

            if (royaltiesPercentage > 0) {
                // pay royalties + seller
                uint256 royaltyValue = _calculateFee(askPrice, royaltiesPercentage);
                // transfer ERC20 token to whoever has the royalties
                erc20.safeTransferFrom(takerOrder.maker, royalties[0].account, royaltyValue);
                // transfer ERC20 token to seller
                erc20.safeTransferFrom(takerOrder.maker, makerOrder.maker, askPrice - royaltyValue);
            } else {
                // only pay seller
                erc20.safeTransferFrom(takerOrder.maker, makerOrder.maker, askPrice);
            }
        } else {
            erc20.safeTransferFrom(takerOrder.maker, makerOrder.maker, askPrice);
        }
    }
}