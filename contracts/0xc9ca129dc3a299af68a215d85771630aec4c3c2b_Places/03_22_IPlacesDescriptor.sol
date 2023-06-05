// SPDX-License-Identifier: MIT

/// @title Interface for Places descriptor
/// @author Places DAO

/*************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░███░░░░░░░░░░░░░███░░░░░░░ *
 * ░▒▒▒░░░███░░░░░░░░░░░░░███░░░▒▒▒░ *
 * ░▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒░ *
 * ░░░░█████████████████████████░░░░ *
 * ░░░░░░█████    ███    █████░░░░░░ *
 * ░░░░░░░░█████████████████░░░░░░░░ *
 * ░░░░░░░░░░████▓▓▓▓▓▓███░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *************************************/

pragma solidity ^0.8.6;

import {IPlaces} from "./IPlaces.sol";

interface IPlacesDescriptor {
    function constructContractURI() external pure returns (string memory);

    function constructTokenURI(uint256 tokenId, IPlaces.Place memory place)
        external
        pure
        returns (string memory);
}