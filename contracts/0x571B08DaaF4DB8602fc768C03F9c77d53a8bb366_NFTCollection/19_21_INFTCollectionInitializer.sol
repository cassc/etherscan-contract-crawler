// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

/**
 * @author interakt
 */
interface INFTCollectionInitializer {
    function initialize(
        string memory _name,
        string memory _symbol,
        address _admin
    ) external;
}