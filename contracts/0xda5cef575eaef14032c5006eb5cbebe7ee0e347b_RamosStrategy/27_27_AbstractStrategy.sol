pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (v2/strategies/AbstractStrategy.sol)

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { ITempleStrategy, ITreasuryReservesVault } from "contracts/interfaces/v2/strategies/ITempleStrategy.sol";
import { CommonEventsAndErrors } from "contracts/common/CommonEventsAndErrors.sol";
import { TempleElevatedAccess } from "contracts/v2/access/TempleElevatedAccess.sol";

/**
 * @dev Abstract base contract implementation of a Temple Strategy. 
 * All strategies should inherit this.
 */
abstract contract AbstractStrategy is ITempleStrategy, TempleElevatedAccess {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    string private constant API_VERSION = "1.0.0";

    /**
     * @notice A human readable name of the strategy
     */
    string public override strategyName;

    /**
     * @notice The address of the treasury reserves vault.
     */
    ITreasuryReservesVault public override treasuryReservesVault;

    /**
     * @notice The Strategy Executor may set manual updates to asset balances
     * if they cannot be reported automatically - eg a staked position with no receipt token.
     */
    AssetBalanceDelta[] internal _manualAdjustments;

    constructor(
        address _initialRescuer,
        address _initialExecutor,
        string memory _strategyName,
        address _treasuryReservesVault
    ) TempleElevatedAccess(_initialRescuer, _initialExecutor) {
        strategyName = _strategyName;
        treasuryReservesVault = ITreasuryReservesVault(_treasuryReservesVault);
    }

    /**
     * @notice Executors can set the address of the treasury reserves vault.
     */
    function setTreasuryReservesVault(address _trv) external override onlyElevatedAccess {
        if (_trv == address(0)) revert CommonEventsAndErrors.InvalidAddress();

        emit TreasuryReservesVaultSet(_trv);
        _updateTrvApprovals(address(treasuryReservesVault), _trv);

        treasuryReservesVault = ITreasuryReservesVault(_trv);

        string memory trvVersion = treasuryReservesVault.apiVersion();
        if (keccak256(abi.encodePacked(trvVersion)) != keccak256(abi.encodePacked(apiVersion())))
            revert InvalidVersion(apiVersion(), trvVersion);
    }

    /**
     * @notice A hook where strategies can optionally update approvals when the trv is updated
     */
    function _updateTrvApprovals(
        address oldTrv, 
        address newTrv
    ) internal virtual;
    
    /**
     * @dev Optionally remove max allowance for a given token from the old spender, and give to the new spender.
     */
    function _setMaxAllowance(IERC20 token, address oldSpender, address newSpender) internal {
        if (oldSpender != address(0)) {
            _setTokenAllowance(token, oldSpender, 0);
        }

        _setTokenAllowance(token, newSpender, type(uint256).max);
    }

    /**
     * @notice Track the deployed version of this contract. 
     */
    function apiVersion() public view virtual override returns (string memory) {
        return API_VERSION;
    }

    /**
     * @notice The Strategy Executor may set manual adjustments to asset balances
     * if they cannot be reported automatically - eg a staked position with no receipt token.
     */
    function setManualAdjustments(
        AssetBalanceDelta[] calldata adjustments
    ) external virtual onlyElevatedAccess {
        delete _manualAdjustments;
        uint256 _length = adjustments.length;
        for (uint256 i; i < _length; ++i) {
            _manualAdjustments.push(adjustments[i]);
        }
        emit ManualAdjustmentsSet(adjustments);
    }

    /**
     * @notice Get the set of manual adjustment deltas, set by the Strategy Executor.
     */
    function manualAdjustments() public virtual view returns (
        AssetBalanceDelta[] memory adjustments
    ) {
        return _manualAdjustments;
    }

    /**
     * @notice The latest checkpoint of each asset balance this strategy holds.
     *
     * @dev The asset value may be stale at any point in time, depending on the strategy. 
     * It may optionally implement `checkpointAssetBalances()` in order to update those balances.
     */
    function latestAssetBalances() public virtual override view returns (
        AssetBalance[] memory assetBalances
    );

    /**
     * @notice By default, we assume there is no checkpoint required for a strategy
     * In which case it would be identical to just calling `latestAssetBalances()`
     *
     * A strategy can override this if on-chain functions are required to run to force balance
     * updates first - eg checkpoint DSR
     */
    function checkpointAssetBalances() external virtual override returns (
        AssetBalance[] memory
    ) {
        return latestAssetBalances();
    }

    /**
     * @notice populate data required for shutdown - for example quote data.
     * This may/may not be required in order to do a shutdown. For example to avoid frontrunning/MEV
     * quotes to exit an LP position may need to be obtained off-chain prior to the actual shutdown.
     * Each strategy can abi encode params that it requires.
     * @dev Intentionally not a view - as some quotes require a non-view (eg Balancer)
     * The intention is for clients to call as 'static', like a view
     */
    function populateShutdownData(
        bytes calldata populateParamsData
    ) external virtual override returns (
        bytes memory shutdownParamsData
    // solhint-disable-next-line no-empty-blocks
    ) {
        // Not implemented by default.
    }

    /**
     * @notice The strategy executor can shutdown this strategy, only after Executors have
     * marked the strategy as `isShuttingDown` in the TRV.
     * This should handle all liquidations and send all funds back to the TRV, and will then call `TRV.shutdown()`
     * to apply the shutdown.
     * @dev Each strategy may require a different set of params to do the shutdown. It can abi encode/decode
     * that data off chain, or by first calling populateShutdownData()
     */
    function automatedShutdown(
        bytes calldata shutdownParamsData
    ) external virtual override onlyElevatedAccess {
        // Instruct the underlying strategy to liquidate
        _doShutdown(shutdownParamsData);

        // NB: solc warns that this is unreachable - but that's a bug and not true
        // It's a a virtual function where not all implementations revert (eg DsrBaseStrategy)
        // See: https://github.com/ethereum/solidity/issues/14359
        emit Shutdown();

        // Now mark as shutdown in the TRV.
        // This will only succeed if executors have first set the strategy to `isShuttingDown`
        treasuryReservesVault.shutdown(address(this));
    }  

    function _doShutdown(
        bytes calldata shutdownParams
    ) internal virtual;

    /**
     * @notice Executors can recover any token from the strategy.
     */
    function recoverToken(
        address token, 
        address to, 
        uint256 amount
    ) external virtual override onlyElevatedAccess {
        emit CommonEventsAndErrors.TokenRecovered(to, token, amount);
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @dev Set the allowance of any token spend from the strategy
     */
    function _setTokenAllowance(IERC20 token, address spender, uint256 amount) internal {
        if (amount == token.allowance(address(this), spender)) return;

        token.safeApprove(spender, 0);
        if (amount > 0) {
            token.safeIncreaseAllowance(spender, amount);
        }
    }

    /**
     * @notice Executors can set the allowance of any token spend from the strategy
     */
    function setTokenAllowance(IERC20 token, address spender, uint256 amount) external override onlyElevatedAccess {
        _setTokenAllowance(token, spender, amount);
        emit TokenAllowanceSet(address(token), spender, amount);
    }

    /**
     * @notice A hook which is called by the Treasury Reserves Vault when the debt ceiling
     * for this strategy is updated
     * @dev by default it's a no-op unless the strategy implements `_debtCeilingUpdated()`
     */
    function debtCeilingUpdated(IERC20 token, uint256 newDebtCeiling) external override {
        if (msg.sender != address(treasuryReservesVault)) revert CommonEventsAndErrors.InvalidAccess();
        _debtCeilingUpdated(token, newDebtCeiling);
    }

    /**
     * @notice A hook which is called by the Treasury Reserves Vault when the debt ceiling
     * for this strategy is updated
     * @dev by default it's a no-op unless the strategy implements it
     */
    // solhint-disable-next-line no-empty-blocks
    function _debtCeilingUpdated(IERC20 /*token*/, uint256 /*newDebtCeiling*/) internal virtual {}
}