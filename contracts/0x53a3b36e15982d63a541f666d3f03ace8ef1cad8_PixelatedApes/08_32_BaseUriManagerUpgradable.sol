//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./AdminManagerUpgradable.sol";

contract BaseUriManagerUpgradable is Initializable, AdminManagerUpgradable {
    string internal _baseUri;

    function __BaseUriManager_init(string memory baseUri_)
        internal
        onlyInitializing
    {
        __AdminManager_init_unchained();
        __BaseUriManager_init_unchained(baseUri_);
    }

    function __BaseUriManager_init_unchained(string memory baseUri_)
        internal
        onlyInitializing
    {
        _baseUri = baseUri_;
    }

    function setBaseUri(string calldata baseUri_) external onlyAdmin {
        _baseUri = baseUri_;
    }

    uint256[49] private __gap;
}