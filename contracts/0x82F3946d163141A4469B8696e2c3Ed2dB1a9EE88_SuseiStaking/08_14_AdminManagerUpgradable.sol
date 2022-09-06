//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AdminManagerUpgradable is Initializable {
    mapping(address => bool) private _admins;

    function __AdminManager_init() internal onlyInitializing {
        __AdminManager_init_unchained();
    }

    function __AdminManager_init_unchained() internal onlyInitializing {
        _admins[msg.sender] = true;
    }

    function setAdminPermissions(address account_, bool enable_)
        external
        onlyAdmin
    {
        _admins[account_] = enable_;
    }

    function isAdmin(address account_) public view returns (bool) {
        return _admins[account_];
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Not an admin");
        _;
    }

    uint256[49] private __gap;
}