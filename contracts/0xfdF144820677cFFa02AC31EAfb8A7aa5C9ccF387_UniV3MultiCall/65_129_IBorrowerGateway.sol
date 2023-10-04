// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DataTypesPeerToPeer} from "../DataTypesPeerToPeer.sol";

interface IBorrowerGateway {
    event Borrowed(
        address indexed vaultAddr,
        address indexed borrower,
        DataTypesPeerToPeer.Loan loan,
        uint256 upfrontFee,
        uint256 indexed loanId,
        address callbackAddr,
        bytes callbackData
    );

    event Repaid(
        address indexed vaultAddr,
        uint256 indexed loanId,
        uint256 repayAmount
    );

    event ProtocolFeeSet(uint128[2] newFeeParams);

    /**
     * @notice function which allows a borrower to use an offChain quote to borrow
     * @param lenderVault address of the vault whose owner(s) signed the offChain quote
     * @param borrowInstructions data needed for borrow (see DataTypesPeerToPeer comments)
     * @param offChainQuote quote data (see DataTypesPeerToPeer comments)
     * @param quoteTuple quote data (see DataTypesPeerToPeer comments)
     * @param proof array of bytes needed for merkle tree verification of quote
     * @return loan data
     */
    function borrowWithOffChainQuote(
        address lenderVault,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.OffChainQuote calldata offChainQuote,
        DataTypesPeerToPeer.QuoteTuple calldata quoteTuple,
        bytes32[] memory proof
    ) external returns (DataTypesPeerToPeer.Loan memory);

    /**
     * @notice function which allows a borrower to use an onChain quote to borrow
     * @param lenderVault address of the vault whose owner(s) enacted onChain quote
     * @param borrowInstructions data needed for borrow (see DataTypesPeerToPeer comments)
     * @param onChainQuote quote data (see DataTypesPeerToPeer comments)
     * @param quoteTupleIdx index of quote tuple array
     * @return loan data
     */
    function borrowWithOnChainQuote(
        address lenderVault,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.OnChainQuote calldata onChainQuote,
        uint256 quoteTupleIdx
    ) external returns (DataTypesPeerToPeer.Loan memory);

    /**
     * @notice function which allows a borrower to repay a loan
     * @param loanRepayInstructions data needed for loan repay (see DataTypesPeerToPeer comments)
     * @param vaultAddr address of the vault in which loan was taken out
     */
    function repay(
        DataTypesPeerToPeer.LoanRepayInstructions
            calldata loanRepayInstructions,
        address vaultAddr
    ) external;

    /**
     * @notice function which allows owner to set new protocol fee params
     * @dev protocolFee params are in units of BASE constant (10**18) and variable portion is annualized
     * @param _newFeeParams new base fee (constant) and fee slope (variable) in BASE
     */
    function setProtocolFeeParams(uint128[2] calldata _newFeeParams) external;

    /**
     * @notice function returns address registry
     * @return address of registry
     */
    function addressRegistry() external view returns (address);

    /**
     * @notice function returns protocol fee
     * @return protocolFeeParams protocol fee Params in Base
     */
    function getProtocolFeeParams()
        external
        view
        returns (uint128[2] memory protocolFeeParams);
}