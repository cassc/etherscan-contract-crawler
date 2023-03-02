// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "ERC165Storage.sol";

import "IMinter.sol";
import "ICNCToken.sol";

/// @notice All contracts that are allowed to mint CNC should inherit from this contract
/// This allows the emergency minter to switch to a new minter during the initial 3 months in case of an issue
abstract contract BaseMinter is IMinter, ERC165Storage {
    address public immutable emergencyMinter;
    ICNCToken public immutable cnc;

    constructor(ICNCToken _cnc, address _emergencyMinter) {
        emergencyMinter = _emergencyMinter;
        cnc = _cnc;
        _registerInterface(IMinter.renounceMinterRights.selector);
    }

    function renounceMinterRights() external override {
        require(msg.sender == emergencyMinter, "only emergency minter can renounce minter rights");
        cnc.renounceMinterRights();
    }
}