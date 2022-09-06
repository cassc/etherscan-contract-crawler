// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import "../../interfaces/manager/IPositionManager.sol";
import "../../interfaces/hub/IMuffinHubCombined.sol";
import "../../interfaces/lens/ILensBase.sol";

abstract contract LensBase is ILensBase {
    IPositionManager public immutable manager;
    IMuffinHubCombined public immutable hub;

    constructor(address _manager) {
        manager = IPositionManager(_manager);
        hub = IMuffinHubCombined(IPositionManager(_manager).hub());
    }
}