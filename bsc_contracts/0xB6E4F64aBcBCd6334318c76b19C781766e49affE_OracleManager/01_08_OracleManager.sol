// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IOracle.sol';
import './IOracleOffChain.sol';
import './IOracleManager.sol';
import '../utils/NameVersion.sol';
import '../utils/Admin.sol';

contract OracleManager is IOracleManager, NameVersion, Admin {

    // symbolId => oracleAddress
    mapping (bytes32 => address) _oracles;

    constructor () NameVersion('OracleManager', '3.0.3') {}

    function getOracle(bytes32 symbolId) external view returns (address) {
        return _oracles[symbolId];
    }

    function getOracle(string memory symbol) external view returns (address) {
        return _oracles[keccak256(abi.encodePacked(symbol))];
    }

    function setOracle(address oracleAddress) external _onlyAdmin_ {
        IOracle oracle = IOracle(oracleAddress);
        bytes32 symbolId = oracle.symbolId();
        _oracles[symbolId] = oracleAddress;
        emit NewOracle(symbolId, oracleAddress);
    }

    function delOracle(bytes32 symbolId) external _onlyAdmin_ {
        delete _oracles[symbolId];
        emit NewOracle(symbolId, address(0));
    }

    function delOracle(string memory symbol) external _onlyAdmin_ {
        bytes32 symbolId = keccak256(abi.encodePacked(symbol));
        delete _oracles[symbolId];
        emit NewOracle(symbolId, address(0));
    }

    function value(bytes32 symbolId) public view returns (uint256) {
        address oracle = _oracles[symbolId];
        require(oracle != address(0), 'OracleManager.value: no oracle');
        return IOracle(oracle).value();
    }

    function getValue(bytes32 symbolId) public view returns (uint256) {
        address oracle = _oracles[symbolId];
        require(oracle != address(0), 'OracleManager.getValue: no oracle');
        return IOracle(oracle).getValue();
    }

    function getValueWithJump(bytes32 symbolId) external returns (uint256 val, int256 jump) {
        address oracle = _oracles[symbolId];
        require(oracle != address(0), 'OracleManager.getValueWithHistory: no oracle');
        return IOracle(oracle).getValueWithJump();
    }

    function updateValue(
        bytes32 symbolId,
        uint256 timestamp_,
        uint256 value_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    ) public returns (bool) {
        address oracle = _oracles[symbolId];
        require(oracle != address(0), 'OracleManager.updateValue: no oracle');
        return IOracleOffChain(oracle).updateValue(timestamp_, value_, v_, r_, s_);
    }

}