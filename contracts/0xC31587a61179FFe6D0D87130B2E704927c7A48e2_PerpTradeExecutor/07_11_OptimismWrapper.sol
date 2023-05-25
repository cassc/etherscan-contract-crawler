//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/CrossDomainMessenger.interface.sol";

/// @title OptimismWrapper
/// @author 0xAd1
/// @notice Is used to send messages to contracts on Optimism
contract OptimismWrapper {
    /// @notice Address of Optimism L1CrossDomainMessenger
    address public L1CrossDomainMessenger;

    /// @notice Returns the true sender of transaction sent from Optimism L2CrossDomainMessenger
    /// @return address of sender
    function messageSender() internal view returns (address) {
        ICrossDomainMessenger optimismMessenger = ICrossDomainMessenger(
            L1CrossDomainMessenger
        );
        return optimismMessenger.xDomainMessageSender();
    }

    /// @notice Function to send txn to contract on Optimism
    /// @param _target address of recipient contract
    /// @param _message calldata of the txn
    /// @param _gasLimit gasLimit of the txn
    function sendMessageToL2(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) internal {
        ICrossDomainMessenger optimismMessenger = ICrossDomainMessenger(
            L1CrossDomainMessenger
        );
        optimismMessenger.sendMessage(_target, _message, _gasLimit);
    }
}