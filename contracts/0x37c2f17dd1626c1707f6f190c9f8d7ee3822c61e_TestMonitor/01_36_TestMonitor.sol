// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IMonitor} from "./interfaces/IMonitor.sol";
import {IGuardedConvexStrategy} from "./interfaces/IGuardedConvexStrategy.sol";
import {GuardedConvexVault} from "./GuardedConvexVault.sol";
import {IConvexBooster} from "./interfaces/IConvexBooster.sol";
import {ICurvePool} from "./interfaces/ICurvePool.sol";
import {ERC20} from "./libs/ERC20.sol";
import {BasicAccessController as AccessControl} from "./AccessControl.sol";
import "hardhat/console.sol";

contract TestMonitor is IMonitor, AccessControl {
    IGuardedConvexStrategy internal zapper;
    GuardedConvexVault internal Vault;
    bool internal initialized;
    bool public shouldRun = true;
    event ChecksHappened(
        bool healthyAmount,
        bool healthyOwnership,
        bool idleEth,
        bool runAdjustIn,
        bool runAdjustOut,
        address sender
    );

    constructor() {
        _grantRole(ADMIN_ROLE, _msgSender());
    }

    function initialize(address _vaultAddress) external onlyAdmin {
        require(!initialized, "contract already initialized");
        Vault = GuardedConvexVault(payable(_vaultAddress));

        initialized = true;
    }

    function checkIdleEth() internal view returns (bool) {
        // check if there is idle eth in the strategy zapper contract
        uint256 idleEth = address(zapper).balance;
        return idleEth > 0;
    }

    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData) {
        // if pool is not healthy run the upkeep
        (bool healthyAmount, bool healthyOwnership) = Vault.isPoolHealthy();
        // check if there is idle eth in the strategy zapper contract
        bool idleEth = checkIdleEth();
        bool runAdjustIn = healthyAmount && healthyOwnership && idleEth;
        bool runAdjustOut = !healthyAmount || !healthyOwnership;
        performData = abi.encode(
            runAdjustIn,
            runAdjustOut,
            healthyAmount,
            healthyOwnership,
            idleEth
        );
        return (runAdjustIn || runAdjustOut, performData);
    }

    function performUpkeep(
        bytes calldata performData
    ) external override onlyExecutive {
        // check conditions for adjust in or adjust out
        (
            bool runAdjustIn,
            bool runAdjustOut,
            bool healthyAmount,
            bool healthyOwnership,
            bool idleEth
        ) = abi.decode(performData, (bool, bool, bool, bool, bool));
        // if pool is healthy and idle eth is over threshold then adjust in
        emit ChecksHappened(
            healthyAmount,
            healthyOwnership,
            idleEth,
            runAdjustIn,
            runAdjustOut,
            _msgSender()
        );
        shouldRun = false;
    }
}