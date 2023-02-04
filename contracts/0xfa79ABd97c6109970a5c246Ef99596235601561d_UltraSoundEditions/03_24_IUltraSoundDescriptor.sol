// SPDX-License-Identifier: MIT

/// @title Interface for Ultra Sound Editions Descriptor
/// @author -wizard

pragma solidity ^0.8.6;

import {IUltraSoundGridRenderer} from "./IUltraSoundGridRenderer.sol";
import {IUltraSoundEditions} from "./IUltraSoundEditions.sol";
import {IUltraSoundParts} from "./IUltraSoundParts.sol";

interface IUltraSoundDescriptor {
    event PartsUpdated(IUltraSoundParts icon);
    event RendererUpdated(IUltraSoundGridRenderer renderer);
    event DataURIToggled(bool enabled);
    event BaseURIUpdated(string baseURI);

    error EmptyPalette();
    error BadPaletteLength();
    error IndexNotFound();

    function setParts(IUltraSoundParts _parts) external;

    function setRenderer(IUltraSoundGridRenderer _renderer) external;

    function palettesCount() external view returns (uint256);

    function symbolsCount() external view returns (uint256);

    function gradientsCount() external view returns (uint256);

    function quantitiesCount() external view returns (uint256);

    function tokenURI(
        uint256 tokenId,
        IUltraSoundEditions.Edition memory edition
    ) external view returns (string memory);

    function dataURI(
        uint256 tokenId,
        IUltraSoundEditions.Edition memory edition
    ) external view returns (string memory);

    function tokenSVG(IUltraSoundEditions.Edition memory edition, uint8 size)
        external
        view
        returns (string memory);
}