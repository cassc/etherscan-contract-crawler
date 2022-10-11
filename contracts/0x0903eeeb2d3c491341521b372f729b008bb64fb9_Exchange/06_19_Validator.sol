// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./DataStruct.sol";
import "./KeccakHelper.sol";
import "./TokenType.sol";
import "../interfaces/IBalance.sol";
import "../interfaces/ITransfer.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/// @title Contract responsbile for validating if the data passed are valid or not
contract Validator is KeccakHelper {

    /// @notice Validates data from all perspectives. Master method that calls other methods.
    /// @param sellOrder Order struct created by seller
    /// @param sellOrderSignature sellOrder signed by seller private key
    /// @param buyOrder Order struct created by buyer
    /// @param buyOrderSignature buyOrder signed by buyer private key
    /// @dev buyOrderSignature can be null in case of fixed order sell since the msg.sender will be present
	function validateFull(
        DataStruct.Order memory sellOrder,
        bytes memory sellOrderSignature,
        DataStruct.Order memory buyOrder,
        bytes memory buyOrderSignature
	) internal view {
		validateTimestamp(sellOrder);
		validateTimestamp(buyOrder);

        checkTokenOwnership(sellOrder.offeredAsset, sellOrder.offerer);
        checkTokenOwnership(buyOrder.offeredAsset, buyOrder.offerer);

        checkApprovals(sellOrder.offeredAsset, sellOrder.offerer);
        checkApprovals(buyOrder.offeredAsset, buyOrder.offerer);

		validateSignature(sellOrder, sellOrderSignature, false);
		validateSignature(buyOrder, buyOrderSignature, true);

        validateAssetType(sellOrder.offeredAsset, sellOrder.expectedAsset);

        validateOrderMatch(sellOrder, buyOrder);
	}

    /// @notice Validate if start and end present, current time should be within the given epoch time frames
	function validateTimestamp(DataStruct.Order memory order) internal view {
        require(order.start == 0 || order.start < block.timestamp, "Order start validation failed");
        require(order.end == 0 || order.end > block.timestamp, "Order end validation failed");
	}

    /// @notice Validate if the balance of the offerer is enough or if the token is owned by the offerer
    /// @param asset Asset data struct
    /// @param trader Offerer address
    function checkTokenOwnership(DataStruct.Asset memory asset, address trader) internal view {
        if (TokenType.ETH == asset.assetType) {
            require(msg.value == asset.quantity, "Not enough token sent");
        } else if (TokenType.ERC20 == asset.assetType) {
            require(IBalance(asset.addr).balanceOf(trader) >= asset.quantity, "Not enough ERC20 tokens");
        } else if (TokenType.ERC721 == asset.assetType) {
            require(IBalance(asset.addr).ownerOf(asset.tokenId) == trader, "Offerer is not token owner");
        } else if (TokenType.ERC1155 == asset.assetType) {
            require(IBalance(asset.addr).balanceOf(trader, asset.tokenId) >= asset.quantity, "Not enough ERC1155 tokens");
        }
    }

    /// @notice Validate if the offerer has approved the exchange the transfer their tokens in enough quantity
    /// @param asset Asset data struct
    /// @param trader Offerer address
    function checkApprovals(DataStruct.Asset memory asset, address trader) internal view {
        if (TokenType.ERC20 == asset.assetType) {
            require(ITransfer(asset.addr).allowance(trader, address(this)) == asset.quantity, "Not enough ERC20 tokens allowed to spend");
        } else if (TokenType.ERC721 == asset.assetType || TokenType.ERC1155 == asset.assetType) {
            require(
                ITransfer(asset.addr).isApprovedForAll(trader, address(this)), "ERC721 tokens not approved");
        } else if (TokenType.ETH != asset.assetType) {
            revert("Asset type not supported");
        }
    }

    /// @notice Check if the recovered signer from the signature is the offerer or not
    /// @param order Order data struct
    /// @param signature Hash signed by offerer private key
    /// @param isBuyOrder Salt 0 check only in case of buy order
    /// @dev If salt is 0 in buy order, the signature will not be checked
	function validateSignature(
        DataStruct.Order memory order,
        bytes memory signature,
        bool isBuyOrder
	) internal view {
        if (order.salt == 0 && isBuyOrder) {
            require(msg.sender == order.offerer, "Sender is not authorized");
        } else {
            bytes32 hashedOrder = hashOrder(order);
            address signer = recoverSigner(hashedOrder, signature);
            require(signer == order.offerer, "Signer is not the offerer");
        }
	}

    /// @notice Validate if the offered asset and expected asset have proper tokens as expected or not.
    /// @dev offeredAsset must have either ERC721 or ERC1155 and expectedAsset must have either ETH or ERC20
    function validateAssetType(DataStruct.Asset memory offeredAsset, DataStruct.Asset memory expectedAsset) internal pure {
        require (TokenType.ERC721 == offeredAsset.assetType || TokenType.ERC1155 == offeredAsset.assetType, "Asset type does not match");
        require (TokenType.ETH == expectedAsset.assetType || TokenType.ERC20 == expectedAsset.assetType, "Asset type does not match");
    }

    /// @notice Check if the offeredAsset and expectedAsset are exactly the same in hashed bytes format or not
    function validateOrderMatch(DataStruct.Order memory sellOrder, DataStruct.Order memory buyOrder) internal pure {
        require(sellOrder.offerer != buyOrder.offerer, "seller can not be buyer");
        
        require(
            hashAsset(sellOrder.offeredAsset) == hashAsset(buyOrder.expectedAsset) &&
            hashAsset(sellOrder.expectedAsset) == hashAsset(buyOrder.offeredAsset)
            , "Orders do not match"
        );
    }

    /// @notice Get original signer from order and signature
    /// @param hashedOrder Order data that has been hashed in the contract
    /// @param signature Order hashed signed passed by the caller
    function recoverSigner(
        bytes32 hashedOrder,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 ethHashedOrder = ethHash(hashedOrder);
        return ECDSAUpgradeable.recover(ethHashedOrder, signature);
    }
}