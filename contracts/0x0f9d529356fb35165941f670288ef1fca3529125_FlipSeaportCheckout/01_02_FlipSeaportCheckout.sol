// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// ======================================================================================================
// ====================================== Flip.xyz: Seaport trades ======================================
// ======================================================================================================

import "./SeaportBatchTypes.sol";

contract FlipSeaportCheckout {
    /*
    Executes a batch of ETH-priced trades via Seaport using fulfillAvailableAdvancedOrders
        Will refund un-used ETH to the caller
    */
    function batchBuy(
        AdvancedOrder[] memory advancedOrders,
        CriteriaResolver[] calldata criteriaResolvers,
        FulfillmentComponent[][] calldata offerFulfillments,
        FulfillmentComponent[][] calldata considerationFulfillments,
        bytes32 fulfillerConduitKey,
        address recipient,
        uint256 maximumFulfilled
    ) external payable {
        SeaportInterface(0x00000000006c3852cbEf3e08E8dF289169EdE581)
            .fulfillAvailableAdvancedOrders{value: msg.value}(
            advancedOrders,
            criteriaResolvers,
            offerFulfillments,
            considerationFulfillments,
            fulfillerConduitKey,
            recipient, // All successfully bought items must be forwarded to the recipient
            maximumFulfilled
        );

        // Check for leftover ETH
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }

    /* 
    Executes a single ETH for ERC721 trade via Seaport
        Expects some bytes of calldata (dynamic length due to BasicOrderParameters.additionalRecipients[]):
            4 byte function selector for Seaport.fulfillBasicOrder
            + BasicOrderParameters
        Expects msg.value to equal order price
    */
    fallback() external payable {
        bool success;
        bool success2;
        assembly {
            // 1. Prepare for trade call
            let ptr := mload(0x40)
            // Copy calldata to memory
            calldatacopy(ptr, 0, calldatasize())

            // 2. Make trade
            success := call(
                gas(),
                0x00000000006c3852cbEf3e08E8dF289169EdE581, // Call Seaport
                callvalue(), // Use msg.value - fulfillBasicOrder will revert on failed trades
                ptr,
                calldatasize(), // Calldata is dynamic length
                0,
                0
            )

            // 3. Prepare for transfer call
            let ptr2 := mload(0x40)
            // Store transferFrom selector + address(this) + recipient + tokenId
            mstore(
                ptr2,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(ptr2, 0x04), address())
            mstore(add(ptr2, 0x24), caller())
            mstore(add(ptr2, 0x44), mload(add(ptr, 0xe4)))

            // 4. Transfer NFT to caller
            success2 := call(
                gas(),
                mload(add(ptr, 0xc4)), // Call NFT collection
                0,
                ptr2,
                0x64, // Data for call is 100 bytes long (4 + 32 * 3)
                0,
                0
            )
        }

        // Check result
        if (!success || !success2) {
            revert("Trade attempt failed");
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector; // 0xf23a6e61
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector; // 0xbc197c81
    }
}