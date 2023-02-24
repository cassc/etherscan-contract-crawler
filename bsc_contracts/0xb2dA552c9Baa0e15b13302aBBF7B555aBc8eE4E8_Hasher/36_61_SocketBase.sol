// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.7;

import "../interfaces/IHasher.sol";
import "../interfaces/ITransmitManager.sol";
import "../interfaces/IExecutionManager.sol";

import "../utils/ReentrancyGuard.sol";
import "./SocketConfig.sol";

abstract contract SocketBase is SocketConfig, ReentrancyGuard {
    IHasher public hasher__;
    ITransmitManager public transmitManager__;
    IExecutionManager public executionManager__;

    uint256 public chainSlug;

    error InvalidAttester();

    event HasherSet(address hasher);

    function setHasher(address hasher_) external onlyOwner {
        hasher__ = IHasher(hasher_);
        emit HasherSet(hasher_);
    }

    // open issue #50
    /**
     * @notice updates transmitManager_
     * @param transmitManager_ address of Transmit Manager
     */
    function setTransmitManager(address transmitManager_) external onlyOwner {
        transmitManager__ = ITransmitManager(transmitManager_);
        emit TransmitManagerSet(transmitManager_);
    }
}