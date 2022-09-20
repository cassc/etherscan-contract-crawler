// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ZunamiElasticVault.sol';

contract ELT is ZunamiElasticVault {
    address public constant ZUNAMI = 0x2ffCC661011beC72e1A9524E12060983E74D14ce;

    constructor()
        ElasticERC20('Elastic Token', 'ELT')
        ElasticVault(IERC20Metadata(ZUNAMI))
        ZunamiElasticVault(ZUNAMI)
    {}
}