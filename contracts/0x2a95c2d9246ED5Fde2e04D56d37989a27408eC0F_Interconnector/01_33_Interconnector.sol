// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./libraries/ProtocolLinkage.sol";
import "./interfaces/IInterconnector.sol";
import "./interfaces/ISupervisor.sol";
import "./interfaces/IMinterestNFT.sol";
import "./interfaces/IWeightAggregator.sol";

/**
 * Immutable storage-less contract with collection of protocol contracts
 */
contract Interconnector is IInterconnector, LinkageRoot {
    // Leaf contracts block
    ISupervisor public immutable supervisor;
    IRewardsHub public immutable rewardsHub;
    IBuyback public immutable buyback;
    IEmissionBooster public immutable emissionBooster;
    IBDSystem public immutable bdSystem;

    IMnt public immutable mnt;
    IMinterestNFT public immutable minterestNFT;
    ILiquidation public immutable liquidation;

    // Utility contracts block
    IPriceOracle public immutable oracle;
    IVesting public immutable vesting;
    IWhitelist public immutable whitelist;
    IWeightAggregator public immutable weightAggregator;

    constructor(address owner_, address[] memory contractAddresses) LinkageRoot(owner_) {
        supervisor = ISupervisor(contractAddresses[0]);
        rewardsHub = IRewardsHub(contractAddresses[1]);
        buyback = IBuyback(contractAddresses[2]);
        emissionBooster = IEmissionBooster(contractAddresses[3]);
        bdSystem = IBDSystem(contractAddresses[4]);

        mnt = IMnt(contractAddresses[5]);
        minterestNFT = IMinterestNFT(contractAddresses[6]);
        liquidation = ILiquidation(contractAddresses[7]);

        oracle = IPriceOracle(contractAddresses[8]);
        vesting = IVesting(contractAddresses[9]);
        whitelist = IWhitelist(contractAddresses[10]);
        weightAggregator = IWeightAggregator(contractAddresses[11]);
    }

    /// @notice Update interconnector version for all leaf contracts
    /// @dev Should include only leaf contracts
    function interconnectInternal() internal override {
        mnt.switchLinkageRoot(_self);
        supervisor.switchLinkageRoot(_self);
        rewardsHub.switchLinkageRoot(_self);
        buyback.switchLinkageRoot(_self);
        liquidation.switchLinkageRoot(_self);
        emissionBooster.switchLinkageRoot(_self);
        minterestNFT.switchLinkageRoot(_self);
        bdSystem.switchLinkageRoot(_self);
    }
}