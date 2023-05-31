// SPDX-License-Identifier: MIT

//
//                 ..        .           .    ..
//  @@@@&        &@@@@@@@@@@@@@@@(        @@@@@.
//  @@@@&   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@.   @@@@@.
//  @@@@& @@@@@@@@               @@@@@@@@ @@@@@.
//  @@@@@@@@@@..                    ,@@@@@@@@@@.
//  @@@@@@@@                          [email protected]@@@@@@@.
//  @@@@@@.                             %@@@@@@.
//  @@@@@.                               %@@@@@.
//  @@@@@                                 @@@@@.
// [email protected]@@@&             CONIUN              @@@@@
//  @@@@@          B   U   L   K          @@@@@.
//  /@@@@,        T R A N S F E R       .&@@@@..
//   @@@@@/                             @@@@@(
//    %@@@@@..                        [email protected]@@@@.
//     [email protected]@@@@@,.                    #@@@@@@
//       [email protected]@@@@@@@...         . ,@@@@@@@@
//         . @@@@@@@@@@@@@@@@@@@@@@@@&
//               [email protected]@@@@@@@@@@@@@@..
//
//
// @creator:     ConiunIO
// @security:    [email protected]
// @author:      Batuhan KATIRCI (@batuhan_katirci)
// @website:     https://coniun.io/

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

struct TransferRequest {
    address receiver;
    uint256 amount;
}

contract ConiunFreeBulkTransfer is Pausable, Ownable {
    constructor() {}

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function initiateBulkTransfer(TransferRequest[] memory transferRequests)
        public
        payable
        whenNotPaused
    {
        // We know the length of the array
        uint256 arrayLength = transferRequests.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            TransferRequest memory transferRequest = transferRequests[i];
            (bool success, ) = transferRequest.receiver.call{
                value: transferRequest.amount
            }("");
            require(success, "bulk_transfer_failed");
        }
    }

    // management functions

    function pause() public whenNotPaused {
        _pause();
    }

    function unpause() public whenPaused {
        _unpause();
    }
}