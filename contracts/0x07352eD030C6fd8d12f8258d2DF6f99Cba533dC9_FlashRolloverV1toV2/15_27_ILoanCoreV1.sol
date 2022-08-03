// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./LoanLibraryV1.sol";

import "../interfaces/IPromissoryNote.sol";
import "./IAssetWrapperV1.sol";
import "../interfaces/IFeeController.sol";

/**
 * @dev Interface for the LoanCore contract. Only needed
 *      functions for rollover copied from V1.
 */
interface ILoanCoreV1 {
    /**
     * @dev Get LoanData by loanId
     */
    function getLoan(uint256 loanId) external view returns (LoanLibraryV1.LoanData calldata loanData);

    /**
     * @dev Getters for integrated contracts
     *
     */
    function borrowerNote() external returns (IPromissoryNote);

    function lenderNote() external returns (IPromissoryNote);

    function collateralToken() external returns (IERC721);

    function feeController() external returns (IFeeController);
}