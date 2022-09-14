//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import { Whitelist } from "./helpers/Whitelist.sol";
import { IGauge } from "./interfaces/IGauge.sol";
import { IGaugeController } from "./interfaces/IGaugeController.sol";
import { IPool } from "./interfaces/IPool.sol";

import "./lzApp/NonblockingLzApp.sol";

contract GaugeSnapshot is NonblockingLzApp, Whitelist {
    IGaugeController gaugeController;
    IGauge[] gauges;

    struct Snapshot {
        address gaugeAddress;
        uint256 timestamp;
        uint256 inflationRate;
        uint256 workingSupply;
        uint256 virtualPrice;
        uint256 relativeWeight;
    }

    constructor(address _lzEndpoint, address _gaugeControllerAddress) NonblockingLzApp(_lzEndpoint) {
        _addToWhitelist(msg.sender);
        gaugeController = IGaugeController(_gaugeControllerAddress);
    }

    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory payload) internal override {}

    function addToGauges(
      address[] calldata gaugesAddresses
    ) external {
        _isEligibleSender();

        for (uint i = 0; i < gaugesAddresses.length; ++i)
            gauges.push(IGauge(gaugesAddresses[i]));
    }

    function resetGauges() external {
        _isEligibleSender();

        delete gauges;
    }

    function removeLastFromGauges(
      uint256 index
    ) external {
        _isEligibleSender();

        gauges.pop();
    }

    function getGauge(uint256 i) external view returns (address) {
        return address(gauges[i]);
    }

    function getNumberOfGauges() external view returns (uint256) {
        return gauges.length;
    }

    function snap(
      bool passRelativeWeight,
      bytes memory adapter
    ) external payable {
        _isEligibleSender();

        // Save gas
        IGauge[] memory _gauges = gauges;

        Snapshot[] memory snapshots = new Snapshot[](_gauges.length);
        uint256 relativeWeight;

        for (uint i = 0; i < _gauges.length; ++i) {
            if (passRelativeWeight)
                relativeWeight = gaugeController.gauge_relative_weight(address(_gauges[i]));
            IPool pool = IPool(_gauges[i].lp_token());
            snapshots[i] = Snapshot(address(_gauges[i]), block.timestamp, _gauges[i].inflation_rate(), _gauges[i].working_supply(), pool.get_virtual_price(), relativeWeight);
        }

        _lzSend(
          110, // Arbitrum chain id
          abi.encode(snapshots), // Data to send
          payable(msg.sender), // Refund address
          address(0x0), // ZERO token payment address
          adapter// Adapter params
        );
    }

    function addToWhitelist(address _address) external onlyOwner {
        _addToWhitelist(_address);
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        _removeFromWhitelist(_address);
    }

    function updateGaugeControllerAddress(address _address) external onlyOwner {
        gaugeController = IGaugeController(_address);
    }
}