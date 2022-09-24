// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./Distributions.sol";


library Balances {
    using Distributions for Distributions.Uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Fungible {
        Distributions.Uint256 _balances;
    }

    function balanceOf(Fungible storage self, address account) internal view returns (uint256) {
        return self._balances.valueOf(account);
    }

    function totalSupply(Fungible storage self) internal view returns (uint256) {
        return self._balances.total();
    }

    function mint(Fungible storage self, address to, uint256 amount) internal {
        self._balances.incr(to, amount);
    }

    function burn(Fungible storage self, address from, uint256 amount) internal {
        require(self._balances.valueOf(from) >= amount, "burn amount exceeds balance");
        self._balances.decr(from, amount);
    }

    function transfer(Fungible storage self, address from, address to, uint256 amount) internal {
        require(self._balances.valueOf(from) >= amount, "transfer amount exceeds balance");
        self._balances.mv(from, to, amount);
    }

    struct NonFungible {
        mapping(uint256 => address) _owner;
    }

    function ownerOf(NonFungible storage self, uint256 tokenid) internal view returns (address) {
        return self._owner[tokenid];
    }

    function mint(NonFungible storage self, address to, uint256 tokenid) internal {
        require(ownerOf(self, tokenid) == address(0), "token already exists");
        self._owner[tokenid] = to;
    }

    function burn(NonFungible storage self, address from, uint256 tokenid) internal {
        require(ownerOf(self, tokenid) == from, "token doesn't exist");
        self._owner[tokenid] = address(0);
    }

    function transfer(NonFungible storage self, address from, address to, uint256 tokenid) internal {
        require(ownerOf(self, tokenid) == from, "token doesn't exist");
        self._owner[tokenid] = to;
    }

    // struct NonFungibleEnumerable {
    //     NonFungible                               _base;
    //     EnumerableSet.UintSet                     _allTokens;
    //     mapping(address => EnumerableSet.UintSet) _userTokens;
    // }

    // function balanceOf(NonFungibleEnumerable storage self, address account) internal view returns (uint256) {
    //     return self._userTokens[account].length();
    // }

    // function at(NonFungibleEnumerable storage self, address account, uint256 idx) internal view returns (uint256) {
    //     return self._userTokens[account].at(idx);
    // }

    // function totalSupply(NonFungibleEnumerable storage self) internal view returns (uint256) {
    //     return self._allTokens.length();
    // }

    // function at(NonFungibleEnumerable storage self, uint256 idx) internal view returns (uint256) {
    //     return self._allTokens.at(idx);
    // }

    // function ownerOf(NonFungibleEnumerable storage self, uint256 tokenid) internal view returns (address) {
    //     return ownerOf(self._base, tokenid);
    // }

    // function mint(NonFungibleEnumerable storage self, address to, uint256 tokenid) internal {
    //     mint(self._base, to, tokenid);
    //     self._allTokens.add(tokenid);
    //     self._userTokens[to].add(tokenid);
    // }

    // function burn(NonFungibleEnumerable storage self, address from, uint256 tokenid) internal {
    //     burn(self._base, from, tokenid);
    //     self._allTokens.remove(tokenid);
    //     self._userTokens[from].remove(tokenid);
    // }

    // function transfer(NonFungibleEnumerable storage self, address from, address to, uint256 tokenid) internal {
    //     transfer(self._base, from, to, tokenid);
    //     self._userTokens[from].remove(tokenid);
    //     self._userTokens[to].add(tokenid);
    // }
}