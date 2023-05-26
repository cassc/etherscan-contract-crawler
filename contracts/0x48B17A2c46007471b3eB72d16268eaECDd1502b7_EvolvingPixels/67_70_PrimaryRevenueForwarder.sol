// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.
pragma solidity >=0.8.17;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {AccessControlEnumerable} from "ethier/erc721/ERC721ACommon.sol";

contract PrimaryRevenueForwarder {
    using Address for address payable;

    /**
     * @notice The primary revenue receiver.
     */
    address payable private _primaryReceiver;

    /**
     * @notice Changes the primary revenue receiver.
     */
    function _setPrimaryReceiver(address payable newReceiver) internal {
        _primaryReceiver = newReceiver;
    }

    /**
     * @notice Returns the primary revenue receiver.
     */
    function primaryReceiver() public view returns (address payable) {
        return _primaryReceiver;
    }

    /**
     * @notice Forwards revenue to the primary receiver.
     */
    function _forwardRevenue(uint256 value) internal {
        _primaryReceiver.sendValue(value);
    }
}

contract SettablePrimaryRevenueForwarder is PrimaryRevenueForwarder, AccessControlEnumerable {
    /**
     * @notice Changes the primary revenue receiver.
     */
    function setPrimaryReceiver(address payable newReceiver) external onlyRole(DEFAULT_STEERING_ROLE) {
        _setPrimaryReceiver(newReceiver);
    }
}