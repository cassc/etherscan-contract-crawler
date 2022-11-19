// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArrakisV2, Rebalance, Range} from "./interfaces/IArrakisV2.sol";
import {PALMManagerStorage} from "./abstracts/PALMManagerStorage.sol";
import {VaultInfo} from "./structs/SPALMManager.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract PALMManager is PALMManagerStorage {
    using Address for address payable;

    constructor(
        uint16 managerFeeBPS_,
        address terms_,
        uint256 termDuration_
    )
        PALMManagerStorage(managerFeeBPS_, terms_, termDuration_)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    function rebalance(
        address vault_,
        Range[] calldata ranges_,
        Rebalance calldata rebalanceParams_,
        Range[] calldata rangesToRemove_,
        uint256 feeAmount_
    ) external override whenNotPaused onlyManagedVaults(vault_) onlyOperators {
        uint256 balance = _preExec(vault_, feeAmount_);
        IArrakisV2(vault_).rebalance(
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