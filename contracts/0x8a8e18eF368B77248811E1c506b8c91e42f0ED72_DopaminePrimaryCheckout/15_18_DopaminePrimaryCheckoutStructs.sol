// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Encapsulation of a Dopamine Marketplace order, which is composed of:
///         - id, a string UUID for uniquely identifying a Dopamine order
///         - purchaser, the address of the entity processing a crypto checkout
///         - signature, a Dopamine signature used to attest order validity
///         - bundles, a list of all Dopamine bundles included in the order
struct Order {
    string id;
    address purchaser;
    bytes signature;
    Bundle[] bundles;
}

/// @notice Encapsulation of a Dopamine Marketplace bundle, which comprises of:
///         - brand, a uint64 identifier for brand attribution (e.g. Nouns)
///         - collection, a uint64 identifier for the collection (e.g. Hoodie)
///         - colorway, a uint64 identifier for the colorway (e.g. Arctic Lime)
///         - size, a uint64 identifier for the bundle's physical (e.g. XL)
///         - price, a uint256 identifier for the bundle's price in USD
struct Bundle {
    uint64 brand;
    uint64 collection;
    uint64 colorway;
    uint64 size;
    uint256 price;
}