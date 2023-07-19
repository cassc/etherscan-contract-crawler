// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "../../interfaces/tokenomics/IMinter.sol";
import "../../interfaces/tokenomics/ITORUSToken.sol";

/// @notice All contracts that are allowed to mint TORUS should inherit from this contract
/// This allows the emergency minter to switch to a new minter during the initial 3 months in case of an issue
abstract contract BaseMinter is IMinter, ERC165Storage {
    address public immutable emergencyMinter;
    ITORUSToken public immutable torus;

    constructor(ITORUSToken _torus, address _emergencyMinter) {
        emergencyMinter = _emergencyMinter;
        torus = _torus;
        _registerInterface(IMinter.renounceMinterRights.selector);
    }

    function renounceMinterRights() external override {
        require(msg.sender == emergencyMinter, "only emergency minter can renounce minter rights");
        torus.renounceMinterRights();
    }
}