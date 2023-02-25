// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

import {IOracle} from "IOracle.sol";

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title Relation
/// @notice Relation - Oracle defining relation between underlying tranche assets
///
///     ###############################################
///     Relation Specification
///     ###############################################
///
///     The Relation module is the second part of the GTranche building blocks,
///         it allows us to create a separate definition of how the underlying tranche
///         assets relate to one another without making changes to the core tranche logic.
///     By relation, we mean a common denominator between all the underlying assets that
///         will be used to price the tranche tokens. Generally speaking, its likely that
///         this will be a price oracle or bonding curve of some sort, but the choice
///         (and by extension) implementation is left as an exercise to the user ;)
///     This modularity exists in order to allow for the GTranche to fulfill different
///         requirements, as we can specify how we want to facilitate protection (tranching)
///         based on how we relate the underlying tokens to one another.
///
///     The following logic need to be implemented in the relation contract:
///         - Swapping price: How much of token x do I get for token y?
///         - Single price: What is the value of token x in a common denominator
///         - token amount: How much of token x do I get from common denominator y
///         - total value: What is the combined value of all underlying tokens in a common denominator
abstract contract Relation is IOracle {
    uint256 constant DEFAULT_FACTOR = 1_000_000_000_000_000_000;

    constructor() {}

    function getSwappingPrice(
        uint256 _i,
        uint256 _j,
        uint256 _amount,
        bool _deposit
    ) external view virtual override returns (uint256);

    function getSinglePrice(
        uint256 _i,
        uint256 _amount,
        bool _deposit
    ) external view virtual override returns (uint256);

    function getTokenAmount(
        uint256 _i,
        uint256 _amount,
        bool _deposit
    ) external view virtual override returns (uint256);

    function getTotalValue(uint256[] memory _amounts)
        external
        view
        virtual
        override
        returns (uint256);
}