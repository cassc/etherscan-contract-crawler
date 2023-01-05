// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IWETH9} from "../interfaces/IWETH9.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
contract RouterImmutables is Initializable {
    /// @dev WETH9 address
    IWETH9 internal WETH9;

    /// @dev Reservoir address
    address internal RESERVOIR;

    /// @dev SeaportModule address
    address internal SEAPORTMODULE;

    /// @dev LooksRareModule address
    address internal LOOKSRAREMODULE;

    /// @dev X2Y2Module address
    address internal X2Y2MODULE;

    // @dev Sudoswap's router address
    address internal SUDOSWAP;

    // @dev EZ's router address
    address internal EZSWAP;

    // constructor(RouterParameters memory params) {
    //     WETH9 = IWETH9(params.weth9);
    //     RESERVOIR = params.reservoir;
    //     SEAPORTMODULE = params.seaportModule;
    //     LOOKSRAREMODULE = params.looksRareModule;
    //     X2Y2MODULE = params.x2y2Module;
    //     SUDOSWAP = params.sudoswap;
    //     EZSWAP = params.ezswap;
    // }

    function initialize(RouterParameters memory params) external initializer {
        WETH9 = IWETH9(params.weth9);
        RESERVOIR = params.reservoir;
        SEAPORTMODULE = params.seaportModule;
        LOOKSRAREMODULE = params.looksRareModule;
        X2Y2MODULE = params.x2y2Module;
        SUDOSWAP = params.sudoswap;
        EZSWAP = params.ezswap;
    }
}