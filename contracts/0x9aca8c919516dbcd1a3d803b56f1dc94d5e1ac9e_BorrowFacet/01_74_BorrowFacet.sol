// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IBorrowFacet} from "./interface/IBorrowFacet.sol";

import {BorrowHandlers} from "./BorrowLogic/BorrowHandlers.sol";
import {BorrowArg, NFToken, Offer, OfferArg} from "./DataStructure/Objects.sol";
import {protocolStorage} from "./DataStructure/Global.sol";
import {Loan} from "./DataStructure/Storage.sol";
import {NotBorrowerOfTheLoan} from "./DataStructure/Errors.sol";

/// @notice public facing methods for borrowing
/// @dev contract handles all borrowing logic through inheritance
contract BorrowFacet is IBorrowFacet, BorrowHandlers {
    /// @notice borrow using sent NFT as collateral without needing approval through transfer callback
    /// @param from account that owned the NFT before transfer
    /// @param tokenId token identifier of the NFT sent according to the NFT implementation contract
    /// @param data abi encoded arguments for the loan
    /// @return selector `this.onERC721Received.selector` ERC721-compliant response, signaling compatibility
    /// @dev param data must be of format OfferArg[]
    function onERC721Received(
        address, // operator
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        OfferArg[] memory args = abi.decode(data, (OfferArg[]));

        // `from` will be considered the borrower, and the NFT will be transferred to the Kairos contract
        // the `operator` that called `safeTransferFrom` is ignored
        useCollateral(args, from, NFToken({implem: IERC721(msg.sender), id: tokenId}));

        return this.onERC721Received.selector;
    }

    /// @notice take loans, take ownership of NFTs specified as collateral, sends borrowed money to caller
    /// @param args list of arguments specifying at which terms each collateral should be used
    /// @return loanIds list of loan ids created
    function borrow(BorrowArg[] calldata args) external returns (uint256[] memory loanIds) {
        loanIds = new uint256[](args.length);

        for (uint256 i = 0; i < args.length; i++) {
            args[i].nft.implem.transferFrom(msg.sender, address(this), args[i].nft.id);
            uint256 loan = useCollateral(args[i].args, msg.sender, args[i].nft);
            loanIds[i] = loan;
        }

        return loanIds;
    }

    /// @notice transfer borrow rights on a loan to another account, the new borrower will receive the collateral
    ///     on repayment or will be able to claim a share of the collateral sale on liquidation
    /// @param loanId id of the loan
    /// @param newBorrower account that will receive the rights
    function transferBorrowerRights(uint256 loanId, address newBorrower) external {
        Loan storage loan = protocolStorage().loan[loanId];

        if (loan.borrower != msg.sender) {
            revert NotBorrowerOfTheLoan(loanId);
        }

        loan.borrower = newBorrower;

        emit TransferBorrowRights(loanId, msg.sender, newBorrower);
    }
}