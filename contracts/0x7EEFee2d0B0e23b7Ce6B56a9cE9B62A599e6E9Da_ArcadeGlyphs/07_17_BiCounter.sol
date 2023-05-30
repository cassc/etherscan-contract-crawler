// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.8.0;

library BiCounters {
    struct BiCounter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(BiCounter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(BiCounter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(BiCounter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(BiCounter storage counter, uint value) internal {
        counter._value = value;
    }
}