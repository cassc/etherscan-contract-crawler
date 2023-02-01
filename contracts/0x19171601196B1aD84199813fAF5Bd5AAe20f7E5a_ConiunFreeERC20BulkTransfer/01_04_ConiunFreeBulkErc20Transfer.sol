// SPDX-License-Identifier: MIT

//                    ERC20
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

struct TransferRequest {
    address receiver;
    uint256 amount;
}

contract ConiunFreeERC20BulkTransfer is Pausable, Ownable {
    constructor() {}

    function withdrawAll(IERC20 token) external onlyOwner {
        uint256 tokenBalance = token.balanceOf(address(this));
        if (tokenBalance > 0) {
            token.transferFrom(address(this), owner(), tokenBalance);
        }
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = owner().call{value: balance}("");
            require(success, "Transfer failed.");
        }
    }


    function initiateBulkTransfer(IERC20 token, TransferRequest[] memory transferRequests)
        public
        whenNotPaused
    {
        // We know the length of the array
        uint256 arrayLength = transferRequests.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            TransferRequest memory transferRequest = transferRequests[i];
            bool success = token.transferFrom(msg.sender, transferRequest.receiver, transferRequest.amount);
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