// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./variables.sol";
import "../lendingLogic/base/ILendingLogic.sol";
import "../../interfaces/IStrategyVault.sol";

/**
 * @title Basic contract
 * @author Cian
 * @notice This contract encompasses the basic logic of the strategy pool.
 * @dev In order to increase the code capacity of the contract, this contract
 * will be inherited by various modules of the strategy pool. Each module
 * contract will be deployed separately and share the same global variables.
 */
contract Basic is Variables, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    // This is used to compensate balancers for the ETH they consume while updating prices.
    uint256 public constant UPDATE_FEE_BASE = 70500;

    /**
     * @dev Ensure that this method is only called by the Vault contract.
     */
    modifier onlyVault() {
        require(vault == msg.sender, "Caller is not the vault!");
        _;
    }

    /**
     * @dev Ensure that this method is only called by authorized portfolio managers.
     */
    modifier onlyAuth() {
        require(rebalancer[msg.sender], "!Auth");
        _;
    }

    event UpdateExchangePrice(uint256 newExchangePrice, uint256 newRevenue);

    /**
     * @dev Execute the operation to allow entry into the lending protocol.
     * This method will delegatecall to the LendingLogic contract.
     * @param _protocolId The ID of the lending protocol to be approved.
     */
    function executeEnterProtocol(uint8 _protocolId) internal {
        require(!availableProtocol[_protocolId], "Already available!");
        bytes memory callBytes_ = abi.encode(_protocolId);
        executeLendingLogic(ILendingLogic.enterProtocol.selector, callBytes_);
        availableProtocol[_protocolId] = true;
    }

    /**
     * @dev Execute the operation to disable the lending protocol.
     * This method will delegatecall to the LendingLogic contract.
     * @param _protocolId The ID of the lending protocol to be disabled.
     */
    function executeExitProtocol(uint8 _protocolId) internal {
        require(availableProtocol[_protocolId], "Already unavailable!");
        bytes memory callBytes_ = abi.encode(_protocolId);
        executeLendingLogic(ILendingLogic.exitProtocol.selector, callBytes_);
        availableProtocol[_protocolId] = false;
    }

    /**
     * @dev Execute the deposit operation in the lending protocol.
     * This method will delegatecall to the LendingLogic contract.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _asset The type of asset being deposited in this transaction.
     * @param _amount The amount of asset being deposited in this transaction.
     */
    function executeDeposit(uint8 _protocolId, address _asset, uint256 _amount) internal {
        require(availableProtocol[_protocolId], "Protocol unavailable!");
        if (_amount == 0) return;
        bytes memory callBytes_ = abi.encode(_protocolId, _asset, _amount);
        executeLendingLogic(ILendingLogic.deposit.selector, callBytes_);
    }

    /**
     * @dev Execute the withdraw operation in the lending protocol.
     * This method will delegatecall to the LendingLogic contract.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _asset The type of asset being withdrawn in this transaction.
     * @param _amount The amount of asset being withdrawn in this transaction.
     */
    function executeWithdraw(uint8 _protocolId, address _asset, uint256 _amount) internal {
        require(availableProtocol[_protocolId], "Protocol unavailable!");
        if (_amount == 0) return;
        bytes memory callBytes_ = abi.encode(_protocolId, _asset, _amount);
        executeLendingLogic(ILendingLogic.withdraw.selector, callBytes_);
    }

    /**
     * @dev Execute the borrow operation in the lending protocol.
     * This method will delegatecall to the LendingLogic contract.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _asset The type of asset being borrowed in this transaction.
     * @param _amount The amount of asset being borrowed in this transaction.
     */
    function executeBorrow(uint8 _protocolId, address _asset, uint256 _amount) internal {
        require(availableProtocol[_protocolId], "Protocol unavailable!");
        if (_amount == 0) return;
        bytes memory callBytes_ = abi.encode(_protocolId, _asset, _amount);
        executeLendingLogic(ILendingLogic.borrow.selector, callBytes_);
    }

    /**
     * @dev Execute the repay operation in the lending protocol.
     * This method will delegatecall to the LendingLogic contract.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _asset The type of asset being repaid in this transaction.
     * @param _amount The amount of asset being repaid in this transaction.
     */
    function executeRepay(uint8 _protocolId, address _asset, uint256 _amount) internal {
        require(availableProtocol[_protocolId], "Protocol unavailable!");
        if (_amount == 0) return;
        bytes memory callBytes_ = abi.encode(_protocolId, _asset, _amount);
        executeLendingLogic(ILendingLogic.repay.selector, callBytes_);
    }

    /**
     * @dev This method delegatecalls the method specified by the function signature to the lending logic.
     * @param _selector The function signature of the LendingLogic contract.
     * @param _callBytes The function parameter bytes of the LendingLogic contract.
     */
    function executeLendingLogic(bytes4 _selector, bytes memory _callBytes) internal {
        bytes memory callBytes = abi.encodePacked(_selector, _callBytes);
        (bool success, bytes memory returnData) = lendingLogic.delegatecall(callBytes);
        require(success, string(returnData));
    }

    /**
     * @dev The reallocation operation will consume a significant amount of ETH gas, which will
     * be paid by the entire position using STETH.
     */
    function collectGasCompensation(uint256 _gasBefore, uint256 _overestimation) internal {
        uint256 gasUsed_ = (_gasBefore - gasleft() + _overestimation) * tx.gasprice;
        // IERC20(STETH_ADDR).safeTransfer(feeReceiver, gasUsed_);
    }

    /**
     * @notice To prevent the contract from being attacked, the exchange rate of the contract
     * is intentionally made non-modifiable by unauthorized addresses. Users may incur some
     * price losses, but under normal circumstances, these losses are negligible and can be
     * covered by profits in a very short period of time.
     * @dev Update the exchange rate between the share token and the core asset stETH.
     * If the real price has increased, record the profit portion proportionally.
     * @return newExchangePrice The new exercise price.
     * @return newRevenue The new realized profit.
     */
    function updateExchangePrice() public onlyAuth returns (uint256 newExchangePrice, uint256 newRevenue) {
        uint256 gasBefore_ = gasleft();
        uint256 totalSupply_ = IStrategyVault(vault).totalSupply();
        if (totalSupply_ == 0) {
            return (exchangePrice, revenue);
        }
        uint256 currentNetAssets_ = getNetAssets();
        newExchangePrice = currentNetAssets_ * 1e18 / totalSupply_;
        if (newExchangePrice > revenueExchangePrice) {
            if (revenueExchangePrice == 0) {
                revenueExchangePrice = newExchangePrice;
                exchangePrice = newExchangePrice;
                return (exchangePrice, revenue);
            }
            uint256 newProfit_ = currentNetAssets_ - ((exchangePrice * totalSupply_) / 1e18);
            newRevenue = (newProfit_ * revenueRate) / 1e4;
            revenue += newRevenue;
            exchangePrice = ((currentNetAssets_ - newRevenue) * 1e18) / totalSupply_;
            revenueExchangePrice = exchangePrice;
        } else {
            exchangePrice = newExchangePrice;
        }

        emit UpdateExchangePrice(newExchangePrice, newRevenue);
        collectGasCompensation(gasBefore_, UPDATE_FEE_BASE);
    }

    /**
     * @dev Retrieve the maximum amount of ETH that this strategy pool address can still
     * borrow in the lending protocol.
     * @param _protocolId The index of the lending protocol within this contract.
     * @return availableBorrowsETH The maximum amount of ETH that can still be borrowed.
     */
    function getAvailableBorrowsETH(uint8 _protocolId) public view returns (uint256) {
        return ILendingLogic(lendingLogic).getAvailableBorrowsETH(_protocolId, address(this));
    }

    /**
     * @dev Retrieve the maximum amount of stETH that this strategy pool address can still
     * withdraw in the lending protocol.
     * @param _protocolId The index of the lending protocol within this contract.
     * @return maxWithdrawsStETH The maximum amount of stETH that can still be withdrawn.
     */
    function getAvailableWithdrawsStETH(uint8 _protocolId) public view returns (uint256) {
        return ILendingLogic(lendingLogic).getAvailableWithdrawsStETH(_protocolId, address(this));
    }

    /**
     * @dev Retrieve the collateral and debt quantities of this strategy pool in the lending protocol.
     * @param _protocolId The index of the lending protocol within this contract.
     * @return stEthAmount The amount of stETH collateral.
     * @return debtEthAmount The amount of ETH debt.
     */
    function getProtocolAccountData(uint8 _protocolId)
        public
        view
        returns (uint256 stEthAmount, uint256 debtEthAmount)
    {
        return ILendingLogic(lendingLogic).getProtocolAccountData(_protocolId, address(this));
    }

    /**
     * @dev Retrieve the amount of net assets in the protocol.
     * @param _protocolId The index of the lending protocol within this contract.
     * @return net The amount of net assets.
     */
    function getProtocolNetAssets(uint8 _protocolId) public view returns (uint256 net) {
        (uint256 stEthAmount, uint256 debtEthAmount) = getProtocolAccountData(_protocolId);
        net = stEthAmount - debtEthAmount;
    }

    /**
     * @dev Retrieve the ratio of debt to collateral, considering stETH and ETH as assets with a 1:1 ratio.
     * @param _protocolId The index of the lending protocol within this contract.
     * @return ratio The debt collateralization ratio, where 1e18 represents 100%.
     */
    function getProtocolRatio(uint8 _protocolId) public view returns (uint256 ratio) {
        (uint256 stEthAmount, uint256 debtEthAmount) = getProtocolAccountData(_protocolId);
        ratio = debtEthAmount * 1e18 / stEthAmount;
    }

    /**
     * @dev Retrieve the debt collateralization ratio of this strategy pool in the lending protocol,
     * using the oracle associated with that lending protocol.
     * @param _protocolId The index of the lending protocol within this contract.
     * @return collateralRatio The debt collateralization ratio, where 1e18 represents 100%.
     * @return isOK This bool indicates whether the safe collateralization ratio has been exceeded.
     * If true, it indicates the need for a deleveraging operation.
     */
    function getProtocolCollateralRatio(uint8 _protocolId) public view returns (uint256 collateralRatio, bool isOK) {
        collateralRatio = ILendingLogic(lendingLogic).getProtocolCollateralRatio(_protocolId, address(this));
        isOK = safeProtocolRatio[_protocolId] + PERMISSIBLE_LIMIT > collateralRatio ? true : false;
    }

    /**
     * @dev Retrieve the amount of WETH required for the flash loan in this operation.
     * When increasing leverage, it is also possible to deposit stETH into the lending
     * protocol simultaneously. When decreasing leverage, it is also possible to withdraw
     * stETH from the lending protocol simultaneously.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _isDepositOrWithdraw Whether an additional deposit of stETH is required.
     * @param _depositOrWithdraw The amount of stETH to be deposited or withdrawn.
     * @return isLeverage Returning "true" indicates the need to increase leverage, while returning
     * "false" indicates the need to decrease leverage.
     * @return amount The amount of flash loan required for this transaction.
     */
    function getProtocolLeverageAmount(uint8 _protocolId, bool _isDepositOrWithdraw, uint256 _depositOrWithdraw)
        public
        view
        returns (bool isLeverage, uint256 amount)
    {
        return ILendingLogic(lendingLogic).getProtocolLeverageAmount(
            _protocolId, address(this), _isDepositOrWithdraw, _depositOrWithdraw, safeProtocolRatio[_protocolId]
        );
    }

    /**
     * @dev Retrieve the amount of assets in all lending protocols involved in this contract for the strategy pool.
     * @return totalAssets The total amount of collateral.
     * @return totalDebt The total amount of debt.
     * @return netAssets The total amount of net assets.
     * @return aggregatedRatio The aggregate collateral-to-debt ratio.
     */
    function getNetAssetsInfo() public view returns (uint256, uint256, uint256, uint256) {
        return ILendingLogic(lendingLogic).getNetAssetsInfo(address(this));
    }

    /**
     * @dev Retrieve the amount of assets in all lending protocols involved in this contract for the strategy pool.
     * @return netAssets The total amount of net assets.
     */
    function getNetAssets() public view returns (uint256) {
        (,, uint256 currentNetAssets_,) = getNetAssetsInfo();
        return currentNetAssets_ + IERC20(STETH_ADDR).balanceOf(address(this)) - revenue;
    }

    /**
     * @dev Retrieve the current real exchange rate and the new profit amount.
     * @return newExchangePrice The current real exchange rate.
     * @return newRevenue If there is a profit, it represents the amount of profit; otherwise, it is 0.
     */
    function getCurrentExchangePrice() public view returns (uint256 newExchangePrice, uint256 newRevenue) {
        uint256 totalSupply_ = IStrategyVault(vault).totalSupply();
        if (totalSupply_ == 0) {
            return (exchangePrice, revenue);
        }
        uint256 currentNetAssets_ = getNetAssets();
        newExchangePrice = (currentNetAssets_ * 1e18) / totalSupply_;
        if (newExchangePrice > revenueExchangePrice) {
            uint256 newProfit_ = currentNetAssets_ - ((exchangePrice * totalSupply_) / 1e18);
            newRevenue = (newProfit_ * revenueRate) / 1e4;
        }
    }

    /**
     * @dev Used to check the overall health status of the strategy pool after
     * an operation to prevent the strategy pool from being in a risky position.
     */
    function checkAggregatedRatio() internal view {
        (,,, uint256 currentAggregatedRatio_) = getNetAssetsInfo();
        require(currentAggregatedRatio_ <= safeAggregatedRatio, "AggregatedRatio out of range");
    }

    /**
     * @dev Used to check the health status of the strategy pool in a specific lending protocol
     * after an operation to prevent the strategy pool from being in a risky position.
     */
    function checkProtocolRatio(uint8 _protocolId) internal view {
        (, bool isOK_) = getProtocolCollateralRatio(_protocolId);
        require(isOK_, "Ratio out of range");
    }

    /**
     * @dev Retrieve the version number of the strategy pool.
     */
    function getVersion() public pure returns (string memory) {
        return "v0.0.2";
    }
}