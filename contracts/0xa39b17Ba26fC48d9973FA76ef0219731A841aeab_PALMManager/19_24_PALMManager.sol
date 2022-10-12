// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IArrakisV2, Rebalance, Range} from "./interfaces/IArrakisV2.sol";
import {IPALMManager} from "./interfaces/IPALMManager.sol";
import {
    IUniswapV3Pool
} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PALMManagerStorage} from "./abstracts/PALMManagerStorage.sol";
import {VaultInfo} from "./structs/SPALMManager.sol";

contract PALMManager is PALMManagerStorage {
    using SafeERC20 for IERC20;

    constructor(
        address gelato_,
        uint16 managerFeeBPS_,
        address terms_,
        uint256 termDuration_
    )
        PALMManagerStorage(gelato_, managerFeeBPS_, terms_, termDuration_)
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
        VaultInfo memory vaultInfo = vaults[vault_];
        require(
            vaultInfo.balance >= feeAmount_,
            "PALMManager: Not enough balance to pay fee"
        );
        balance = vaultInfo.balance - feeAmount_;

        // update lastRebalance time
        // solhint-disable-next-line not-rely-on-time
        vaults[vault_].lastRebalance = block.timestamp;
        vaults[vault_].balance = balance;
    }

    // #endregion ====== INTERNAL FUNCTIONS ========
}