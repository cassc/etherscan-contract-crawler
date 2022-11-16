// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.15;

import "./Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../interfaces/IMessageReceiver.sol";

abstract contract MessageReceiver is IMessageReceiver, Ownable, Initializable {
    event MessageBusUpdated(address messageBus);

    // testMode is used for the ease of testing functions with the "onlyMessageBus" modifier.
    // WARNING: when testMode is true, ANYONE can call executeMessage functions
    // this variable can only be set during contract construction and is always not set on mainnets
    bool public testMode;

    address public messageBus;

    constructor(bool _testMode, address _messageBus) {
        testMode = _testMode;
        messageBus = _messageBus;
    }

    function initMessageReceiver(bool _testMode, address _msgbus) internal onlyInitializing {
        require(!_testMode || block.chainid == 31337); // only allow testMode on hardhat local network
        testMode = _testMode;
        messageBus = _msgbus;
        emit MessageBusUpdated(messageBus);
    }

    function setMessageBus(address _msgbus) public onlyOwner {
        messageBus = _msgbus;
        emit MessageBusUpdated(messageBus);
    }

    modifier onlyMessageBus() {
        if (!testMode) {
            require(msg.sender == messageBus, "caller is not message bus");
        }
        _;
    }

    /**
     * @notice Called by MessageBus (MessageBusReceiver)
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual returns (ExecutionStatus) {}

    /**
     * @notice Called by MessageBus (MessageBusReceiver) to process refund of the original transfer from this contract
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message
    ) external payable virtual returns (bool) {}
}