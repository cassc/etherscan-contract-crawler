// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBEP20 is IERC20, IERC20Metadata {
    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);
}