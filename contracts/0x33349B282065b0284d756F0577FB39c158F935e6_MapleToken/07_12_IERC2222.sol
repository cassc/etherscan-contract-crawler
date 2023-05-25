// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface IERC2222 {
    /**
     * @dev Returns the total amount of funds a given address is able to withdraw currently.
     * @param owner Address of FDT holder
     * @return A uint256 representing the available funds for a given account
     */
    function withdrawableFundsOf(address owner) external view returns (uint256);

    /**
     * @dev Withdraws all available funds for a FDT holder. 
     */
    function withdrawFunds() external;

    /**
     * @dev This event emits when new funds are distributed
     * @param by the address of the sender who distributed funds
     * @param fundsDistributed the amount of funds received for distribution
     */
    event FundsDistributed(address indexed by, uint256 fundsDistributed);

    /**
     * @dev This event emits when distributed funds are withdrawn by a token holder.
     * @param by the address of the receiver of funds
     * @param fundsWithdrawn the amount of funds that were withdrawn
     * @param totalWithdrawn the total amount of funds that were withdrawn
     */
    event FundsWithdrawn(address indexed by, uint256 fundsWithdrawn, uint256 totalWithdrawn);
}