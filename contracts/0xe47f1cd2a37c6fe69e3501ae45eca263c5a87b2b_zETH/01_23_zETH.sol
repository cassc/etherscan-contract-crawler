// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ZunamiElasticRigidVault.sol';

contract zETH is ZunamiElasticRigidVault {
    address public constant ZUNAMI = 0x9dE83985047ab3582668320A784F6b9736c6EEa7;

    constructor()
        ElasticERC20('Zunami ETH', 'zETH')
        ElasticRigidVault(IERC20Metadata(ZUNAMI))
        ZunamiElasticRigidVault(ZUNAMI)
    {}
}