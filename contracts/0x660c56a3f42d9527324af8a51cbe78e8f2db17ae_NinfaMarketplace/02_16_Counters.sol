/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 *
 * @title Counters                                           *
 *                                                           *
 * @dev Stripped down version of OpenZeppelin Contracts       *
 * v4.4.1 (utils/Counters.sol), identical to                 *
 * CountersUpgradeable.sol being a library. Provides         *
 * counters that can only be incremented.                    *
 * Used to track the total supply of ERC721 ids.             *
 * @dev Include with `using Counters for Counters.Counter;`  *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 *
 */
/**
 * @title Counters
 * @dev Stripped down version of OpenZeppelin Contracts v4.4.1
 * (utils/Counters.sol), identical to
 * CountersUpgradeable.sol being a library. Provides counters that can only be
 * incremented. Used to track the total
 * supply of ERC721 ids.
 * @dev Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    /// @dev if implementing ERC721A there could be an overflow risk by removing
    /// overflow protection with `unchecked`,
    /// unless we limit the amount of tokens that can be minted, or require that
    /// totalsupply be less than 2^256 - 1
    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }
}