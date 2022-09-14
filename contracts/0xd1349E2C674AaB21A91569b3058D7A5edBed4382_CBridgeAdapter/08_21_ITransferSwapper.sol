// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "./IMessageReceiverApp.sol";

interface ITransferSwapper {
    function nativeWrap() external view returns (address);

    /**
     * @notice Called by MessageBus (MessageBusReceiver) to process refund of the original transfer from this contract
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferRefundFromAdapter(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address _executor
    ) external payable returns (IMessageReceiverApp.ExecutionStatus);
}