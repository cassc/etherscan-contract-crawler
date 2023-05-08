// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IWineManagerPoolIntegration {

    function allowMint(address) external view returns (bool);
    function allowInternalTransfers(address) external view returns (bool);
    function allowBurn(address) external view returns (bool);

}