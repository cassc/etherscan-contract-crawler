//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../admin-manager/AdminManagerUpgradable.sol";

abstract contract SupplyUpgradable is Initializable, AdminManagerUpgradable {
    uint256 internal _maxSupply;

    function __Supply_init(uint256 maxSupply_) internal onlyInitializing {
        __AdminManager_init_unchained();
        __Supply_init_unchained(maxSupply_);
    }

    function __Supply_init_unchained(uint256 maxSupply_)
        internal
        onlyInitializing
    {
        _maxSupply = maxSupply_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyAdmin {
        _maxSupply = maxSupply_;
    }

    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    function _currentSupply() internal view virtual returns (uint256);

    modifier onlyInSupply(uint256 amount_) {
        require(_currentSupply() + amount_ <= _maxSupply, "Exceeds supply");
        _;
    }

    uint256[49] private __gap;
}