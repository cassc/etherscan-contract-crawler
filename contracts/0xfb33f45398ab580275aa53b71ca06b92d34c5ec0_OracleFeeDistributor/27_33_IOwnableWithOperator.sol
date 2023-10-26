// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IOwnable.sol";

/**
 * @dev Ownable with an additional role of operator
 */
interface IOwnableWithOperator is IOwnable {
    /**
     * @dev Returns the current operator.
     */
    function operator() external view returns (address);
}