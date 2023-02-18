// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBusinessAddresses {
    error BusinessAddresses__NotExist();
    error BusinessAddresses__Existed();
    error BusinessAddresses__NotAuthorized();

    event BusinessNew(address[] indexed accounts);
    event BusinessCancel(address[] indexed accounts);
}