// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface Initializable {
    /// @dev Initialize contract's storage context.
    function initialize(bytes calldata) external;
}