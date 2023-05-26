// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IBaseVesting.sol";
import "../IERC20Mintable.sol";

/**
 * @notice {ISpoolPreDAOVesting} interface.
 *
 * @dev See {SpoolPreDAOVesting} for function descriptions.
 *
 */
interface ISpoolPreDAOVesting is IBaseVesting {
    function setVests(
        address[] calldata members,
        uint192[] calldata amounts
    ) external;
}