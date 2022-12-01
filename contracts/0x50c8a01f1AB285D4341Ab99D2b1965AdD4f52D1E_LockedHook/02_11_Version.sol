// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IVersion.sol";
abstract contract Version is IVersion {
    uint8 private _major;
    uint8 private _minor;
    uint16 private _patch;

    function setVersionMetaData(uint8 major, uint8 minor, uint16 patch) internal {
        _major = major;
        _minor = minor;
        _patch = patch;
    }

    function version() public view override returns(uint8,uint8,uint16) {
        return (_major, _minor, _patch);
    }

}