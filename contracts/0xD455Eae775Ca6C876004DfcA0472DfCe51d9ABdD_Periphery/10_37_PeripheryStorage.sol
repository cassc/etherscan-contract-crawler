// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/IERC20Minimal.sol";
import "../interfaces/fcms/IFCM.sol";
import "../interfaces/IMarginEngine.sol";
import "../interfaces/IVAMM.sol";
import "../interfaces/IWETH.sol";

contract PeripheryStorageV1 {
    // Any variables that would implicitly implement an IPeriphery function if public, must instead
    // be internal due to limitations in the solidity compiler (as of 0.8.12)

    /// @dev Wrapped ETH interface
    IWETH internal _weth;

    /// @dev Voltz Protocol vamm => LP Margin Cap in Underlying Tokens
    /// @dev LP margin cap of zero implies no margin cap
    mapping(IVAMM => int256) internal _lpMarginCaps;

    /// @dev amount of margin (coming from the periphery) in terms of underlying tokens taken up by LPs in a given VAMM
    mapping(IVAMM => int256) internal _lpMarginCumulatives;

    /// @dev alpha lp margin mapping
    mapping(bytes32 => int256) internal _lastAccountedMargin;
}

contract PeripheryStorage is PeripheryStorageV1 {
    // Reserve some storage for use in future versions, without creating conflicts
    // with other inheritted contracts
    uint256[50] private __gap;
}