//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./TypeCVaultStorage.sol";
import "../proxy/VaultProxy.sol";

contract TypeCVaultProxy is TypeCVaultStorage, VaultProxy {

    function setBaseInfoProxy(
        string memory _name,
        address _token,
        address _owner
    ) external onlyProxyOwner {
        name = _name;
        token = _token;
        owner = _owner;

        if(!isAdmin(_owner)){
            _setupRole(PROJECT_ADMIN_ROLE, _owner);
        }

    }
}