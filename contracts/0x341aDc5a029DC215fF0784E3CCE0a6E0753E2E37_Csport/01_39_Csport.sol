// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Consideration } from "./lib/Consideration.sol";
/**
 * @title Csport
 * @custom:version 1.1
 * @notice Csport is a generalized ETH/ERC20/ERC721/ERC1155 marketplace. It
 *         minimizes external calls to the greatest extent possible and provides
 *         lightweight methods for common routes as well as more flexible
 *         methods for composing advanced orders or groups of orders. Each order
 *         contains an arbitrary number of items that may be spent (the "offer")
 *         along with an arbitrary number of items that must be received back by
 *         the indicated recipients (the "consideration").
 */
contract Csport is Consideration {
    
    /**
     * @notice Derive and set hashes, reference chainId, and associated domain
     *         separator during deployment.
     *
     * @param conduitController A contract that deploys conduits, or proxies
     *                          that may optionally be used to transfer approved
     *                          ERC20/721/1155 tokens.
     */
    constructor(address conduitController) Consideration(conduitController) {}

    /**
     * @dev Internal pure function to retrieve and return the name of this
     *      contract.
     *
     * @return The name of this contract.
     */
    function _name() internal pure override returns (string memory) {
        // Return the name of the contract.
        assembly {
            mstore(0x20, 0x20)
            mstore(0x47, 0x07536561706f7274)
            return(0x20, 0x60)
        }
    }
}