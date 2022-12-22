// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRoles {
    error SenderIsNotController();

    event ControllerAddressUpdated(address indexed controllerAddress);

    function setControllerAddress(address controllerAddress) external;

    function getControllerAddress() external view returns (address);
}