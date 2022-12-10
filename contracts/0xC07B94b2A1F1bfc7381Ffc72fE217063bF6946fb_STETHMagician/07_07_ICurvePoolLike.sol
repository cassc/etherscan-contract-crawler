// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @dev A simplified version of the Curve Pool interface with methods
/// that are required for the SETH Magician.
interface ICurvePoolLike {
    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external payable returns (uint256);
    function coins(uint256 i) external view returns (address);
    // solhint-disable-next-line func-name-mixedcase
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}