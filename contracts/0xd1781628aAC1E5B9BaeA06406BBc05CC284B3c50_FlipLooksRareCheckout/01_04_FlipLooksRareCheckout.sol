// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// ======================================================================================================
// ===================================== Flip.xyz: LooksRare trades =====================================
// ======================================================================================================

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./LooksRareTypes.sol";

// Enable interface checking for 721s/1155s
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Enable ERC721 transfers back to caller
interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// Enable ERC1155 transfers back to caller
interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// Enable rewards claiming
interface IMultiRewardsDistributor {
    function claim(
        uint8[] calldata treeIds,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external;
}

// Enable LOOKS reward transfers to distributor contract
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract FlipLooksRareCheckout is Ownable {
    address flipDistributor;
    address constant looksToken = 0xf4d2888d29D722226FafA5d9B24F9164c092421E;

    constructor(address _flipDistributor) {
        flipDistributor = _flipDistributor;
    }

    /* 
    Executes a batch of ETH for ERC721/ERC1155 trades via LooksRare
        Will not revert failed trades, but will rather refund the leftover ETH
            UNLESS a purchased asset does not support ERC721 or ERC1155 interface, then will revert
        Uses 'receiver' rather than 'msg.sender' to enable use by external contracts
    */
    function batchBuy(
        TakerOrder[] calldata takerBids,
        MakerOrder[] calldata makerAsks,
        address receiver
    ) external payable {
        // Make trades
        for (uint256 i = 0; i < takerBids.length; i++) {
            _singleBuy(takerBids[i], makerAsks[i], receiver);
        }

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
    Executes a single ETH for ERC721 trade via LooksRare using explicitly typed parameters
        This will not revert a failed trade, as the batchBuy function will refund leftover ETH
    */
    function _singleBuy(
        TakerOrder calldata takerBid,
        MakerOrder calldata makerAsk,
        address receiver
    ) internal {
        // Make trade on behalf of caller
        try
            ILooksRareExchange(0x59728544B08AB483533076417FbBB2fD0B17CE3a)
                .matchAskWithTakerBidUsingETHAndWETH{value: takerBid.price}(
                takerBid,
                makerAsk
            )
        {
            if (IERC165(makerAsk.collection).supportsInterface(0x80ac58cd)) {
                IERC721(makerAsk.collection).transferFrom(
                    address(this),
                    receiver,
                    makerAsk.tokenId
                );
            } else if (
                IERC165(makerAsk.collection).supportsInterface(0xd9b67a26)
            ) {
                IERC1155(makerAsk.collection).safeTransferFrom(
                    address(this),
                    receiver,
                    makerAsk.tokenId,
                    makerAsk.amount,
                    "0x"
                );
            } else {
                revert("Purchased asset not ERC721 or ERC1155"); // Will revert the entire transaction so asset does not get stuck
            }
        } catch {} // Do not bubble up revert failed trade reverts
    }

    /*
    Claims LOOKS rewards and forwards them to the distributor contract
    */
    function claimAndSend(
        uint8[] calldata treeIds,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external onlyOwner {
        IMultiRewardsDistributor(0x0554f068365eD43dcC98dcd7Fd7A8208a5638C72)
            .claim(treeIds, amounts, merkleProofs);

        uint256 balance = IERC20(looksToken).balanceOf(address(this));
        require(balance > 0, "No rewards claimed");

        IERC20(looksToken).transfer(flipDistributor, balance);
    }

    /* 
    Executes a single ETH for ERC721 trade via LooksRare
        Expects '0x' + 868 bytes of calldata:
            4 byte function selector for LooksRareExchange.matchAskWithTakerBidUsingETHAndWETH
            + 832 bytes order data (TakerOrder and MakerOrder)
            + 32 bytes recipient address
        Expects msg.value to equal MakerOrder.price, will fail if not
        Will revert a failed trade
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
                0x59728544B08AB483533076417FbBB2fD0B17CE3a, // Call LooksRareExchange
                callvalue(), // use msg.value to combat leftover ETH - LooksRareExchange will revert on bad msg.value
                ptr,
                0x344, // Data for making the call is 836 bytes long
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
            mstore(add(ptr2, 0x24), mload(add(ptr, 0x344)))
            mstore(add(ptr2, 0x44), mload(add(ptr, 0xa4)))

            // 4. Transfer NFT to caller
            success2 := call(
                gas(),
                mload(add(ptr, 0x164)), // Call NFT collection
                0,
                ptr2,
                0x64, // Data for call is 100 bytes long (4 + 32 * 3)
                0,
                0
            )
        }

        // Check result
        if (!success || !success2) {
            revert("Trade attempt reverted");
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // For ERC721BasicToken.sol
    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector; // 0xf23a6e61
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector; // 0xbc197c81
    }
}