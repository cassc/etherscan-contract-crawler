pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

interface I_RICH_KIDZ_CLUB {

    function mint(
        address recipient,
		address currency,
		uint256 amount,
		uint256 permittedAmount,
		bytes32[] calldata proof
	) external payable;

    function setActivePhase(Phase phase) external;
    function setPhaseConfig(Phase phase, PhaseConfig calldata config) external;

    event PhaseChanged(Phase indexed newPhase);
    event NewRoot(Phase indexed phase, bytes32 indexed newRoot);
    event PhaseConfigured(Phase indexed phase, PhaseConfig indexed config);

    event Staked(address indexed staker, uint256 indexed tokenId, uint256 duration);
    event Unstaked(address indexed staker, uint256 indexed tokenId);
    event RewardClaimed(address indexed staker, uint256 amount);

    enum Phase {
        PAUSED,
        FF,
        WL,
        PUBLIC
    }

    struct PhaseConfig {
        uint128 maxSupply;
        uint128 mintingFee;
        bytes32 root;
    }

    enum Type {
        UNREVEALED,
        RICH_KIDS,
        SUPER_RICH,
        FU_MONEY,
        BILLIONAIRES,
        DIAMOND
    }

    struct StakingStats {
        // tokens (wei) per second
        uint72 baseRate;
        uint40 lastUpdate;
        uint104 bonus;
        uint40 end;
        uint40 minStaking;
        address staker;
    }
}