//SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

import "./interfaces/IFeeDispatcher.sol";

contract FeeRecipient {
    /// @notice Constructor replay prevention
    bool internal initialized;
    /// @notice Address where funds are sent to be dispatched
    IFeeDispatcher internal dispatcher;
    /// @notice Public Key root assigned to this receiver
    bytes32 internal publicKeyRoot;

    error AlreadyInitialized();

    /// @notice Initializes the receiver
    /// @param _dispatcher Address that will handle the fee dispatching
    /// @param _publicKeyRoot Public Key root assigned to this receiver
    function init(address _dispatcher, bytes32 _publicKeyRoot) external {
        if (initialized) {
            revert AlreadyInitialized();
        }
        initialized = true;
        dispatcher = IFeeDispatcher(_dispatcher);
        publicKeyRoot = _publicKeyRoot;
    }

    /// @notice Empty calldata fallback
    receive() external payable {}

    /// @notice Non-empty calldata fallback
    fallback() external payable {}

    /// @notice Triggers a withdrawal by sending its funds + its public key root to the dispatcher
    /// @dev Can be called by any wallet as recipients are not parameters
    function withdraw() external {
        dispatcher.dispatch{value: address(this).balance}(publicKeyRoot);
    }

    /// @notice Retrieve the assigned public key root
    function getPublicKeyRoot() external view returns (bytes32) {
        return publicKeyRoot;
    }

    /// @notice retrieve the assigned withdrawer
    function getWithdrawer() external view returns (address) {
        return dispatcher.getWithdrawer(publicKeyRoot);
    }
}