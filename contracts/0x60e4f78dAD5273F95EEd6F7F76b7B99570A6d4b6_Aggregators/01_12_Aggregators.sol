// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../Marketplace/CollateralWrapper.sol";
import "../Security/OnlyAuthorized.sol";

contract Aggregators is CollateralWrapper, OnlyAuthorized {
    address[] private aggregators;
    mapping(address => uint256) private aggregatorsIndex;

    event NewAggregator(address indexed aggregator);
    event RemovedAggregator(address indexed aggregator);

    constructor(
        address _collateral,
        address _signatureCollateral,
        address[] memory initialsWallets
    ) CollateralWrapper(_collateral, _signatureCollateral) {
        for (uint i = 0; i < initialsWallets.length; i++) {
            aggregators.push(initialsWallets[i]);
            aggregatorsIndex[initialsWallets[i]] = aggregators.length;
            emit NewAggregator(initialsWallets[i]);
        }
    }

    function add(address addr) external onlyOwner {
        require(addr != address(0), "addr cannot be zero");
        require(aggregatorsIndex[addr] == 0, "The address is already assigned");

        aggregators.push(addr);
        aggregatorsIndex[addr] = aggregators.length;
        emit NewAggregator(addr);
    }

    function remove(address addr) external onlyOwner {
        require(aggregators.length > 0, "There is no registered aggregator");
        require(aggregatorsIndex[addr] > 0, "Aggregator not found");
        if (aggregators.length == 1) return _remove(addr);
        if (aggregatorsIndex[addr] == aggregators.length) return _remove(addr);
        _swap(addr);
    }

    function _remove(address addr) private {
        aggregators.pop();
        aggregatorsIndex[addr] = 0;
        emit RemovedAggregator(addr);
    }

    function _swap(address addr) private {
        uint256 index = aggregatorsIndex[addr];
        address swapAddress = aggregators[aggregators.length - 1];

        aggregators[index - 1] = swapAddress;
        aggregators.pop();
        aggregatorsIndex[addr] = 0;
        aggregatorsIndex[swapAddress] = index;

        emit RemovedAggregator(addr);
    }

    function count() external view onlyAuthorized returns (uint256) {
        return aggregators.length;
    }

    function getByIndex(uint256 i)
        external
        view
        onlyAuthorized
        returns (address)
    {
        return aggregators[i];
    }

    function getAll() external view returns (address[] memory) {
        return aggregators;
    }

    function distribute() external onlyAuthorized {
        uint256 balanceToDistribute = _collateralBalanceOf(address(this)) /
            aggregators.length;

        require(balanceToDistribute > 0, "There are not enough funds");

        for (uint i = 0; i < aggregators.length; i++) {
            _collateralTransfer(aggregators[i], balanceToDistribute);
        }
    }
}