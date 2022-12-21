// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title ERC721TimeTrackable
 * @dev ERC721 contract that allows to get time created and time held for a token
 * @author North Technologies
 * @custom:version 1.1
 * @custom:date 30 April 2022
 *
 * @custom:changelog
 *
 * v1.1
 * - More efficient storage of block time in uint64
 * - Moved created and held times into a struct
 */
abstract contract ERC721TimeTrackable is ERC721 {
    struct TimeRegister {
        uint64 created;
        uint64 held;
    }

    mapping(uint256 => TimeRegister) private _timeRegister;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            // solhint-disable-next-line not-rely-on-time
            _timeRegister[tokenId].created = uint64(block.timestamp);
        } else {
            // solhint-disable-next-line not-rely-on-time
            _timeRegister[tokenId].held = uint64(block.timestamp);
        }
    }

    /**
     * @dev Returns the time created for a token
     */
    function getTimeCreated(uint256 tokenId) public view returns (uint64) {
        return _timeRegister[tokenId].created;
    }

    /**
     * @dev Returns the time held for a token
     */
    function getTimeHeld(uint256 tokenId) public view returns (uint64) {
        return _timeRegister[tokenId].held;
    }
}