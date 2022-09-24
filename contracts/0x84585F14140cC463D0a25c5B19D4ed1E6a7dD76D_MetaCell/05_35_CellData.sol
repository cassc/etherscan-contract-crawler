// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
 * @title Representation of cell with it fields
 */
library CellData {
    /**
     *  Represents the standart roles
     *  on which cell can be divided
     */
    enum Class {
        INIT,
        COMMON,
        SPLITTABLE_NANO,
        SPLITTABLE_BIOMETA,
        SPLITTABLE_ENHANCER,
        FINISHED
    }

    function isSplittable(Class _class) internal pure returns (bool) {
        return
            _class == Class.SPLITTABLE_NANO ||
            _class == Class.SPLITTABLE_BIOMETA ||
            _class == Class.SPLITTABLE_ENHANCER;
    }

    /**
     *  Represents the basic parameters that describes cell
     */
    struct Cell {
        uint256 tokenId;
        address user;
        Class class;
        uint256 stage;
        uint256 nextEvolutionBlock;
        uint256 variant;
        bool onSale;
        uint256 price;
    }
}