// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

struct PathOption {
    address target;
    uint8 option;
    uint8 totalOptions;
}

library PathOptionOps {
    /// @dev returns path option for providede target, zero if nothing was found
    function getPathOption(PathOption[] memory p, address target)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i; i < p.length; ) {
            if (p[i].target == target) {
                return p[i].option;
            }

            unchecked {
                ++i;
            }
        }
        return 0;
    }

    function nextOption(PathOption[] memory p)
        internal
        pure
        returns (PathOption[] memory newOption, bool hasNext)
    {
        if (p.length == 0) {
            return (p, false);
        }

        newOption = p;
        uint256 len = newOption.length;

        for (uint256 i = len - 1; ; ) {
            newOption[i].option++;

            if (i == 0 && newOption[i].option == newOption[i].totalOptions) {
                return (newOption, false);
            }

            if (newOption[i].option == newOption[i].totalOptions) {
                newOption[i].option = 0;
            } else {
                return (newOption, true);
            }
            unchecked {
                --i;
            }
        }
    }

    function concat(PathOption[] memory po1, PathOption[] memory po2)
        internal
        pure
        returns (PathOption[] memory res)
    {
        uint256 len1 = po1.length;
        uint256 lenTotal = len1 + po2.length;

        if (lenTotal == len1) return po1;

        res = new PathOption[](lenTotal);

        for (uint256 i; i < lenTotal; ) {
            res[i] = (i < len1) ? po1[i] : po2[i - len1];
            unchecked {
                ++i;
            }
        }
    }
}