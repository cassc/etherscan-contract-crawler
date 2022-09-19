// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice An interface for communicating fees to 3rd party marketplaces.
 * @dev Originally implemented in mainnet contract 0x44d6e8933f8271abcf253c72f9ed7e0e4c0323b3
 */
interface IHasSecondarySaleFees {
    /**
     * @notice Returns the recipients that are eligible for royalty
     */
    function getFeeRecipients(uint256 id)
        external
        view
        returns (address payable[] memory);

    /**
     * @notice Returns the fees for a given token id in basis points
     */
    function getFeeBps(uint256 id) external view returns (uint256[] memory);
}