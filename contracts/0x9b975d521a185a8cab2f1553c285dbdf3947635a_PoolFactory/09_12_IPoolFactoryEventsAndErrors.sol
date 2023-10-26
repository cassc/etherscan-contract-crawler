// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IPoolFactoryEventsAndErrors {
    error NotERC721();
    error AlreadyDeployed();

    event NewPoolCreated(address deployment,address creator, address collection);
}