// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { EnumerableSet } from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

/**
 * @title Positions Manager State
 */
interface IPositionManagerState {

    /**
    * @dev Struct holding Position `LP` state.
    * @param lps         [WAD] position LP.
    * @param depositTime Deposit time for position
    */
    struct Position {
        uint256 lps;
        uint256 depositTime;
    }

    /**
    * @dev Struct tracking a position token info.
    * @param pool            The pool address associated with the position.
    * @param positionIndexes Mapping tracking indexes to which a position is associated.
    * @param positions       Mapping tracking a positions state in a bucket index.
    */
    struct TokenInfo {
        address pool;
        EnumerableSet.UintSet positionIndexes;
        mapping(uint256 index => Position) positions;
    }

}