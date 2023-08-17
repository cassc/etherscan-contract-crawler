//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ICrossChainGovernable} from "../interfaces/ICrossChainGovernable.sol";

/**
 * @title CrossChainGovernable
 * @notice A 2-step cross-chain governable contract with a delay between setting the pending governor and transferring governance.
 */
abstract contract CrossChainGovernable is ICrossChainGovernable {
    error CrossChainGovernable__ZeroAddress();
    error CrossChainGovernable__ZeroChainId();
    error CrossChainGovernable__NotAuthorized();
    error CrossChainGovernable__TooEarly();
    error CrossChainGovernable__CommunicationNotLost();

    address private s_governor;
    address private s_pendingGovernor;
    uint64 private s_governorChainSelector;
    uint64 private s_pendingGovernorChainSelector;
    uint64 private s_govTransferReqTimestamp;
    uint32 private s_intervalCommunicationLost;
    uint32 public constant TRANSFER_GOVERNANCE_DELAY = 3 days;

    event CrossChainGovernorChanged(address indexed newGovernor, uint64 indexed governorChainSelector);
    event PendingGovernorChanged(address indexed pendingGovernor, uint64 indexed pendingGovernorChainSelector);
    event CommunicationLostIntervalChanged(uint32 indexed newInterval);

    modifier onlyCrossChainGovernor(address sender, uint64 chainId) {
        _onlyCrossChainGovernor(sender, chainId);
        _;
    }

    constructor(address governor, uint64 governorChainSelector, uint32 intervalCommunicationLost) {
        s_governor = governor;
        s_governorChainSelector = governorChainSelector;
        s_intervalCommunicationLost = intervalCommunicationLost;
        emit CrossChainGovernorChanged(governor, governorChainSelector);
    }

    // @inheritdoc ICrossChainGovernable
    function setPendingGovernor(address pendingGovernor, uint64 pendingGovernorChainId) external virtual;

    // @inheritdoc ICrossChainGovernable
    function setIntervalCommunicationLost(uint32 intervalCommunicationLost) external virtual;

    // @inheritdoc ICrossChainGovernable
    function transferGovernance() external {
        _transferGovernance();
    }

    // @inheritdoc ICrossChainGovernable
    function _setPendingGovernor(address pendingGovernor, uint64 pendingGovernorChainSelector) internal {
        if (pendingGovernor == address(0)) {
            revert CrossChainGovernable__ZeroAddress();
        }
        if (pendingGovernorChainSelector == 0) {
            revert CrossChainGovernable__ZeroChainId();
        }
        s_pendingGovernor = pendingGovernor;
        s_pendingGovernorChainSelector = pendingGovernorChainSelector;
        s_govTransferReqTimestamp = uint64(block.timestamp);
        emit PendingGovernorChanged(pendingGovernor, pendingGovernorChainSelector);
    }

    // @inheritdoc ICrossChainGovernable
    function _setIntervalCommunicationLost(uint32 intervalCommunicationLost) internal {
        s_intervalCommunicationLost = intervalCommunicationLost;
        emit CommunicationLostIntervalChanged(intervalCommunicationLost);
    }

    // @inheritdoc ICrossChainGovernable
    function _transferGovernance() internal {
        address newGovernor = s_pendingGovernor;
        uint64 newGovernorChainSelector = s_pendingGovernorChainSelector;
        if (newGovernor == address(0)) {
            revert CrossChainGovernable__ZeroAddress();
        }
        if (block.timestamp - s_govTransferReqTimestamp < TRANSFER_GOVERNANCE_DELAY) {
            revert CrossChainGovernable__TooEarly();
        }
        s_pendingGovernor = address(0);
        s_governor = newGovernor;
        emit CrossChainGovernorChanged(newGovernor, newGovernorChainSelector);
    }

    function _isCommunicationLost() internal view virtual returns (bool isCommunticationLost);

    function _getGovernor() internal view returns (address) {
        return s_governor;
    }

    function _getGovernorChainSelector() internal view returns (uint64) {
        return s_governorChainSelector;
    }

    function _getPendingGovernor() internal view returns (address) {
        return s_pendingGovernor;
    }

    function _getPendingGovernorChainSelector() internal view returns (uint64) {
        return s_pendingGovernorChainSelector;
    }

    function _getIntervalCommunicationLost() internal view returns (uint32) {
        return s_intervalCommunicationLost;
    }

    function _onlyCrossChainGovernor(address sender, uint64 chainId) internal view {
        if (sender != s_governor || chainId != s_governorChainSelector) {
            revert CrossChainGovernable__NotAuthorized();
        }
    }

    function getGovernor() external view returns (address) {
        return _getGovernor();
    }

    function getGovernorChainSelector() external view returns (uint64) {
        return _getGovernorChainSelector();
    }

    function getPendingGovernor() external view returns (address) {
        return _getPendingGovernor();
    }

    function getPendingGovernorChainSelector() external view returns (uint64) {
        return _getPendingGovernorChainSelector();
    }

    function getIntervalCommunicationLost() external view returns (uint32) {
        return _getIntervalCommunicationLost();
    }

    function getGovTransferReqTimestamp() external view returns (uint64) {
        return s_govTransferReqTimestamp;
    }
}