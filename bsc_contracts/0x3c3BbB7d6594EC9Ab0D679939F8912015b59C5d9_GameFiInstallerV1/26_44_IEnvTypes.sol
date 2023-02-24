// SPDX-License-Identifier: BUSL-1.1
// GameFi Core™ by CDEVS

pragma solidity 0.8.10;

interface IEnvTypes {
    struct Environment {
        uint256[] instances;
        string environmentName;
    }

    struct EnvInstance {
        uint256 environmentId;
        uint256 instanceType;
        address instanceContract;
        address instanceImplementation;
    }
}