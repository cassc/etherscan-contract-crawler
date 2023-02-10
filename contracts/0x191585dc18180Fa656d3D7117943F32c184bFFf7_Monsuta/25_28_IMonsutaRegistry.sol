// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IMonsutaRegistry {
    function getTraitsOfMonsutaId(uint256 monsutaId)
        external
        view
        returns (
            string memory character,
            string memory monsuta,
            string memory eyeColor,
            string memory skinColor,
            string memory item
        );

    function getEncodedTraitsOfMonsutaId(uint256 monsutaId, uint256 state)
        external
        view
        returns (bytes memory traits);
}