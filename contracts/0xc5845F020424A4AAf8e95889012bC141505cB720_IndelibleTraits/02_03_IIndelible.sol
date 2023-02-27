// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IIndelible {
    struct Trait {
        string name;
        string mimetype;
    }

    function traitData(uint layerIndex, uint traitIndex)
        external
        view
        returns (string memory);

    function traitDetails(uint layerIndex, uint traitIndex)
        external
        view
        returns (Trait memory);
}