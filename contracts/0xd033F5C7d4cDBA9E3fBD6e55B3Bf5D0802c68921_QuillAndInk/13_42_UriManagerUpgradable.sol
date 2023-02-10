//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../admin-manager/AdminManagerUpgradable.sol";

contract UriManagerUpgradable is Initializable, AdminManagerUpgradable {
    using StringsUpgradeable for uint256;

    string internal _prefix;
    string internal _suffix;

    function prefix() public view returns (string memory) {
        return _prefix;
    }

    function suffix() public view returns (string memory) {
        return _suffix;
    }

    function __UriManager_init(string memory prefix_, string memory suffix_)
        internal
        onlyInitializing
    {
        __AdminManager_init_unchained();
        __UriManager_init_unchained(prefix_, suffix_);
    }

    function __UriManager_init_unchained(
        string memory prefix_,
        string memory suffix_
    ) internal onlyInitializing {
        _prefix = prefix_;
        _suffix = suffix_;
    }

    function _buildUri(uint256 tokenId) internal view returns (string memory) {
        return string(abi.encodePacked(_prefix, tokenId.toString(), _suffix));
    }

    function setPrefix(string calldata prefix_) external onlyAdmin {
        _prefix = prefix_;
    }

    function setSuffix(string calldata suffix_) external onlyAdmin {
        _suffix = suffix_;
    }

    uint256[48] private __gap;
}