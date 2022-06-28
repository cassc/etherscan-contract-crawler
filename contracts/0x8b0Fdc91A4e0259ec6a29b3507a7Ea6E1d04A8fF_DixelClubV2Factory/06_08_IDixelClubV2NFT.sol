// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.13;

import "./Shared.sol";

interface IDixelClubV2NFT {
    function init(
        address owner_,
        string calldata name_,
        string calldata symbol_,
        string calldata description_,
        Shared.MetaData calldata metaData_,
        uint24[16] calldata palette_,
        uint8[288] calldata pixels_
    ) external;
}