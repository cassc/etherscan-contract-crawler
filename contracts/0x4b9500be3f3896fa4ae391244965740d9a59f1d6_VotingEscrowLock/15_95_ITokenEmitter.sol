// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

struct EmissionWeight {
    address[] pools;
    uint256[] weights;
    uint256 treasury;
    uint256 caller;
    uint256 protocol;
    uint256 dev;
    uint256 sum;
}

struct EmitterConfig {
    uint256 projId;
    uint256 initialEmission;
    uint256 minEmissionRatePerWeek;
    uint256 emissionCutRate;
    uint256 founderShareRate;
    uint256 startDelay;
    address treasury;
    address gov;
    address token;
    address protocolPool;
    address contributionBoard;
    address erc20BurnMiningFactory;
    address erc20StakeMiningFactory;
    address erc721StakeMiningFactory;
    address erc1155StakeMiningFactory;
    address erc1155BurnMiningFactory;
    address initialContributorShareFactory;
}

struct MiningPoolConfig {
    uint256 weight;
    bytes4 poolType;
    address baseToken;
}

struct MiningConfig {
    MiningPoolConfig[] pools;
    uint256 treasuryWeight;
    uint256 callerWeight;
}

interface ITokenEmitter {
    event Start();
    event TokenEmission(uint256 amount);
    event EmissionCutRateUpdated(uint256 rate);
    event EmissionRateUpdated(uint256 rate);
    event EmissionWeightUpdated(uint256 numberOfPools);
    event NewMiningPool(bytes4 poolTypes, address baseToken, address pool);

    function start() external;

    function distribute() external;

    function token() external view returns (address);

    function projId() external view returns (uint256);

    function poolTypes(address pool) external view returns (bytes4);

    function factories(bytes4 poolType) external view returns (address);

    function minEmissionRatePerWeek() external view returns (uint256);

    function emissionCutRate() external view returns (uint256);

    function emission() external view returns (uint256);

    function initialContributorPool() external view returns (address);

    function initialContributorShare() external view returns (address);

    function treasury() external view returns (address);

    function protocolPool() external view returns (address);

    function pools(uint256 index) external view returns (address);

    function emissionWeight() external view returns (EmissionWeight memory);

    function emissionStarted() external view returns (uint256);

    function emissionWeekNum() external view returns (uint256);

    function INITIAL_EMISSION() external view returns (uint256);

    function FOUNDER_SHARE_DENOMINATOR() external view returns (uint256);

    function EMISSION_PERIOD() external pure returns (uint256);

    function DENOMINATOR() external pure returns (uint256);
}