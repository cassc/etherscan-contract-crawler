// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.12;

interface IERC1155Factory {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}