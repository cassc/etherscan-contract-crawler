// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ZunamiElasticRigidVault.sol';

contract UZD is ZunamiElasticRigidVault {
    address public constant ZUNAMI = 0x2ffCC661011beC72e1A9524E12060983E74D14ce;

    constructor()
        ElasticERC20('UZD Zunami Stable', 'UZD')
        ElasticRigidVault(IERC20Metadata(ZUNAMI))
        ZunamiElasticRigidVault(ZUNAMI)
    {}
}