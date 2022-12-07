// SPDX-License-Identifier: MIT

////////////////////////////////////////////////solarde.fi//////////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {IInitializer} from "./IInitializer.sol";
import {LibInitializer} from "./LibInitializer.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

abstract contract Initializer is IInitializer {
    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !LibInitializer.isInitializing();

        if (
            (isTopLevelCall && !LibInitializer.isInitialized(1)) ||
            (!Address.isContract(address(this)) &&
                LibInitializer.getInitializedVersion() == 1)
        ) {
            LibInitializer.setInitialized(1);

            if (isTopLevelCall) {
                LibInitializer.setInitializing(true);
            }
            _;
            if (isTopLevelCall) {
                LibInitializer.setInitializing(false);
                emit Initialized(1);
            }
        } else {
            revert InitializerContractAlreadyInitialized();
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        if (
            LibInitializer.isInitializing() ||
            LibInitializer.isInitialized(version)
        ) {
            revert InitializerVersionAlreadyInitialized(version);
        }

        LibInitializer.setInitialized(1);
        LibInitializer.setInitializing(true);
        _;
        LibInitializer.setInitializing(false);
        emit Initialized(version);
    }
}