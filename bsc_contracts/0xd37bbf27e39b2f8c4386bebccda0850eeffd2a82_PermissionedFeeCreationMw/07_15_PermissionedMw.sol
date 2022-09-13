// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberEngine } from "../../interfaces/ICyberEngine.sol";

abstract contract PermissionedMw {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/
    address public immutable ENGINE; // solhint-disable-line

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks that the sender is the engine address.
     */
    modifier onlyEngine() {
        require(ENGINE == msg.sender, "NON_ENGINE_ADDRESS");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address engine) {
        require(engine != address(0), "ENGINE_ADDRESS_ZERO");
        ENGINE = engine;
    }
}