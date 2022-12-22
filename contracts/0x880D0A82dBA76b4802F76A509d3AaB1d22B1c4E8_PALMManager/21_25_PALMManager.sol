// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {
    IArrakisV2Extended,
    Rebalance,
    Range
} from "./interfaces/IArrakisV2Extended.sol";
import {PALMManagerStorage} from "./abstracts/PALMManagerStorage.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract PALMManager is PALMManagerStorage {
    using Address for address payable;

    constructor(
        address terms_,
        uint256 termDuration_,
        uint16 managerFeeBPS_
    )
        PALMManagerStorage(terms_, termDuration_, managerFeeBPS_)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    /// @notice rebalance Arrakis V2 tokens allocation on Uniswap V3.
    /// @param vault_ Arrakis V2 vault address
    /// @param ranges_ ranges to tracks
    /// @param rebalanceParams_ contains all data for doing reblance
    /// @param rangesToRemove_ ranges to remove
    /// @param feeAmount_ gas cost of rebalance
    /// @dev only operators can call it
    function rebalance(
        address vault_,
        Range[] calldata ranges_,
        Rebalance calldata rebalanceParams_,
        Range[] calldata rangesToRemove_,
        uint256 feeAmount_
    ) external override whenNotPaused onlyManagedVaults(vault_) onlyOperators {
        uint256 balance = _preExec(vault_, feeAmount_);
        IArrakisV2Extended(vault_).rebalance(
            ranges_,
            rebalanceParams_,
            rangesToRemove_
        );
        emit RebalanceVault(vault_, balance);
    }

    // #region ====== INTERNAL FUNCTIONS ========

    function _preExec(address vault_, uint256 feeAmount_)
        internal
        returns (uint256 balance)
    {
        uint256 vaultBalance = vaults[vault_].balance;
        require(
            vaultBalance >= feeAmount_,
            "PALMManager: Not enough balance to pay fee"
        );
        balance = vaultBalance - feeAmount_;

        // update lastRebalance time
        // solhint-disable-next-line not-rely-on-time
        vaults[vault_].lastRebalance = block.timestamp;
        vaults[vault_].balance = balance;

        Address.sendValue(gelatoFeeCollector, feeAmount_);
    }

    // #endregion ====== INTERNAL FUNCTIONS ========
}