// SPDX-License-Identifier: GPL-3.0

/**
  @title ICapsuleRenderer

  @author peri

  @notice Interface for CapsuleRenderer contract
 */

pragma solidity ^0.8.8;

import "./ICapsuleToken.sol";
import "./ITypeface.sol";

interface ICapsuleRenderer {
    function typeface() external view returns (address);

    function svgOf(Capsule memory capsule)
        external
        view
        returns (string memory);

    function isValidFont(Font memory font) external view returns (bool);

    function isValidText(bytes32[8] memory line) external view returns (bool);
}