// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}