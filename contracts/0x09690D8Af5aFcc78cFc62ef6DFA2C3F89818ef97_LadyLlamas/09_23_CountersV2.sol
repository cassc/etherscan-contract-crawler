/***
 *     ██████╗ ██████╗ ██╗   ██╗███╗   ██╗████████╗███████╗██████╗ ███████╗
 *    ██╔════╝██╔═══██╗██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝
 *    ██║     ██║   ██║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝███████╗
 *    ██║     ██║   ██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗╚════██║
 *    ╚██████╗╚██████╔╝╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║███████║
 *     ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝
 * @title CountersV2
 * @author Matt Condon (@shrugs), and @MaxFlowO2 (edits)
 * @dev Provides counters that can only be incremented, decremented, reset or set. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Edited by @MaxFlowO2 for more NFT functionality on 13 Jan 2022
 * added .set(uint) so if projects need to start at say 1 or some random number they can
 * and an event log for numbers being reset or set.
 *
 * Include with `using CountersV2 for CountersV2.Counter;`
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library CountersV2 {

  error NegativeNumber();

  event CounterNumberChangedTo(uint _number);

  struct Counter {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    unchecked {
      counter._value += 1;
    }
  }

  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    if (value == 0) {
      revert NegativeNumber();
    }
    unchecked {
      counter._value = value - 1;
    }
  }

  function reset(Counter storage counter) internal {
    counter._value = 0;
    emit CounterNumberChangedTo(counter._value);
  }

  function set(Counter storage counter, uint number) internal {
    counter._value = number;
    emit CounterNumberChangedTo(counter._value);
  }  
}