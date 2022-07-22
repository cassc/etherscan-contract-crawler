// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Controller } from "./IERC173Controller.sol";

/**
 * @title ERC173 interface
 * @dev See https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Controller {
    /**
     * @notice Get the contract owner
     * @return owner The owner's address
     */
    function owner() external returns (address);

    /**
     * @notice Transfer ownership to new owner
     * @param newOwner The new owner's address
     */
    function transferOwnership(address newOwner) external;
}