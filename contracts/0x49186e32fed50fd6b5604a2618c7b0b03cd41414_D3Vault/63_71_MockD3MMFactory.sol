// SPDX-License-Identifier: MIT

import "contracts/DODOV3MM/periphery/D3MMFactory.sol";

pragma solidity 0.8.16;

contract MockD3MMFactory is D3MMFactory {
    constructor(
        address owner,
        address[] memory d3Temps,
        address[] memory d3MakerTemps,
        address cloneFactory,
        address d3VaultAddress,
        address oracleAddress,
        address feeRateModel,
        address maintainer
    ) D3MMFactory(
        owner,
        d3Temps,
        d3MakerTemps,
        cloneFactory,
        d3VaultAddress,
        oracleAddress,
        feeRateModel,
        maintainer
    ) {}

    function addD3Pool(address pool) public {
        d3Vault.addD3PoolByFactory(pool);
    }
}