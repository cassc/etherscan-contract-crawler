// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./CErc721Sandbox.sol";

/**
 * @title Drops's CErc721 Contract (Modified from "Compound's CErc20Immutable Contract")
 * @notice CTokens which wrap an EIP-20 underlying and are immutable
 * @author Drops Loan
 */
contract CErc721SandboxDelegate is CErc721Sandbox, CDelegateInterface {
    /**
     * @notice Construct an empty delegate
     */
    constructor() public {}

    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) virtual override public {
        // Shh -- currently unused
        data;

        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _becomeImplementation");
    }

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() virtual override public {
        // Shh -- we don't ever want this hook to be marked pure
        if (false) {
            implementation = address(0);
        }

        require(msg.sender == admin, "only the admin may call _resignImplementation");
    }
}