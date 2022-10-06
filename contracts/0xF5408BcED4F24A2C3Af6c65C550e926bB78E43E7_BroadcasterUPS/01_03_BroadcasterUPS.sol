// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

enum ExchangeKind {
    SEAPORT,
    SUDOSWAP
}

contract BroadcasterUPS {

    address public seaport;

    address public sudoswap;

    error UnexpectedOwnerOrBalance();
    error UnexpectedSelector();
    error UnsuccessfulCall();
    error UnsuccessfulFill();
    error UnsuccessfulPayment();
    error UnsupportedExchange();

    function setSeaportAddress(address seaportAddress) external {
        seaport = seaportAddress;
    }
    
    function setSudoswapAddress(address sudoswapAddress) external {
        sudoswap = sudoswapAddress;
    }

    constructor(
        address seaportAddress,
        address sudoswapAddress
    ) {

        // --- Seaport setup ---

        seaport = seaportAddress;

        // --- Sudoswap setup ---

        sudoswap = sudoswapAddress;

    }

    /**
     * 
     */
    function singleERC721ListingFillWithPrecheck(
        bytes calldata data,
        ExchangeKind exchangeKind,
        address collection,
        uint256 tokenId,
        address receiver,
        address expectedOwner,
        address feeRecipient,
        uint16 feeBps
    ) external payable {
        if (
            expectedOwner != address(0) &&
            IERC721(collection).ownerOf(tokenId) != expectedOwner
        ) {
            revert UnexpectedOwnerOrBalance();
        }

        address target;
        if (exchangeKind == ExchangeKind.SEAPORT) {
            target = seaport;
            //if (
                //selector != ISeaport.fulfillAdvancedOrder.selector &&
                //selector != ISeaport.matchAdvancedOrders.selector
            //) {
                //revert UnexpectedSelector();
            //}
        } else if (exchangeKind == ExchangeKind.SUDOSWAP) {
            target = sudoswap;
            // if (selector != ISudoSwap.swapETHForSpecificNFTs.selector) {
            //     revert UnexpectedSelector();
            // }
        } else {
            revert UnsupportedExchange();
        }

        uint256 payment = (10000 * msg.value) / (10000 + feeBps);

        (bool success, ) = target.call{value: payment}(data);
        if (!success) {
            revert UnsuccessfulFill();
        }

        uint256 fee = msg.value - payment;
        if (fee > 0) {
            (success, ) = payable(feeRecipient).call{value: fee}("");
            if (!success) {
                revert UnsuccessfulPayment();
            }
        }
    }

    /**
     * 
     */
    function multiListingFill(
        bytes[] calldata data,
        uint256[] calldata values,
        bool revertIfIncomplete
    ) external payable {
        bool success;

        uint256 balanceBefore = address(this).balance - msg.value;

        uint256 length = data.length;
        for (uint256 i = 0; i < length; ) {
            (success, ) = address(this).call{value: values[i]}(data[i]);
            if (revertIfIncomplete && !success) {
                revert UnsuccessfulFill();
            }

            unchecked {
                ++i;
            }
        }

        uint256 balanceAfter = address(this).balance;

        if (balanceAfter > balanceBefore) {
            (success, ) = msg.sender.call{value: balanceAfter - balanceBefore}(
                ""
            );
            if (!success) {
                revert UnsuccessfulPayment();
            }
        }
    }

}