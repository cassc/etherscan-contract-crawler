// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Distributions {
    struct Uint256 {
        mapping(address => uint256) _values;
        uint256 _total;
    }

    function valueOf(Uint256 storage self, address account) internal view returns (uint256) {
        return self._values[account];
    }

    function total(Uint256 storage self) internal view returns (uint256) {
        return self._total;
    }

    function set(Uint256 storage self, address account, uint256 amount) internal {
        self._total = self._total - self._values[account] + amount;
        self._values[account] = amount;
    }

    function incr(Uint256 storage self, address account, uint256 amount) internal {
        self._total += amount;
        self._values[account] += amount;
    }

    function decr(Uint256 storage self, address account, uint256 amount) internal {
        self._total -= amount;
        self._values[account] -= amount;
    }

    function mv(Uint256 storage self, address from, address to, uint256 amount) internal {
        self._values[from] -= amount;
        self._values[to] += amount;
    }

    struct Int256 {
        mapping(address => int256) _values;
        int256 _total;
    }

    function valueOf(Int256 storage self, address account) internal view returns (int256) {
        return self._values[account];
    }

    function total(Int256 storage self) internal view returns (int256) {
        return self._total;
    }

    function set(Int256 storage self, address account, int256 amount) internal {
        self._total += amount - self._values[account];
        self._values[account] = amount;
    }

    function incr(Int256 storage self, address account, int256 amount) internal {
        self._total += amount;
        self._values[account] += amount;
    }

    function decr(Int256 storage self, address account, int256 amount) internal {
        self._total -= amount;
        self._values[account] -= amount;
    }

    function mv(Int256 storage self, address from, address to, int256 amount) internal {
        self._values[from] -= amount;
        self._values[to] += amount;
    }
}