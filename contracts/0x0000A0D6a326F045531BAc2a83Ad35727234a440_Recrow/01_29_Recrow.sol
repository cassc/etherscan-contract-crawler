// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./RecrowBase.sol";

/**
 * @title Recrow
 * @custom:version 1.0
 * @author Cook (cookunijs.eth)
 * @custom:coauthor Ligaratus (ligaratus.eth)
 * @notice Recrow is a general-purpose escrow protocol.
 */
contract Recrow is RecrowBase {
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets domain variables and trusted forwarder.
     * @param name The human-readable name of the signing domain.
     * @param version The current major version of the signing domain.
     * @param trustedForwarder The Recrow TrustedForwarder address.
     */
    constructor(
        string memory name,
        string memory version,
        address trustedForwarder
    ) RecrowBase(name, version, trustedForwarder) {}
}