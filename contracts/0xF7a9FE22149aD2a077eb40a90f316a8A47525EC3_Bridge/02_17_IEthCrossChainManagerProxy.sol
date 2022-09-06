// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;


interface IEthCrossChainManagerProxy {
    function getEthCrossChainManager() external view returns (address);
}