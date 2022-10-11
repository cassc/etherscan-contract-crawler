// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./DataStruct.sol";
import "./TokenType.sol";
import "../interfaces/ITransfer.sol";
import "../interfaces/ITraded.sol";
import "../ExchangeAdmin.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// @title Contract to handle all the transfer methods
/// @dev ExchangeAdmin is extended to get the fee amount and fee receiver
contract TransferManager is ExchangeAdmin {

	/// @notice Emitted when orders match successfully and the transfers are complete
	event OrdersMatched(
		address indexed buyer,
		address indexed seller,
		DataStruct.Asset offeredAsset,
		DataStruct.Asset expectedAsset,
		address royaltyReceiver,
		uint royaltyAmount,
		uint feeAmount,
		uint netAmount
	);

	/// @notice Method responsible for transferred tokens
	/// @param offeredAsset Asset to be sold
	/// @param expectedAsset Asset to be recevied in return
	/// @param seller Address of the seller
	/// @param buyer Address of the buyer
	/// @param data For ERC1155 transfer
	/// @dev Updates traded in collectibles
	function manageOrderTransfer(
		DataStruct.Asset memory offeredAsset,
		DataStruct.Asset memory expectedAsset,
		address seller,
		address buyer,
		bytes memory data
	) internal {
		DataStruct.PaymentDetail memory payment = calculatePayment(offeredAsset.addr, offeredAsset.tokenId, expectedAsset.quantity, seller);

        if (payment.callTradedMethod) {
            ITraded(offeredAsset.addr).traded(offeredAsset.tokenId);
        }

        if(TokenType.ERC721 == offeredAsset.assetType) {
        	ITransfer(offeredAsset.addr).safeTransferFrom(
	            seller,
	            buyer,
	            offeredAsset.tokenId
	        );
    	} else if(TokenType.ERC1155 == offeredAsset.assetType) {
        	ITransfer(offeredAsset.addr).safeTransferFrom(
	            seller,
	            buyer,
	            offeredAsset.tokenId,
	            offeredAsset.quantity,
	            data
	        );
    	}

        if(TokenType.ETH == expectedAsset.assetType) {
	        if (payment.royaltyReceiver != address(0)) {
	            payable(payment.royaltyReceiver).transfer(payment.royaltyAmount);
	        }

	        payable(seller).transfer(payment.netAmount);
    	} else if(TokenType.ERC20 == expectedAsset.assetType) {
	        if (payment.royaltyReceiver != address(0)) {
	            require(ITransfer(expectedAsset.addr).transferFrom(buyer, payment.royaltyReceiver, payment.royaltyAmount), 'Not able to send royalty');
	        }

	        require(ITransfer(expectedAsset.addr).transferFrom(buyer, seller, payment.netAmount), 'Failed to transfer amount to seller');
	        require(ITransfer(expectedAsset.addr).transferFrom(buyer, feeReceiver, payment.feeAmount), 'Failed to transfer fee to exchange');
    	}

    	emit OrdersMatched(buyer, seller, offeredAsset, expectedAsset, payment.royaltyReceiver, payment.royaltyAmount, payment.feeAmount, payment.netAmount);
	}

	/// @notice Calculates amount to be received by seller, exchange and creator
	/// @param offeredContract Address of the ERC721 or ERC1155 contract to get royalty
	/// @param offeredTokenId Token id of the ERC721 or ERC1155 token to get royalty
	/// @param seller Address of the seller to check if seller is the creator or not
	/// @dev If first traded value is false, the commisison percent is 40 and seller receives 60
	/// @return Payment struct type from DataStruct which contains amount to be receivable by each address
	function calculatePayment(
		address offeredContract,
		uint offeredTokenId,
		uint expectedQuantity,
		address seller
	)
	internal view
    returns (DataStruct.PaymentDetail memory)
	{
		DataStruct.PaymentDetail memory payment = DataStruct.PaymentDetail(address(0), 0, 0, 0, false);

        // Supports Traded Interface
        if (ITransfer(offeredContract).supportsInterface(0x40d8d24e) &&
        	!ITraded(offeredContract).isTraded(offeredTokenId)) {
	            payment.netAmount = (expectedQuantity * 60) / 100;
	            payment.feeAmount = expectedQuantity - payment.netAmount;

	            payment.callTradedMethod = true;
        } else {
            // Supports Royalty Interface
            if (ITransfer(offeredContract).supportsInterface(0x2a55205a)) {
                (payment.royaltyReceiver, payment.royaltyAmount) = IERC2981(offeredContract)
                    .royaltyInfo(offeredTokenId, expectedQuantity);
                if (payment.royaltyReceiver == seller || payment.royaltyAmount == 0) {
                    payment.royaltyReceiver = address(0);
                    payment.royaltyAmount = 0;
                }
            }

            payment.feeAmount = (expectedQuantity * exchangeFee) / 10000;
            payment.netAmount = expectedQuantity - payment.feeAmount - payment.royaltyAmount;
        }

        require(
            expectedQuantity >= (payment.netAmount + payment.royaltyAmount + payment.feeAmount),
            "Either commission or royalty is too high."
        );

        return payment;
	}
}