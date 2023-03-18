// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8;

import "../../../api/royalties/IRoyalty.sol";

abstract contract OperatorFilterToggle is IPublicOperatorFilterToggleV0, IRestrictedOperatorFilterToggleV0 {
    bool public operatorRestriction;

    function setOperatorRestriction(bool _restriction) external virtual {
        require(_canSetOperatorRestriction(), "Not authorized to set operator restriction.");
        _setOperatorRestriction(_restriction);
    }

    function _setOperatorRestriction(bool _restriction) internal {
        operatorRestriction = _restriction;
        emit OperatorRestriction(_restriction);
    }

    function _canSetOperatorRestriction() internal virtual returns (bool);
}