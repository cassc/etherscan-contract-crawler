// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './Interfaces/IDefaultPool.sol';
import './Interfaces/IActivePool.sol';
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/SendCollateral.sol";

/*
 * The Default Pool holds the collateral and THUSD debt (but not THUSD tokens) from liquidations that have been redistributed
 * to active troves but not yet "applied", i.e. not yet recorded on a recipient active trove's struct.
 *
 * When a trove makes an operation that applies its pending collateral and THUSD debt, its pending collateral and THUSD debt is moved
 * from the Default Pool to the Active Pool.
 */
contract DefaultPool is Ownable, CheckContract, SendCollateral, IDefaultPool {

    string constant public NAME = "DefaultPool";

    address public activePoolAddress;
    address public collateralAddress;
    address public troveManagerAddress;
    uint256 internal collateral;  // deposited collateral tracker
    uint256 internal THUSDDebt;  // debt

    // --- Dependency setters ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _collateralAddress
    )
        external
        onlyOwner
    {
        checkContract(_troveManagerAddress);
        checkContract(_activePoolAddress);
        if (_collateralAddress != address(0)) {
            checkContract(_collateralAddress);
        }

        troveManagerAddress = _troveManagerAddress;
        activePoolAddress = _activePoolAddress;
        collateralAddress = _collateralAddress;

        require(
            (Ownable(_activePoolAddress).owner() != address(0) || 
            IActivePool(_activePoolAddress).collateralAddress() == _collateralAddress),
            "The same collateral address must be used for the entire set of contracts"
        );

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit CollateralAddressChanged(_collateralAddress);

        _renounceOwnership();
    }

    // --- Getters for public variables. Required by IPool interface ---

    /*
    * Returns the collateral state variable.
    *
    * Not necessarily equal to the the contract's raw collateral balance - collateral can be forcibly sent to contracts.
    */
    function getCollateralBalance() external view override returns (uint) {
        return collateral;
    }

    function getTHUSDDebt() external view override returns (uint) {
        return THUSDDebt;
    }

    // --- Pool functionality ---

    function sendCollateralToActivePool(uint256 _amount) external override {
        _requireCallerIsTroveManager();
        address activePool = activePoolAddress; // cache to save an SLOAD
        collateral -= _amount;
        emit DefaultPoolCollateralBalanceUpdated(collateral);
        emit CollateralSent(activePool, _amount);

        sendCollateral(IERC20(collateralAddress), activePool, _amount);
        if (collateralAddress == address(0)) {
            return;
        } 
        IActivePool(activePool).updateCollateralBalance(_amount);
    }

    function increaseTHUSDDebt(uint256 _amount) external override {
        _requireCallerIsTroveManager();
        THUSDDebt += _amount;
        emit DefaultPoolTHUSDDebtUpdated(THUSDDebt);
    }

    function decreaseTHUSDDebt(uint256 _amount) external override {
        _requireCallerIsTroveManager();
        THUSDDebt -= _amount;
        emit DefaultPoolTHUSDDebtUpdated(THUSDDebt);
    }

    // --- 'require' functions ---

    function _requireCallerIsActivePool() internal view {
        require(msg.sender == activePoolAddress, "DefaultPool: Caller is not the ActivePool");
    }

    function _requireCallerIsTroveManager() internal view {
        require(msg.sender == troveManagerAddress, "DefaultPool: Caller is not the TroveManager");
    }

    // When ERC20 token collateral is received this function needs to be called
    function updateCollateralBalance(uint256 _amount) external override {
        _requireCallerIsActivePool();
        require(collateralAddress != address(0), "DefaultPool: ETH collateral needed, not ERC20");
        collateral += _amount;
        emit DefaultPoolCollateralBalanceUpdated(collateral);
  	}

    // --- Fallback function ---

    receive() external payable {
        _requireCallerIsActivePool();
        require(collateralAddress == address(0), "DefaultPool: ERC20 collateral needed, not ETH");
        collateral += msg.value;
        emit DefaultPoolCollateralBalanceUpdated(collateral);
    }
}