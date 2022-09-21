//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "PaymentSplitter.sol";
import "IERC721.sol";

/**
 * The OpenZeppelin PaymentSplitter with following extensions:
 * - releaseAll() function to release() funds for all payees. (Distribute all funds on one go to save gas.)
 * - rescueERC721 function to allow rescuing any accidentally transferred NFT.
 */
contract PaySplitter is PaymentSplitter {

    constructor(address[] memory payees, uint256[] memory shares_) PaymentSplitter(payees, shares_) payable {
    }

    /**
     * @notice Transfer all native currency to the shareholders.
     * @dev The loop counts shares because PaymentSplitter does not expose any API to enumerate payees.
     *      Getting shares for a non-existing payee index would revert().
     */
    function releaseAll() public {
        uint256 sharesLeft = PaymentSplitter.totalShares();
        for (uint256 i = 0; sharesLeft > 0; i++) {
            address payee = PaymentSplitter.payee(i);
            PaymentSplitter.release(payable(payee));
            sharesLeft -= PaymentSplitter.shares(payee);
        }
    }

    /**
     * @notice If by accident someone transfers an NFT to this contract, any shareholder may rescue it.
     * Transfers the the NFT to the caller.
     */
    function rescueERC721(IERC721 tokenToRescue, uint256 tokenId) external {
        require(PaymentSplitter.shares(_msgSender()) > 0, "only shareholders can rescue");
        tokenToRescue.safeTransferFrom(address(this), _msgSender(), tokenId);
    }
}