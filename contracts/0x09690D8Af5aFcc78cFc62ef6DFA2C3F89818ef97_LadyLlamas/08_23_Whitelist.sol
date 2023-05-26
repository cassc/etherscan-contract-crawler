/***
 *    ██╗    ██╗██╗  ██╗██╗████████╗███████╗██╗     ██╗███████╗████████╗
 *    ██║    ██║██║  ██║██║╚══██╔══╝██╔════╝██║     ██║██╔════╝╚══██╔══╝
 *    ██║ █╗ ██║███████║██║   ██║   █████╗  ██║     ██║███████╗   ██║   
 *    ██║███╗██║██╔══██║██║   ██║   ██╔══╝  ██║     ██║╚════██║   ██║   
 *    ╚███╔███╔╝██║  ██║██║   ██║   ███████╗███████╗██║███████║   ██║   
 *     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚═╝╚══════╝   ╚═╝   
 * @title Whitelist
 * @author @MaxFlowO2 on Twitter/GitHub
 *  Written on 12 Jan 2022, post Laid Back Llamas, aka LLAMA TECH!
 * @dev Provides a whitelist capability that can be added to and removed easily. With
 *  a modified version of Countes.sol from openzeppelin 4.4.1 you can track numbers of who's
 *  on the whitelist and who's been removed from the whitelist, showing clear statistics of
 *  your contract's whitelist usage.
 *
 * Include with 'using Whitelist for Whitelist.List;'
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./CountersV2.sol";

library Whitelist {
  using CountersV2 for CountersV2.Counter;

  event WhiteListEndChanged(uint _old, uint _new);
  event WhiteListChanged(bool _old, bool _new, address _address);
  event WhiteListStatus(bool _old, bool _new);

  struct List {
    // These variables should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    bool enabled; //default is false,
    CountersV2.Counter _added; // default 0, no need to _added.set(uint)
    CountersV2.Counter _removed; // default 0, no need to _removed.set(uint)
    uint end; // default 0, this can be time or quant
    mapping(address => bool) _list; // all values default to false
  }

  function add(List storage list, address _address) internal {
    require(!list._list[_address], "Whitelist: Address already whitelisted.");
    // since now all previous values are false no need for another variable
    // and add them to the list!
    list._list[_address] = true;
    // increment counter
    list._added.increment();
    // emit event
    emit WhiteListChanged(false, list._list[_address], _address);
  }

  function remove(List storage list, address _address) internal {
    require(list._list[_address], "Whitelist: Address already not whitelisted.");
    // since now all previous values are true no need for another variable
    // and remove them from the list!
    list._list[_address] = false;
    // increment counter
    list._removed.increment();
    // emit event
    emit WhiteListChanged(true, list._list[_address], _address);
  }

  function enable(List storage list) internal {
    require(!list.enabled, "Whitelist: Whitelist already enabled.");
    list.enabled = true;
    emit WhiteListStatus(false, list.enabled);
  }

  function disable(List storage list) internal {
    require(list.enabled, "Whitelist: Whitelist already enabled.");
    list.enabled = false;
    emit WhiteListStatus(true, list.enabled);
  }

  function setEnd(List storage list, uint newEnd) internal {
    require(list.end != newEnd, "Whitelist: End already set to that value.");
    uint old = list.end;
    list.end = newEnd;
    emit WhiteListEndChanged(old, list.end);
  }

  function status(List storage list) internal view returns (bool) {
    return list.enabled;
  }

  function totalAdded(List storage list) internal view returns (uint) {
    return list._added.current();
  }

  function totalRemoved(List storage list) internal view returns (uint) {
    return list._removed.current();
  }

  function onList(List storage list, address _address) internal view returns (bool) {
    return list._list[_address];
  }

  function showEnd(List storage list) internal view returns (uint) {
    return list.end;
  }
}