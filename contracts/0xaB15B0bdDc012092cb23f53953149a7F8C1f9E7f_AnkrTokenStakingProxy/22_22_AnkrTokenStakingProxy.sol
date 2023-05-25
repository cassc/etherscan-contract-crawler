// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "@ankr.com/contracts/libs/ManageableProxy.sol";
import "@ankr.com/contracts/protocol/AnkrTokenStaking.sol";

contract AnkrTokenStakingProxy is ManageableProxy {

    constructor(IStakingConfig stakingConfig, IERC20 ankrToken) ManageableProxy(
        stakingConfig, _deployDefault(),
        abi.encodeWithSelector(AnkrTokenStaking.initialize.selector, stakingConfig, ankrToken)
    ) {
    }

    function _deployDefault() internal returns (address) {
        AnkrTokenStaking impl = new AnkrTokenStaking{
        salt : keccak256("AnkrTokenStakingV0")
        }();
        return address(impl);
    }
}