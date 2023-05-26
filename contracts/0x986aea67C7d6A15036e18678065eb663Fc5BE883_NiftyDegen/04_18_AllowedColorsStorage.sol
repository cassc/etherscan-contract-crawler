// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AllowedColorsStorage
 * @dev Color indexes need to be restricted per tribe prior to NFT deploy
 */
contract AllowedColorsStorage is Ownable {
    /// @dev Mapping if color is allowed for selected tribe
    mapping(uint256 => mapping(uint256 => bool)) private _tribeColorAllowed;

    constructor() {}

    /**
     * @notice Set allowed on a given a list of colors
     * @param tribe Tribe ID 1-10
     * @param colors List of colors to set for tribe
     * @param allowed Bool if the color list should be made allowed or not
     */
    function setAllowedColorsOnTribe(
        uint256 tribe,
        uint256[] memory colors,
        bool allowed
    ) external onlyOwner {
        require(tribe > 0 && tribe < 10, "Invalid tribe provided");
        for (uint256 i = 0; i < colors.length; i++) {
            _toggleColorAllowed(tribe, colors[i], allowed);
        }
    }

    /**
     * @notice Toggle color allowed on and off for a tribe
     * @param tribe Tribe ID
     * @param color Trait ID
     * @param allowed Bool if the color should be made allowed or not
     * @dev Defaults to false if never set
     */
    function _toggleColorAllowed(
        uint256 tribe,
        uint256 color,
        bool allowed
    ) private {
        _tribeColorAllowed[tribe][color] = allowed;
    }

    /**
     * @notice Check if color is allowed for a tribe
     * @param tribe Tribe ID
     * @param color Trait ID
     * @return True if color is allowed for tribe
     */
    function isAllowedColor(uint256 tribe, uint256 color) public view returns (bool) {
        return _tribeColorAllowed[tribe][color];
    }
}