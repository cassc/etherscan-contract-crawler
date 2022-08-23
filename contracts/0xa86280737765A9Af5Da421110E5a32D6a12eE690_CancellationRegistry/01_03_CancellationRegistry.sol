//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// File Contracts/CancellationRegistry.sol

contract CancellationRegistry is Ownable {

    mapping(address => bool) private registrants;
    mapping(bytes32 => uint256) private orderCancellationBlockNumber;
    mapping(bytes => bool) private orderDeactivations;

    modifier onlyRegistrants {
        require(registrants[msg.sender], "The caller is not a registrant.");
        _;
    }

    function addRegistrant(address registrant) external onlyOwner {
        registrants[registrant] = true;
    }

    function removeRegistrant(address registrant) external onlyOwner {
        registrants[registrant] = false;
    }

    /*
    * @dev Cancels an order.
    */
    function cancelPreviousSellOrders(
        address seller,
        address tokenAddr,
        uint256 tokenId
    ) external onlyRegistrants {
        bytes32 cancellationDigest = keccak256(abi.encode(seller, tokenAddr, tokenId));
        orderCancellationBlockNumber[cancellationDigest] = block.number;
    }

    /*
    * @dev Check if an order has been cancelled.
    */
    function getSellOrderCancellationBlockNumber(
        address addr,
        address tokenAddr,
        uint256 tokenId
    ) external view returns (uint256) {
        bytes32 cancellationDigest = keccak256(abi.encode(addr, tokenAddr, tokenId));
        return orderCancellationBlockNumber[cancellationDigest];
    }

    /*
    * @dev Cancels an order.
    */
    function cancelOrder(bytes memory signature) external onlyRegistrants {
        orderDeactivations[signature] = true;
    }

    /*
    * @dev Check if an order has been cancelled.
    */
    function isOrderCancelled(bytes memory signature) external view returns (bool) {
        return orderDeactivations[signature];
    }

}