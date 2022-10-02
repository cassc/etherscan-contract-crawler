pragma solidity ^0.5.16;

import "./MFungibleTokenUser.sol";

/**
 * @title mmo.finance's MEther Contract
 * @notice mToken which wraps Ether
 * @author mmo.finance, based on Compound
 */
contract MEtherUser is MFungibleTokenUser, MEtherUserInterface {

    /*** User Interface ***/

    /**
     * @notice Sender supplies assets (ETH) into the market and receives mTokens in exchange
     * @dev Reverts upon any failure
     * @return The amount of new mTokens minted
     */
    function mint() external payable returns (uint) {
        ( , uint tokens, ) = mintToFungibleInternal(msg.sender, msg.value);
        return tokens;
    }

    /**
     * @notice Sender supplies assets (ETH) into the market and beneficiary receives mTokens in exchange
     * @dev Reverts upon any failure
     * @param beneficiary The address to receive the newly minted mTokens
     * @return The amount of new mTokens minted
     */
    function mintTo(address beneficiary) external payable returns (uint) {
        ( , uint tokens, ) = mintToFungibleInternal(beneficiary, msg.value);
        return tokens;
    }

    /**
     * @notice Sender repays their own borrow
     * @dev Reverts upon any failure
     * @return (uint) If successful, returns the actual repayment amount.
     */
    function repayBorrow() external payable returns (uint) {
        (uint err, uint amount) = repayBorrowInternal(thisFungibleMToken, msg.value);
        requireNoError(err, "repayBorrow failed");
        return amount;
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @dev Reverts upon any failure
     * @param borrower the account with the debt being paid off
     * @return (uint) If successful, returns the actual repayment amount.
     */
    function repayBorrowBehalf(address borrower) external payable returns (uint) {
        (uint err, uint amount) = repayBorrowBehalfInternal(borrower, thisFungibleMToken, msg.value);
        requireNoError(err, "repayBorrowBehalf failed");
        return amount;
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @dev Reverts upon any failure
     * @param borrower The borrower whose collateral is to be liquidated
     * @param mTokenCollateral The mToken collateral which to seize from the borrower
     * @return (uint) If successful, returns the actual repayment amount for the borrow.
     */
    function liquidateBorrow(address borrower, uint240 mTokenCollateral) external payable returns (uint) {
        (uint err, uint amount) = liquidateBorrowInternal(borrower, thisFungibleMToken, msg.value, mTokenCollateral);
        requireNoError(err, "liquidateBorrow failed");
        return amount;
    }

    /**
     * @notice The fee the protocol keeps from auction sales, scaled by 1e18.
     * @return uint The fee, as mantissa
     */
    function getProtocolAuctionFeeMantissa() external view returns (uint) {
        return protocolAuctionFeeMantissa;
    }

    /**
     * @notice The sender adds to reserves.
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _addReserves() external payable returns (uint) {
        return _addReservesInternal(thisFungibleMToken, msg.value);
    }

    /**
     * @notice In case of any other action (e.g., ETH being sent to contract), revert
     */
    function () external payable {
        revert("Invalid function call");
    }

    /*** Safe Token ***/

    /**
     * @notice Perform the actual transfer in, which is a no-op
     * @param from Address sending the Ether
     * @param amount Amount of Ether being sent
     * @return The actual amount of Ether transferred
     */
    function doTransferIn(address from, uint256 underlyingID, uint amount) internal returns (uint) {
        // Sanity checks
        require(msg.sender == from, "sender mismatch");
        require(underlyingIDs[thisFungibleMToken] == underlyingID, "underlying tokenID mismatch");
        require(msg.value == amount, "value mismatch");
        return amount;
    }
}