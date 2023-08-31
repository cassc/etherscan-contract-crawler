// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

abstract contract Dao {
    event DaoAddressChanged(address _oldDao, address _dao);

    error DaoCannotBeZero();

    // dao address
    address public dao;

    constructor() {}

    modifier onlyDao() {
        require(msg.sender == dao, "PERMISSION_DENIED");
        _;
    }

    // set dao vault address
    // You need to implement contracts to do that
    function setDaoAddress(address _dao) external virtual;
}