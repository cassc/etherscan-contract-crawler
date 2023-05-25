// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';

// not migrate (create new whitelist)
contract GhostAdminWhitelist is Ownable {
    mapping(address => bool) private _whitelists;
    event UpdateWhitelist(address indexed _address, bool _result);

    // change whitelist status
    constructor(address _admin) {
        _whitelists[_admin] = true;
    }

    /**
     * @param _address: target address
     * @param _result: in whitelist or not
     */
    function updateWhitelist(address _address, bool _result) external onlyOwner {
        _whitelists[_address] = _result;
        emit UpdateWhitelist(_address, _result);
    }

    /**
     * @param _address: target address
     */
    function whitelists(address _address) external view returns (bool) {
        return _whitelists[_address];
    }
}