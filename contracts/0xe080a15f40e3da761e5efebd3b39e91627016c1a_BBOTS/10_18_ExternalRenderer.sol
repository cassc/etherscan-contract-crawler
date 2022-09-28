// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IMetadataRenderer} from "../interface/MetadataRenderer.interface.sol";

contract ExternalRenderer {
    error MetadataLocked();

    IMetadataRenderer public renderer;
    bool public metadataLocked;

    constructor(IMetadataRenderer _renderer) {
        renderer = _renderer;
    }

    modifier requireMetadataUnlocked() {
        if (metadataLocked) revert MetadataLocked();
        _;
    }

    function _updateMetadataRenderer(address _renderer)
        internal
        virtual
        requireMetadataUnlocked
    {
        renderer = IMetadataRenderer(_renderer);
    }

    function _lockMetadata() internal virtual requireMetadataUnlocked {
        metadataLocked = true;
    }
}