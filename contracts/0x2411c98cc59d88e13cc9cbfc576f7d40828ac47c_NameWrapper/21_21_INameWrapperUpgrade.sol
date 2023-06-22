//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

interface INameWrapperUpgrade {
    function wrap(
        string calldata label,
        address wrappedOwner,
        uint32 fuses,
        uint64 expiry,
        address resolver
    ) external;
}