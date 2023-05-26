// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract NeonIstByDevrimErbilSplitsAndRoyalties is ERC2981 {
    address[] internal addresses = [
        0x280fB84649b2744536B0FfEDb0dd36472F708467, // Studio Wallet1
        0x9f65B9E48126AebfF592CAA39Ad6ba25766E5208, // Studio Wallet2
        0x4474efe96982D38997B5BbF231EABB587201124E // Dr3am
    ];

    uint256[] internal splits = [43, 43, 14];

    uint96 private constant DEFAULT_ROYALTY_BASIS_POINTS = 1000;

    constructor() {
        // Default royalty information to be this contract, so that no potential
        // royalty payments are missed by marketplaces that support ERC2981.
        _setDefaultRoyalty(address(this), DEFAULT_ROYALTY_BASIS_POINTS);
    }
}