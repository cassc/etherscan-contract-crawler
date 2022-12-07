// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract CosmicBloomSplitsAndRoyalties is ERC2981 {
    address[] internal addresses = [
        0x19A9215201C647d3E7c52661b06C010972e73E9c,
        0x41Fb9227c703086B2d908E177A692EdCD3d7DE2C,
        0xb67dEB598736CE3C2B7b709c9Bf7bc911b31a0aF
    ];

    uint256[] internal splits = [750, 125, 125];

    uint96 private constant DEFAULT_ROYALTY_BASIS_POINTS = 1000; // 10%

    constructor() {
        // Default royalty information to be this contract, so that no potential
        // royalty payments are missed by marketplaces that support ERC2981.
        _setDefaultRoyalty(address(this), DEFAULT_ROYALTY_BASIS_POINTS);
    }
}