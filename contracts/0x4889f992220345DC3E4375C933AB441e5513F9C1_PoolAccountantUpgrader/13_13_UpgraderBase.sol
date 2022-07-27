// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../dependencies/openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "../interfaces/multicall/IMulticall.sol";

abstract contract UpgraderBase is ProxyAdmin {
    address public multicall;

    constructor(address _multicall) {
        multicall = _multicall;
    }

    function safeUpgrade(address _proxy, address _implementation) public onlyOwner {
        bytes[] memory calls = _calls();
        bytes[] memory beforeResults = _aggregate(_proxy, calls);

        TransparentUpgradeableProxy(payable(_proxy)).upgradeTo(_implementation);

        bytes[] memory afterResults = _aggregate(_proxy, calls);
        _checkResults(beforeResults, afterResults);
    }

    function safeUpgradeToAndCall(
        address _proxy,
        address _implementation,
        bytes memory _data
    ) public payable onlyOwner {
        bytes[] memory calls = _calls();
        bytes[] memory beforeResults = _aggregate(_proxy, calls);

        TransparentUpgradeableProxy(payable(_proxy)).upgradeToAndCall{value: msg.value}(_implementation, _data);

        bytes[] memory afterResults = _aggregate(_proxy, calls);
        _checkResults(beforeResults, afterResults);
    }

    function _aggregate(address _proxy, bytes[] memory _callDatas) internal returns (bytes[] memory results) {
        IMulticall.Call[] memory calls = new IMulticall.Call[](_callDatas.length);
        for (uint256 i = 0; i < _callDatas.length; i++) {
            calls[i].target = _proxy;
            calls[i].callData = _callDatas[i];
        }
        (, results) = IMulticall(multicall).aggregate(calls);
    }

    function _calls() internal virtual returns (bytes[] memory calls);

    function _checkResults(bytes[] memory _beforeResult, bytes[] memory _afterResults) internal virtual;
}