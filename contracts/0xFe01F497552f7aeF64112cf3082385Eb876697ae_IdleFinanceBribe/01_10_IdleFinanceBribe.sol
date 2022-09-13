// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {BribeBase} from "./BribeBase.sol";

contract IdleFinanceBribe is BribeBase {
    address[] public gauges;
    mapping(address => uint256) public indexOfGauge;

    constructor(address _BRIBE_VAULT)
        BribeBase(_BRIBE_VAULT, "IDLE_FINANCE")
    {}

    /**
        @notice Set a single proposal for a liquidity gauge
        @param  gauge     address  Gauge address
        @param  deadline  uint256  Proposal deadline
     */
    function setGaugeProposal(address gauge, uint256 deadline)
        public
        onlyAuthorized
    {
        require(gauge != address(0), "Invalid gauge");

        // Add new gauge to list and track index
        if (
            gauges.length == 0 ||
            (indexOfGauge[gauge] == 0 && gauges[0] != gauge)
        ) {
            gauges.push(gauge);
            indexOfGauge[gauge] = gauges.length - 1;
        }

        _setProposal(keccak256(abi.encodePacked(gauge)), deadline);
    }

    /**
        @notice Set multiple proposals for many gauges
        @param  gauges_    address[]  Gauge addresses
        @param  deadlines  uint256[]  Proposal deadlines
     */
    function setGaugeProposals(
        address[] calldata gauges_,
        uint256[] calldata deadlines
    ) external onlyAuthorized {
        uint256 gaugeLen = gauges_.length;
        require(gaugeLen != 0, "Invalid gauges_");
        require(gaugeLen == deadlines.length, "Arrays length mismatch");

        for (uint256 i; i < gaugeLen; ++i) {
            setGaugeProposal(gauges_[i], deadlines[i]);
        }
    }

    /**
        @notice Get list of gauges
     */
    function getGauges() external view returns (address[] memory) {
        return gauges;
    }
}