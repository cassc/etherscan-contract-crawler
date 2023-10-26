// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './Interfaces/IActivePool.sol';
import './Interfaces/ICollSurplusPool.sol';
import './Interfaces/IDefaultPool.sol';
import './Interfaces/IStabilityPool.sol';
import './Interfaces/IBorrowerOperations.sol';
import "./Dependencies/Ownable.sol";
import "./Dependencies/CheckContract.sol";
// import "./Dependencies/console.sol";
import "./Dependencies/SendCollateral.sol";

/*
 * The Active Pool holds the collateral and THUSD debt (but not THUSD tokens) for all active troves.
 *
 * When a trove is liquidated, it's collateral and THUSD debt are transferred from the Active Pool, to either the
 * Stability Pool, the Default Pool, or both, depending on the liquidation conditions.
 *
 */
contract ActivePool is Ownable, CheckContract, SendCollateral, IActivePool {

    string constant public NAME = "ActivePool";

    address public defaultPoolAddress;
    address public borrowerOperationsAddress;
    address public collateralAddress;
    address public collSurplusPoolAddress;
    address public stabilityPoolAddress;
    address public troveManagerAddress;
    uint256 internal collateral;  // deposited collateral tracker
    uint256 internal THUSDDebt;

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _stabilityPoolAddress,
        address _defaultPoolAddress,
        address _collSurplusPoolAddress,
        address _collateralAddress
    )
        external
        onlyOwner
    {
        checkContract(_borrowerOperationsAddress);
        checkContract(_troveManagerAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_collSurplusPoolAddress);
        if (_collateralAddress != address(0)) {
            checkContract(_collateralAddress);
        }

        borrowerOperationsAddress = _borrowerOperationsAddress;
        troveManagerAddress = _troveManagerAddress;
        stabilityPoolAddress = _stabilityPoolAddress;
        defaultPoolAddress = _defaultPoolAddress;
        collateralAddress = _collateralAddress;
        collSurplusPoolAddress = _collSurplusPoolAddress;

        require(
            (Ownable(_defaultPoolAddress).owner() != address(0) || 
            IDefaultPool(_defaultPoolAddress).collateralAddress() == _collateralAddress) &&
            (Ownable(_borrowerOperationsAddress).owner() != address(0) || 
            IBorrowerOperations(_borrowerOperationsAddress).collateralAddress() == _collateralAddress) &&
            (Ownable(_stabilityPoolAddress).owner() != address(0) || 
            IStabilityPool(stabilityPoolAddress).collateralAddress() == _collateralAddress) &&
            (Ownable(_collSurplusPoolAddress).owner() != address(0) || 
            ICollSurplusPool(_collSurplusPoolAddress).collateralAddress() == _collateralAddress),
            "The same collateral address must be used for the entire set of contracts"
        );

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit CollateralAddressChanged(_collateralAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);

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

    function sendCollateral(address _account, uint256 _amount) external override {
        _requireCallerIsBOorTroveMorSP();
        collateral -= _amount;
        emit ActivePoolCollateralBalanceUpdated(collateral);
        emit CollateralSent(_account, _amount);

        sendCollateral(IERC20(collateralAddress), _account, _amount);
        if (collateralAddress == address(0)) {
            return;
        }
        if (_account == defaultPoolAddress) {
            IDefaultPool(_account).updateCollateralBalance(_amount);
        } else if (_account == collSurplusPoolAddress) {
            ICollSurplusPool(_account).updateCollateralBalance(_amount);
        } else if (_account == stabilityPoolAddress) {
            IStabilityPool(_account).updateCollateralBalance(_amount);
        }
    }

    function increaseTHUSDDebt(uint256 _amount) external override {
        _requireCallerIsBOorTroveM();
        THUSDDebt += _amount;
        emit ActivePoolTHUSDDebtUpdated(THUSDDebt);
    }

    function decreaseTHUSDDebt(uint256 _amount) external override {
        _requireCallerIsBOorTroveMorSP();
        THUSDDebt -= _amount;
        emit ActivePoolTHUSDDebtUpdated(THUSDDebt);
    }

    // --- 'require' functions ---

    function _requireCallerIsBorrowerOperationsOrDefaultPool() internal view {
        require(
            msg.sender == borrowerOperationsAddress ||
            msg.sender == defaultPoolAddress,
            "ActivePool: Caller is neither BorrowerOperations nor Default Pool");
    }

    function _requireCallerIsBOorTroveMorSP() internal view {
        require(
            msg.sender == borrowerOperationsAddress ||
            msg.sender == troveManagerAddress ||
            msg.sender == stabilityPoolAddress,
            "ActivePool: Caller is neither BorrowerOperations nor TroveManager nor StabilityPool");
    }

    function _requireCallerIsBOorTroveM() internal view {
        require(
            msg.sender == borrowerOperationsAddress ||
            msg.sender == troveManagerAddress,
            "ActivePool: Caller is neither BorrowerOperations nor TroveManager");
    }

    // When ERC20 token collateral is received this function needs to be called
    function updateCollateralBalance(uint256 _amount) external override {
        _requireCallerIsBorrowerOperationsOrDefaultPool();
        require(collateralAddress != address(0), "ActivePool: ETH collateral needed, not ERC20");
        collateral += _amount;
        emit ActivePoolCollateralBalanceUpdated(collateral);
  	}

    // --- Fallback function ---

    // This executes when the contract recieves ETH
    receive() external payable {
        _requireCallerIsBorrowerOperationsOrDefaultPool();
        require(collateralAddress == address(0), "ActivePool: ERC20 collateral needed, not ETH");
        collateral += msg.value;
        emit ActivePoolCollateralBalanceUpdated(collateral);
    }
}