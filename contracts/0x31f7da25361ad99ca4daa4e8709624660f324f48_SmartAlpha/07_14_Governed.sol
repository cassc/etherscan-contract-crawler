// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.6;

import "./interfaces/IPriceOracle.sol";
import "./interfaces/ISeniorRateModel.sol";
import "./interfaces/IAccountingModel.sol";
import "./SmartAlphaEvents.sol";

/// @notice Governance functions for SmartAlpha
/// @dev It defines a DAO and a Guardian
/// From a privilege perspective, the DAO is also considered Guardian, allowing it to execute any action
/// that the Guardian can do.
abstract contract Governed is SmartAlphaEvents {
    address public dao;
    address public guardian;

    bool public paused;

    IPriceOracle public priceOracle;
    ISeniorRateModel public seniorRateModel;
    IAccountingModel public accountingModel;

    uint256 public constant MAX_FEES_PERCENTAGE = 5 * 10 ** 16; // 5% * 10^18
    address public feesOwner;
    uint256 public feesPercentage;

    constructor (address _dao, address _guardian) {
        require(_dao != address(0), "invalid address");
        require(_guardian != address(0), "invalid address");

        dao = _dao;
        guardian = _guardian;
    }

    /// @notice Transfer the DAO to a new address
    /// @dev Only callable by the current DAO. The new dao cannot be address(0) or the same dao.
    /// @param newDAO The address of the new dao
    function transferDAO(address newDAO) public {
        enforceCallerDAO();
        require(newDAO != address(0), "invalid address");
        require(newDAO != dao, "!new");

        emit TransferDAO(dao, newDAO);

        dao = newDAO;
    }

    /// @notice Transfer the Guardian to a new address
    /// @dev Callable by the current DAO or the current Guardian. The new Guardian cannot be address(0)
    /// or the same as before.
    /// @param newGuardian The address of the new Guardian
    function transferGuardian(address newGuardian) public {
        enforceCallerGuardian();
        require(newGuardian != address(0), "invalid address");
        require(newGuardian != guardian, "!new");

        emit TransferGuardian(guardian, newGuardian);

        guardian = newGuardian;
    }

    /// @notice Pause the deposits into the system
    /// @dev Callable by DAO or Guardian. It will block any junior & senior deposits until resumed.
    function pauseSystem() public {
        enforceCallerGuardian();
        require(!paused, "paused");

        paused = true;

        emit PauseSystem();
    }

    /// @notice Resume the deposits into the system
    /// @dev Callable by DAO or Guardian. It will resume deposits.
    function resumeSystem() public {
        enforceCallerGuardian();
        require(paused, "!paused");

        paused = false;

        emit ResumeSystem();
    }

    /// @notice Change the price oracle
    /// @dev Only callable by DAO. The address of the new price oracle must have contract code.
    /// @param newPriceOracle The address of the new price oracle contract
    function setPriceOracle(address newPriceOracle) public {
        enforceCallerDAO();
        enforceHasContractCode(newPriceOracle, "invalid address");

        emit SetPriceOracle(address(priceOracle), newPriceOracle);

        priceOracle = IPriceOracle(newPriceOracle);
    }

    /// @notice Change the senior rate model contract
    /// @dev Only callable by DAO. The address of the new contract must have code.
    /// @param newModel The address of the new model
    function setSeniorRateModel(address newModel) public {
        enforceCallerDAO();
        enforceHasContractCode(newModel, "invalid address");

        emit SetSeniorRateModel(address(seniorRateModel), newModel);

        seniorRateModel = ISeniorRateModel(newModel);
    }

    /// @notice Change the accounting model contract
    /// @dev Only callable by DAO. The address of the new contract must have code.
    /// @param newModel The address of the new model
    function setAccountingModel(address newModel) public {
        enforceCallerDAO();
        enforceHasContractCode(newModel, "invalid address");

        emit SetAccountingModel(address(accountingModel), newModel);

        accountingModel = IAccountingModel(newModel);
    }

    /// @notice Change the owner of the fees
    /// @dev Only callable by DAO. The new owner must not be 0 address.
    /// @param newOwner The address to which fees will be transferred
    function setFeesOwner(address newOwner) public {
        enforceCallerDAO();
        require(newOwner != address(0), "invalid address");

        emit SetFeesOwner(feesOwner, newOwner);

        feesOwner = newOwner;
    }

    /// @notice Change the percentage of the fees applied
    /// @dev Only callable by DAO. If the percentage is greater than 0, it must also have a fees owner.
    /// @param percentage The percentage of profits to be taken as fee
    function setFeesPercentage(uint256 percentage) public {
        enforceCallerDAO();
        if (percentage > 0) {
            require(feesOwner != address(0), "no fees owner");
        }
        require(percentage < MAX_FEES_PERCENTAGE, "max percentage exceeded");

        emit SetFeesPercentage(feesPercentage, percentage);

        feesPercentage = percentage;
    }

    /// @notice Helper function to enforce that the call comes from the DAO
    /// @dev Reverts the execution if msg.sender is not the DAO.
    function enforceCallerDAO() internal view {
        require(msg.sender == dao, "!dao");
    }

    /// @notice Helper function to enforce that the call comes from the Guardian
    /// @dev Reverts the execution if msg.sender is not the Guardian.
    function enforceCallerGuardian() internal view {
        require(msg.sender == guardian || msg.sender == dao, "!guardian");
    }

    /// @notice Helper function to block any action while the system is paused
    /// @dev Reverts the execution if the system is paused
    function enforceSystemNotPaused() internal view {
        require(!paused, "paused");
    }

    /// @notice Helper function to check for contract code at given address
    /// @dev Reverts if there's no code at the given address.
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}