// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@solidstate/contracts/proxy/diamond/Diamond.sol';
import '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol';

contract MagicProxy is Diamond {
    constructor() {
        ERC20MetadataStorage.Layout storage l = ERC20MetadataStorage.layout();
        l.name = 'MAGIC';
        l.symbol = 'MAGIC';
    }
}