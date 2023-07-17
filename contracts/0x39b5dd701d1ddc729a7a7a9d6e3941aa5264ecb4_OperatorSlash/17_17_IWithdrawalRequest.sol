// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;

/**
 * @title Interface for WithdrawalRequest
 * @notice WithdrawalRequest contract
 */
interface IWithdrawalRequest {
    /**
     * @notice get nft unstake block number
     * @param _tokenId token id
     */
    function getNftUnstakeBlockNumber(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get information about Withdrawal request
     * @param  _requestId request Id
     */
    function getWithdrawalOfRequestId(uint256 _requestId)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, address, bool);

    /**
     * @notice Get information about operator's withdrawal request
     * @param  _operatorId operator Id
     */
    function getOperatorLargeWithdrawalPendingInfo(uint256 _operatorId) external view returns (uint256, uint256);

    /**
     * @notice receive eth for withdrawals
     * @param _operatorId _operator id
     * @param  _amount receive fund amount
     */
    function receiveWithdrawals(uint256 _operatorId, uint256 _amount) external payable;

    /**
     * @notice getTotalPendingClaimedAmounts: Used when calculating exchange rates
     */
    function getTotalPendingClaimedAmounts() external view returns (uint256);
}