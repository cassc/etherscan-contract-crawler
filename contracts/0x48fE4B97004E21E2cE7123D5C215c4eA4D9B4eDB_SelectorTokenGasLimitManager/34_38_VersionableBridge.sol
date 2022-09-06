// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

abstract contract VersionableBridge {
    function getBridgeInterfacesVersion()
        external
        pure
        virtual
        returns (
            uint64 major,
            uint64 minor,
            uint64 patch
        );

    function getBridgeMode() external pure virtual returns (bytes4);
}