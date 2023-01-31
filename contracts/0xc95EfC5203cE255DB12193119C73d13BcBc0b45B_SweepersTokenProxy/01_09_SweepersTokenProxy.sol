// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { TransparentUpgradeableProxy } from '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract SweepersTokenProxy is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin,
        address _sweepersTreasury,
        address _minter,
        address _descriptor,
        address _seeder,
        address _proxyRegistry,
        address _sweepersV1,
        uint256 __currentSweeperId,
        address _dust
    ) TransparentUpgradeableProxy(logic, admin, generateData(
        _sweepersTreasury,
        _minter,
        _descriptor,
        _seeder,
        _proxyRegistry,
        _sweepersV1,
        __currentSweeperId,
        _dust
        )) {}

    function generateData(
        address _sweepersTreasury,
        address _minter,
        address _descriptor,
        address _seeder,
        address _proxyRegistry,
        address _sweepersV1,
        uint256 __currentSweeperId,
        address _dust
    ) internal pure returns (bytes memory data) {
        data = abi.encodeWithSignature(
            'initialize(address,address,address,address,address,address,uint256,address)',
            _sweepersTreasury,
            _minter,
            _descriptor,
            _seeder,
            _proxyRegistry,
            _sweepersV1,
            __currentSweeperId,
            _dust
        );
    }
}