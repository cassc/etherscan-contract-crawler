// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";

/**
 *      _____                     ______ __  __ _____   ______          ________ _____  ______ _____
 *     |_   _|                   |  ____|  \/  |  __ \ / __ \ \        / /  ____|  __ \|  ____|  __ \
 *       | |     __ _ _ __ ___   | |__  | \  / | |__) | |  | \ \  /\  / /| |__  | |__) | |__  | |  | |
 *       | |    / _` | '_ ` _ \  |  __| | |\/| |  ___/| |  | |\ \/  \/ / |  __| |  _  /|  __| | |  | |
 *      _| |_  | (_| | | | | | | | |____| |  | | |    | |__| | \  /\  /  | |____| | \ \| |____| |__| |
 *     |_____|  \__,_|_| |_| |_| |______|_|  |_|_|     \____/   \/  \/   |______|_|  \_\______|_____/
 *      _____   ______          __         __  __          _   _    _____ _____ _________     __
 *     |  __ \ / __ \ \        / /        |  \/  |   /\   | \ | |  / ____|_   _|__   __\ \   / /
 *     | |__) | |  | \ \  /\  / /  __  __ | \  / |  /  \  |  \| | | |      | |    | |   \ \_/ /
 *     |  ___/| |  | |\ \/  \/ /   \ \/ / | |\/| | / /\ \ | . ` | | |      | |    | |    \   /
 *     | |    | |__| | \  /\  /     >  <  | |  | |/ ____ \| |\  | | |____ _| |_   | |     | |
 *     |_|     \____/   \/  \/     /_/\_\ |_|  |_/_/    \_\_| \_|  \_____|_____|  |_|     |_|
 *
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}