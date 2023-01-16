// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IWETH9} from "../interfaces/IWETH9.sol";

struct RouterParameters {
    address weth9;
    address reservoir;
    address seaportModule;
    address looksRareModule;
    address x2y2Module;
    address sudoswap;
    address ezswap;
}

/// @title Router Immutable Storage contract
/// @notice Used along with the `RouterParameters` struct for ease of cross-chain deployment
contract RouterImmutables {
    /// @dev WETH9 address
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IWETH9 internal immutable WETH9;

    /// @dev Reservoir address
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable RESERVOIR;

    /// @dev SeaportModule address
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable SEAPORTMODULE;

    /// @dev LooksRareModule address
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable LOOKSRAREMODULE;

    /// @dev X2Y2Module address
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable X2Y2MODULE;

    // @dev Sudoswap's router address
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable SUDOSWAP;

    // @dev EZ's router address
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address internal immutable EZSWAP;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(RouterParameters memory params) {
        WETH9 = IWETH9(params.weth9);
        RESERVOIR = params.reservoir;
        SEAPORTMODULE = params.seaportModule;
        LOOKSRAREMODULE = params.looksRareModule;
        X2Y2MODULE = params.x2y2Module;
        SUDOSWAP = params.sudoswap;
        EZSWAP = params.ezswap;
    }

}