// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

abstract contract System {

    bool public alreadyInit;

    // TODO CHANGE GENESIS ADDRESS
    address public constant POSITION_ADMIN_ADDR = 0x0000000000000000000000000000000000001001;
    address public constant GOVERNANCE_HUB_ADDR = 0x0000000000000000000000000000000000001002;
    address public constant SYSTEM_REWARD_ADDR = 0x0000000000000000000000000000000000001003;
    address public constant RELAYER_HUB_ADDR = 0x0000000000000000000000000000000000001004;
    address public constant RELAYER_INCENTIVE_ADDR = 0x0000000000000000000000000000000000001005;

    // NOTE: only init those two address on Posi chain
    address public constant TOKEN_HUB_ADDR = 0x0000000000000000000000000000000000001006;
    address public constant CROSS_CHAIN_ADDR = 0x0000000000000000000000000000000000001007;

    modifier onlyPositionAdmin() {
        require(
            msg.sender == POSITION_ADMIN_ADDR,
            "Only Position Admin Address"
        );
        _;
    }

    modifier onlyGovernmentHub() {
        require(
            msg.sender == GOVERNANCE_HUB_ADDR,
            "Only Governance Hub Contract"
        );
        _;
    }

    modifier onlySystemReward() {
        require(
            msg.sender == SYSTEM_REWARD_ADDR,
            "Only System Reward Contract"
        );
        _;
    }

    modifier onlyRelayerHub() {
        require(
            msg.sender == RELAYER_HUB_ADDR,
            "Only Relayer Hub Contract"
        );
        _;
    }

    modifier onlyRelayerIncentive() {
        require(
            msg.sender == RELAYER_INCENTIVE_ADDR,
            "Only Relayer Incentive Contract"
        );
        _;
    }

    modifier onlyTokenHub() {
        require(
            msg.sender == TOKEN_HUB_ADDR,
            "Only Token Hub Contract"
        );
        _;
    }

    modifier onlyCrosschain() {
        require(
            msg.sender == CROSS_CHAIN_ADDR,
            "Only Cross-chain Contract"
        );
        _;
    }


}