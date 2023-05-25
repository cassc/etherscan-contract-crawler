// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IWrapperERC721Initializer
 * @author Limit Break, Inc.
 * @notice Allows cloneable contracts to include Wrapper ERC721 functionality.
 * @dev See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
interface IWrapperERC721Initializer {

    /**
     * @notice Initializes parameters of {WrapperERC721} contracts
     */
    function initializeWrapperERC721(address wrappedCollection_) external;
}