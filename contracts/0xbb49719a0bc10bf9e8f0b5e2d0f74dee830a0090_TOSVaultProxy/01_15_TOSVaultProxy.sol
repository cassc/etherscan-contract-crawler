//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./TOSVaultStorage.sol";
import "../proxy/VaultProxy.sol";

contract TOSVaultProxy is TOSVaultStorage, VaultProxy {

    function setBaseInfoProxy(
        string memory _name,
        address _token,
        address _owner,
        address _dividedPool
    ) external onlyProxyOwner {
        name = _name;
        token = _token;
        owner = _owner;
        dividiedPool = _dividedPool;

        if(!isAdmin(_owner)){
            _setupRole(PROJECT_ADMIN_ROLE, _owner);
        }

    }
}