// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControlModifiers} from "../AccessControl/AccessControlModifiers.sol";
import {PausableModifiers} from "../Pausable/PausableModifiers.sol";
import {RefundUsersLib} from "./RefundUsersLib.sol";

contract RefundUsersFacet is AccessControlModifiers, PausableModifiers {
    function currentNonce() public view returns (uint256) {
        return RefundUsersLib.refundUsersStorage().nonce;
    }

    function singleValueEthRefund(
        address[] memory _recipients,
        uint256 _value,
        bytes memory _approvalSignature
    ) public payable whenNotPaused onlyOwner {
        RefundUsersLib.singleValueEthRefund(
            _recipients,
            _value,
            _approvalSignature
        );
    }

    function multiValueEthRefund(
        address[] memory _recipients,
        uint256[] memory _values,
        bytes memory _approvalSignature
    ) public payable whenNotPaused onlyOwner {
        RefundUsersLib.multiValueEthRefund(
            _recipients,
            _values,
            _approvalSignature
        );
    }
}