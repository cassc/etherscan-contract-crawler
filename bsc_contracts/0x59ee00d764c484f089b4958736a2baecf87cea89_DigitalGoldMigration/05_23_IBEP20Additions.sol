// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**
 * @dev Interface of the additions needed to the ERC20 standard to make it BEP20.
 */
interface IBEP20Additions {
    /**
     * @dev Returns the token owner.
     */
    function getOwner() external view returns (address);
}