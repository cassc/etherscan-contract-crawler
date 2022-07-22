// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173 } from "../../IERC173.sol";

/**
 * @title ERC173 safe ownership access control interface
 */
interface ISafeOwnable is IERC173 {
    /**
     * @notice Get the nominated owner
     * @return nomineeOwner The nominated owner's address
     */
    function nomineeOwner() external returns (address);

    /**
     * @notice Accept contract ownership
     */
    function acceptOwnership() external;
}