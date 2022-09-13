// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "../utils/AddressUtils.sol";

contract StratManager is Ownable, Pausable {
    /**
     * @dev Company Contracts:
     * {strategist} - Address of the strategy author/deployer where strategist fee will go.
     * {vault} - Address of the vault that controls the strategy's funds.
     * {unirouter} - Address of exchange to execute swaps.
     */
    address public strategist;
    address public unirouter;
    address public vault;
    address public companyFeeRecipient;

    event StratUpdate(address indexed updater, string updateType, address newValue);
    event OwnerOperation(address indexed invoker, string method);

    /**
     * @dev Initializes the base strategy.
     * @param _strategist address where strategist fees go.
     * @param _unirouter router to use for swaps
     * @param _vault address of parent vault.
     * @param _companyFeeRecipient address where to send Company's fees.
     */
    constructor(
        address _strategist,
        address _unirouter,
        address _vault,
        address _companyFeeRecipient
    ) public {
        // strategist can be empty
        strategist = _strategist;
        unirouter = AddressUtils.validateOneAndReturn(_unirouter);
        vault = AddressUtils.validateOneAndReturn(_vault);
        companyFeeRecipient = AddressUtils.validateOneAndReturn(_companyFeeRecipient);
    }

    /**
     * @dev Updates address where strategist fee earnings will go.
     * @param _strategist new strategist address.
     */
    function setStrategist(address _strategist) external onlyOwner {
        strategist = _strategist;

        emit StratUpdate(msg.sender, "Strategist", _strategist);
        emit OwnerOperation(msg.sender, "StratManager.setStrategist");
    }

    /**
     * @dev Updates router that will be used for swaps.
     * @param _unirouter new unirouter address.
     */
    function setUnirouter(address _unirouter) external onlyOwner {
        unirouter = _unirouter;

        emit StratUpdate(msg.sender, "Inirouter", _unirouter);
        emit OwnerOperation(msg.sender, "StratManager.setUnirouter");
    }

    /**
     * @dev Updates company fee recipient.
     * @param _companyFeeRecipient new company fee recipient address.
     */
    function setCompanyFeeRecipient(address _companyFeeRecipient) external onlyOwner {
        companyFeeRecipient = _companyFeeRecipient;

        emit StratUpdate(msg.sender, "CompanyFeeRecipient", _companyFeeRecipient);
        emit OwnerOperation(msg.sender, "StratManager.setCompanyFeeRecipient");
    }

    /**
     * @dev Function to synchronize balances before new user deposit.
     * Can be overridden in the strategy.
     */
    function beforeDeposit() external virtual {}
}