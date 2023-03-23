pragma solidity ^0.8.0;

// SPDX-License-Identifier: BUSL-1.1

import { IERC20 } from "./IERC20.sol";
import { ISavETHManager } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/ISavETHManager.sol";
import { IAccountManager } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IAccountManager.sol";
import { IBalanceReporter } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IBalanceReporter.sol";
import { ISlotSettlementRegistry } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/ISlotSettlementRegistry.sol";
import { IStakeHouseRegistry } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IStakeHouseRegistry.sol";
import { IStakeHouseUniverse } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IStakeHouseUniverse.sol";
import { ITransactionRouter } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/ITransactionRouter.sol";

import { MainnetConstants, GoerliConstants } from "./Constants.sol";

/// @title Implementable Stakehouse protocol smart contract consumer without worrying about the interfaces or addresses
abstract contract StakehouseAPI {

    /// @dev Get the interface connected to the AccountManager smart contract
    function getAccountManager() internal view virtual returns (IAccountManager accountManager) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            accountManager = IAccountManager(MainnetConstants.AccountManager);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            accountManager = IAccountManager(GoerliConstants.AccountManager);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Get the interface connected to the Balance Reporter smart contract
    function getBalanceReporter() internal view virtual returns (IBalanceReporter balanceReporter) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            balanceReporter = IBalanceReporter(MainnetConstants.TransactionRouter);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            balanceReporter = IBalanceReporter(GoerliConstants.TransactionRouter);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Get the interface connected to the savETH registry adaptor smart contract
    function getSavETHRegistry() internal view virtual returns (ISavETHManager savETHManager) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            savETHManager = ISavETHManager(MainnetConstants.SavETHManager);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            savETHManager = ISavETHManager(GoerliConstants.SavETHManager);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Get the interface connected to the SLOT registry smart contract
    function getSlotRegistry() internal view virtual returns (ISlotSettlementRegistry slotSettlementRegistry) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            slotSettlementRegistry = ISlotSettlementRegistry(MainnetConstants.SlotSettlementRegistry);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            slotSettlementRegistry = ISlotSettlementRegistry(GoerliConstants.SlotSettlementRegistry);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Get the interface connected to an arbitrary Stakehouse registry smart contract
    function getStakeHouseRegistry(address _stakeHouse) internal view virtual returns (IStakeHouseRegistry stakehouse) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            stakehouse = IStakeHouseRegistry(_stakeHouse);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            stakehouse = IStakeHouseRegistry(_stakeHouse);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Get the interface connected to the Stakehouse universe smart contract
    function getStakeHouseUniverse() internal view virtual returns (IStakeHouseUniverse universe) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            universe = IStakeHouseUniverse(MainnetConstants.StakeHouseUniverse);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            universe = IStakeHouseUniverse(GoerliConstants.StakeHouseUniverse);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Get the interface connected to the Transaction Router adaptor smart contract
    function getTransactionRouter() internal view virtual returns (ITransactionRouter transactionRouter) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            transactionRouter = ITransactionRouter(MainnetConstants.TransactionRouter);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            transactionRouter = ITransactionRouter(GoerliConstants.TransactionRouter);
        }

        else {
            _unsupported();
        }
    }

    /// @notice Get the dETH instance
    function getDETH() internal view virtual returns (IERC20 dETH) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            dETH = IERC20(MainnetConstants.dETH);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            dETH = IERC20(GoerliConstants.dETH);
        }

        else {
            _unsupported();
        }
    }

    /// @dev If the network does not match one of the choices stop the flow
    function _unsupported() internal pure {
        revert('Network unsupported');
    }

    /// @dev Helper function to get the id of the current chain
    function _getChainId() internal view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}