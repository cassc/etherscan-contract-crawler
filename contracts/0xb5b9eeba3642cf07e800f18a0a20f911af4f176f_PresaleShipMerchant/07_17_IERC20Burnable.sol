// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

interface IERC20Burnable {
    function burnFrom(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;
}