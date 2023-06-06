// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IUserWithdrawalManager {
    // Errors
    error ETHTransferFailed();
    error UnsupportedOperationInSafeMode();
    error InSufficientBalance();
    error ProtocolNotHealthy();
    error InvalidWithdrawAmount();
    error requestIdNotFinalized(uint256 _requestId);
    error RequestAlreadyRedeemed(uint256 _requestId);
    error MaxLimitOnWithdrawRequestCountReached();
    error CannotFindRequestId();
    error CallerNotAuthorizedToRedeem();
    error ZeroAddressReceived();

    // Events
    event UpdatedFinalizationBatchLimit(uint256 paginationLimit);
    event UpdatedStaderConfig(address staderConfig);
    event WithdrawRequestReceived(
        address indexed _msgSender,
        address _recipient,
        uint256 _requestId,
        uint256 _sharesAmount,
        uint256 _etherAmount
    );
    // finalized request upto `requestId`
    event FinalizedWithdrawRequest(uint256 requestId);
    event RequestRedeemed(address indexed _sender, address _recipient, uint256 _ethTransferred);
    event RecipientAddressUpdated(
        address indexed _sender,
        uint256 _requestId,
        address _oldRecipient,
        address _newRecipient
    );
    event ReceivedETH(uint256 _amount);

    function finalizationBatchLimit() external view returns (uint256);

    function nextRequestIdToFinalize() external view returns (uint256);

    function nextRequestId() external view returns (uint256);

    function ethRequestedForWithdraw() external view returns (uint256);

    function maxNonRedeemedUserRequestCount() external view returns (uint256);

    function userWithdrawRequests(uint256)
        external
        view
        returns (
            address payable owner,
            uint256 ethXAmount,
            uint256 ethExpected,
            uint256 ethFinalized,
            uint256 requestTime
        );

    function requestIdsByUserAddress(address, uint256) external view returns (uint256);

    function updateFinalizationBatchLimit(uint256 _paginationLimit) external;

    function requestWithdraw(uint256 _ethXAmount, address receiver) external returns (uint256);

    function finalizeUserWithdrawalRequest() external;

    function claim(uint256 _requestId) external;

    function getRequestIdsByUser(address _owner) external view returns (uint256[] memory);
}