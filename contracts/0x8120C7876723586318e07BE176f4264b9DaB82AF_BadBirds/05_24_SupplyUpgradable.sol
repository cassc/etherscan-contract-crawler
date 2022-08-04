//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../admin-manager/AdminManagerUpgradable.sol";
import "../balance-limit/BalanceLimit.sol";

contract SupplyUpgradable is Initializable, AdminManagerUpgradable {
    using BalanceLimit for BalanceLimit.Data;

    BalanceLimit.Data internal _supply;

    function __Supply_init(uint256 maxSupply_) internal onlyInitializing {
        __AdminManager_init_unchained();
        __Supply_init_unchained(maxSupply_);
    }

    function __Supply_init_unchained(uint256 maxSupply_)
        internal
        onlyInitializing
    {
        _supply.limit = maxSupply_;
    }

    function _increaseSupply(uint256 amount_) internal {
        _supply.increaseBalance(address(this), amount_);
    }

    function setMaxSupply(uint256 maxSupply_) external onlyAdmin {
        _supply.limit = maxSupply_;
    }

    function maxSupply() external view returns (uint256) {
        return _supply.limit;
    }

    uint256[49] private __gap;
}