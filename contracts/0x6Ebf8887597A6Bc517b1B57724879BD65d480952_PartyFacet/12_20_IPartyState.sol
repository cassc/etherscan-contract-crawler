// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {PartyInfo} from "../../libraries/LibAppStorage.sol";

/**
 * @notice Methods that compose the party and that are mutable
 */
interface IPartyState {
    /**
     * @notice Queries the Party denomination asset (ERC-20)
     * @dev The denomination asset is used for depositing into the party, which is an ERC-20 stablecoin
     * @return Denomination asset address
     */
    function denominationAsset() external view returns (address);

    /**
     * @notice Queries the Party's creator address
     * @return The address of the user who created the Party
     */
    function creator() external view returns (address);

    /**
     * @notice Queries the Party's member access of given address
     * @param account Address
     * @return Whether if the given address is a member
     */
    function members(address account) external view returns (bool);

    /**
     * @notice Queries the Party's manager access of given address
     * @param account Address
     * @return Whether if the given address is a manager
     */
    function managers(address account) external view returns (bool);

    /**
     * @notice Queries the ERC-20 tokens held in the Party
     * @dev Will display the tokens that were acquired through a Swap/LimitOrder method
     * @return Array of ERC-20 addresses
     */
    function getTokens() external view returns (address[] memory);

    /**
     * @notice Queries the party information
     * @return PartyInfo struct
     */
    function partyInfo() external view returns (PartyInfo memory);

    /**
     * @notice Queries if the Party is closed
     * @return Whether if the Party is already closed or not
     */
    function closed() external view returns (bool);
}