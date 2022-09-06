// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YakuzziSplitter is PaymentSplitter, Ownable {
    constructor(address[] memory payees, uint256[] memory shares_) payable PaymentSplitter(payees, shares_) {}

    /**
     * @notice Transfer all native currency to the shareholders.
     * @dev The loop counts shares because PaymentSplitter does not expose any API to enumerate payees.
     *      Getting shares for a non-existing payee index would revert().
     */
    function releaseAll() public onlyOwner {
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