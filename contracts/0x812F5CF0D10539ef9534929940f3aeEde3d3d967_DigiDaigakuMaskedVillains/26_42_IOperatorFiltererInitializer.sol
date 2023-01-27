// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IOperatorFiltererInitializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include OpenSea's OperatorFilterer functionality.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IOperatorFiltererInitializer {

    /**
     * @notice Initializes parameters of OperatorFilterer contracts
     */
    function initializeOperatorFilterer(address subscriptionOrRegistrantToCopy, bool subscribe) external;
}