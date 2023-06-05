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

contract HealthMonitor is IMonitor, AccessControl {
    IGuardedConvexStrategy internal zapper;
    GuardedConvexVault internal Vault;
    IConvexBooster internal ConvexBooster;
    ICurvePool internal CurvePool;
    uint256 internal slippageAmount = 1; // actual number is slippageAmount / decimalShiftForProportion = actual percentage slippage we allow = 1%
    bool internal initialized;

    constructor() {
        _grantRole(ADMIN_ROLE, _msgSender());
    }

    function initialize(
        address _curvePoolAddress,
        address _convexBoosterAddress,
        address _zapperAddress,
        address _vaultAddress
    ) external onlyAdmin {
        require(!initialized, "contract already initialized");

        // initialize contracts
        CurvePool = ICurvePool(_curvePoolAddress);
        ConvexBooster = IConvexBooster(_convexBoosterAddress);
        zapper = IGuardedConvexStrategy(payable(_zapperAddress));
        Vault = GuardedConvexVault(payable(_vaultAddress));

        initialized = true;
    }

    function checkIdleEth() internal view returns (bool) {
        // check if there is idle eth in the strategy zapper contract
        uint256 idleEth = address(zapper).balance;
        return idleEth > 0;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // if pool is not healthy run the upkeep
        (bool healthyAmount, bool healthyOwnership) = Vault.isPoolHealthy();
        // check if there is idle eth in the strategy zapper contract
        bool idleEth = checkIdleEth();
        bool runAdjustIn = healthyAmount && healthyOwnership && idleEth;
        bool runAdjustOut = !healthyAmount || !healthyOwnership;

        performData = abi.encode(runAdjustIn, runAdjustOut);
        return (runAdjustIn || runAdjustOut, performData);
    }

    function performUpkeep(
        bytes calldata performData
    ) external override onlyExecutive {
        // check conditions for adjust in or adjust out

        (bool runAdjustIn, bool runAdjustOut) = abi.decode(
            performData,
            (bool, bool)
        );
        // if pool is healthy and idle eth is over threshold then adjust in
        if (runAdjustIn) {
            (uint256 minLPAmountToAdjustIn, ) = Vault.previewAdjustIn();
            // apply slippage to minLPAmountToAdjustIn
            minLPAmountToAdjustIn = applySlippage(minLPAmountToAdjustIn);
            Vault.adjustIn(minLPAmountToAdjustIn);
        }
        if (runAdjustOut) {
            // if pool is not healthy then adjust out
            uint256 minOutputEthAmount = Vault.previewAdjustOut();
            //  apply slipage
            minOutputEthAmount = applySlippage(minOutputEthAmount);
            Vault.adjustOut(minOutputEthAmount);
        }
    }

    function setSlippageAmount(uint256 _slippageAmount) external onlyAdmin {
        slippageAmount = _slippageAmount;
    }

    // getters

    function getSlippageAmount()
        external
        view
        returns (uint256 _slippageAmount)
    {
        return slippageAmount;
    }

    // helper functions

    function applySlippage(uint256 amount) internal view returns (uint256) {
        return (amount * slippageAmount) / 100;
    }
}