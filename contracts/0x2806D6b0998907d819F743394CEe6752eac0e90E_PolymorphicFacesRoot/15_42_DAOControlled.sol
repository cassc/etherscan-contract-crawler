// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

abstract contract DAOControlled {
    address payable public daoAddress;

    constructor(address payable _daoAddress) {
        daoAddress = _daoAddress;
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Not called from the dao");
        _;
    }
}