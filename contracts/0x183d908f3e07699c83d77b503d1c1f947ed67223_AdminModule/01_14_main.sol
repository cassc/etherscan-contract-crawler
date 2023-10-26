// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./events.sol";

/**
 * @title AdminModule contract
 * @author Cian
 * @dev This module includes various functionalities for managing permissions,
 * appointments, and parameter adjustments. It allows for the management and adjustment
 * of permissions and parameters within the strategy pool, includingthe ability
 * to appoint and dismiss administrators, adjust settings, and modify parameters as needed.
 */
contract AdminModule is Events {
    using SafeERC20 for IERC20;

    /**
     * @dev Initialize various parameters of the strategy pool.
     * @param _revenueRate The percentage of performance fees collected.
     * @param _safeAggregatedRatio The safe aggregate collateralization ratio.
     * @param _safeProtocolRatio The safe target collateralization ratio corresponding to the lending protocol.
     * @param _rebalancers The whitelist addresses allowed to perform position adjustments.
     * @param _flashloanHelper The address of the intermediary contract used for executing flash loan operations.
     * @param _lendingLogic The logic contract for executing lending operations.
     * @param _feeReceiver The address of the recipient for performance fees.
     */
    function initialize(
        uint256 _revenueRate,
        uint256 _safeAggregatedRatio,
        uint256[] memory _safeProtocolRatio,
        address[] memory _rebalancers,
        address _flashloanHelper,
        address _lendingLogic,
        address _feeReceiver
    ) public initializer {
        __Ownable_init();
        require(
            _safeAggregatedRatio >= MIN_SAFE_AGGREGATED_RATIO && _safeAggregatedRatio < MAX_SAFE_AGGREGATED_RATIO,
            "Invalid aggregated Ratio!"
        );
        safeAggregatedRatio = _safeAggregatedRatio;
        require(_revenueRate >= 10 && _revenueRate <= 2000, "revenueRate error!");
        revenueRate = _revenueRate;
        if (_rebalancers.length != 0) {
            for (uint256 i = 0; i < _rebalancers.length; i++) {
                _addRebalancer(_rebalancers[i]);
            }
        }
        if (_safeProtocolRatio.length != 0) {
            for (uint8 i = 0; i < _safeProtocolRatio.length; i++) {
                safeProtocolRatio[i] = _safeProtocolRatio[i];
            }
        }
        flashloanHelper = _flashloanHelper;
        lendingLogic = _lendingLogic;
        feeReceiver = _feeReceiver;
        exchangePrice = 1e18;
        IERC20(STETH_ADDR).safeIncreaseAllowance(WSTETH_ADDR, type(uint256).max);

        executeEnterProtocol(uint8(ILendingLogic.PROTOCOL.PROTOCOL_AAVEV2));
        executeEnterProtocol(uint8(ILendingLogic.PROTOCOL.PROTOCOL_AAVEV3));
        executeEnterProtocol(uint8(ILendingLogic.PROTOCOL.PROTOCOL_COMPOUNDV3));
        executeEnterProtocol(uint8(ILendingLogic.PROTOCOL.PROTOCOL_MORPHO_AAVEV2));
    }

    /**
     * @dev Allow entry into this lending protocol.
     * @param _protocolId The index of the lending protocol within this contract.
     */
    function enterProtocol(uint8 _protocolId) external onlyOwner {
        executeEnterProtocol(_protocolId);

        emit EnterProtocol(_protocolId);
    }

    /**
     * @dev Disallow entry into this lending protocol.
     * @param _protocolId The index of the lending protocol within this contract.
     */
    function exitProtocol(uint8 _protocolId) external onlyOwner {
        executeExitProtocol(_protocolId);

        emit ExitProtocol(_protocolId);
    }

    /**
     * @dev Set the address of the contract used to record user equity.
     * @param _vault The address of the contract used to record user equity.
     */
    function setVault(address _vault) external onlyOwner {
        require(vault == address(0) && _vault != address(0), "Illegal operation!");
        vault = _vault;

        emit SetVault(_vault);
    }

    /**
     * @dev Set the new address for the recipient of performance fees.
     * @param _newFeeReceiver The new address for the recipient of performance fees.
     */
    function updateFeeReceiver(address _newFeeReceiver) public onlyOwner {
        collectRevenue();
        emit UpdateFeeReceiver(feeReceiver, _newFeeReceiver);
        feeReceiver = _newFeeReceiver;
    }

    /**
     * @dev Add a new address to the position adjustment whitelist.
     * @param _newRebalancer The new address to be added.
     */
    function _addRebalancer(address _newRebalancer) internal {
        require(!rebalancer[_newRebalancer], "Already exists!");
        rebalancer[_newRebalancer] = true;

        emit AddRebalancer(_newRebalancer);
    }

    /**
     * @dev Remove an address from the position adjustment whitelist.
     * @param _delRebalancer The address to be removed.
     */
    function _removeRebalancer(address _delRebalancer) internal {
        require(rebalancer[_delRebalancer], "Does not exist!");
        rebalancer[_delRebalancer] = false;

        emit RemoveRebalancer(_delRebalancer);
    }

    /**
     * @dev Update the logic for interacting with the lending protocol.
     * @param _newLendingLogic The new logic address.
     */
    function updateLendingLogic(address _newLendingLogic) external onlyOwner {
        require(_newLendingLogic != address(0), "Wrong lendingLogic!");
        emit UpdateLendingLogic(lendingLogic, _newLendingLogic);
        lendingLogic = _newLendingLogic;
    }

    /**
     * @dev Update the address of the intermediary contract used for flash loan operations.
     * @param _newFlashloanHelper The new contract address.
     */
    function updateFlashloanHelper(address _newFlashloanHelper) external onlyOwner {
        require(_newFlashloanHelper != address(0), "Wrong flashloanHelper!");
        emit UpdateFlashloanHelper(flashloanHelper, _newFlashloanHelper);
        flashloanHelper = _newFlashloanHelper;
    }

    /**
     * @dev Update the position adjustment whitelist.
     * @param _rebalancers The addresses to be updated.
     * @param _isAllowed Allow or disable the address.
     */
    function updateRebalancer(address[] calldata _rebalancers, bool[] calldata _isAllowed) external onlyOwner {
        require(_rebalancers.length == _isAllowed.length && _isAllowed.length != 0, "Mismatched length!");
        for (uint256 i = 0; i < _rebalancers.length; i++) {
            _isAllowed[i] ? _addRebalancer(_rebalancers[i]) : _removeRebalancer(_rebalancers[i]);
        }

        emit UpdateRebalancer(_rebalancers, _isAllowed);
    }

    /**
     * @dev Updating the performance fee ratio.
     * @param _newRevenueRate The new performance fee ratio. 1000 = 20%
     */
    function updateRevenueRate(uint256 _newRevenueRate) external onlyOwner {
        require(_newRevenueRate >= 10 && _newRevenueRate <= 2000, "revenueRate error!");
        emit UpdateRevenueRate(revenueRate, _newRevenueRate);
        revenueRate = _newRevenueRate;
    }

    /**
     * @dev Update the safe line for aggregation.
     * @param _newSafeAggregatedRatio The safe line for aggregation.
     */
    function updateSafeAggregatedRatio(uint256 _newSafeAggregatedRatio) external onlyOwner {
        require(
            _newSafeAggregatedRatio >= MIN_SAFE_AGGREGATED_RATIO && _newSafeAggregatedRatio < MAX_SAFE_AGGREGATED_RATIO,
            "Invalid aggregated Ratio!"
        );
        emit UpdateSafeAggregatedRatio(safeAggregatedRatio, _newSafeAggregatedRatio);
        safeAggregatedRatio = _newSafeAggregatedRatio;
    }

    /**
     * @dev Update the target collateralization ratio for the lending protocol.
     * @param _protocolId The index of the lending protocol within this contract.
     * @param _safeProtocolRatio The safe target collateralization ratio corresponding to the lending protocol.
     */
    function updateSafeProtocolRatio(uint8[] calldata _protocolId, uint256[] calldata _safeProtocolRatio)
        external
        onlyOwner
    {
        require(_protocolId.length == _safeProtocolRatio.length && _protocolId.length != 0, "Mismatched length!");
        for (uint8 i = 0; i < _protocolId.length; i++) {
            safeProtocolRatio[_protocolId[i]] = _safeProtocolRatio[i];
        }

        emit UpdateSafeProtocolRatio(_protocolId, _safeProtocolRatio);
    }

    /**
     * @dev Collect performance fees to the recipient address.
     */
    function collectRevenue() public {
        require(msg.sender == feeReceiver || msg.sender == owner(), "feeReceiver: Wut?");
        IERC20(STETH_ADDR).safeTransfer(feeReceiver, revenue);
        emit CollectRevenue(revenue);
        revenue = 0;
    }
}