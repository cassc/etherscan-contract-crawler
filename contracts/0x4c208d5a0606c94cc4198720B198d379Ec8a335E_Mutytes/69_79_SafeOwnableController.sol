// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { SafeOwnableModel } from "./SafeOwnableModel.sol";
import { OwnableController } from "../OwnableController.sol";
import { AddressUtils } from "../../../utils/AddressUtils.sol";

abstract contract SafeOwnableController is SafeOwnableModel, OwnableController {
    using AddressUtils for address;

    modifier onlyNomineeOwner() {
        _enforceOnlyNomineeOwner();
        _;
    }

    function nomineeOwner_() internal view virtual returns (address) {
        return _nomineeOwner();
    }

    function acceptOwnership_() internal virtual {
        transferOwnership_(_nomineeOwner());
        _setNomineeOwner(address(0));
    }

    function _enforceOnlyNomineeOwner() internal view virtual {
        msg.sender.enforceEquals(_nomineeOwner());
    }
}