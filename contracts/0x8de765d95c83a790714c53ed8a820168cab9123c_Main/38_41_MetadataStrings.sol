// SPDX-License-Identifier: CC0-1.0

// solhint-disable no-global-import

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./StringBank.sol";

contract MetadataStrings is Ownable {
    mapping(uint256 => address) private _banks;

    bytes private _missing;

    function getString(
        uint256 bank,
        uint256 index
    ) external view returns (bytes memory value) {
        value = IStringBank(_banks[bank]).getString(index);
        if (value.length == 0) {
            value = _missing;
        }
    }

    function setBanks(address[] calldata addresses_) external onlyOwner {
        for (uint256 i; i < addresses_.length; i++) {
            _banks[i] = addresses_[i];
        }
    }

    function setMissing(string calldata missing_) external onlyOwner {
        _missing = bytes(missing_);
    }
}