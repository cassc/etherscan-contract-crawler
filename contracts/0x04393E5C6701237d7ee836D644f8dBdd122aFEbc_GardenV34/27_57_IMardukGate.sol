// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IBabylonGate} from './IBabylonGate.sol';

/**
 * @title IMardukGate
 * @author Babylon Finance
 *
 * Interface for interacting with the Gate Guestlist NFT
 */
interface IMardukGate is IBabylonGate {
    /* ============ Functions ============ */

    function canAccessBeta(address _user) external view returns (bool);
}