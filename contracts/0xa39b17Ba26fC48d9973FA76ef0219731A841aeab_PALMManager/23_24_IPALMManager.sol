// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Rebalance, Range} from "./IArrakisV2.sol";
import {IManager} from "./IManager.sol";
import {VaultInfo} from "../structs/SPALMManager.sol";

interface IPALMManager is IManager {
    event AddVault(address indexed vault, bytes datas, string strat);

    event RemoveVault(address indexed vault, uint256 sendBack);

    event SetVaultData(address indexed vault, bytes data);

    event SetVaultStrat(address indexed vault, bytes32 strat);

    event WhitelistStrat(address indexed manager, string strat);

    event AddOperators(address indexed manager, address[] operators);

    event RemoveOperators(address indexed manager, address[] operators);

    event UpdateVaultBalance(address indexed vault, uint256 newBalance);

    event SetTermEnd(
        address indexed vault,
        uint256 oldtermDuration,
        uint256 newtermDuration
    );

    event WithdrawVaultBalance(
        address indexed vault,
        uint256 amount,
        address to,
        uint256 newBalance
    );

    event RebalanceVault(address indexed vault, uint256 newBalance);

    // ======== GELATOFIED FUNCTIONS ========
    function rebalance(
        address vault_,
        Range[] calldata ranges_,
        Rebalance calldata rebalanceParams_,
        Range[] calldata rangesToRemove_,
        uint256 feeAmount_
    ) external;

    // ======= PERMISSIONED OWNER FUNCTIONS =====
    function withdrawVaultBalance(
        address vault_,
        uint256 amount_,
        address payable to_
    ) external;

    function addVault(
        address vault_,
        bytes calldata datas_,
        string calldata strat_
    ) external payable;

    function removeVault(address vault_, address payable to_) external;

    function setVaultData(address vault_, bytes calldata data_) external;

    function setVaultStraByName(address vault_, string calldata strat_)
        external;

    function addOperators(address[] calldata operators_) external;

    function removeOperators(address[] calldata operators_) external;

    function pause() external;

    function unpause() external;

    function withdrawFeesEarned(address[] calldata tokens_, address to_)
        external;

    // ======= PUBLIC FUNCTIONS =====
    function fundVaultBalance(address vault_) external payable;

    function renewTerm(address vault_) external;

    function getVaultInfo(address vault_)
        external
        view
        returns (VaultInfo memory);

    function getWhitelistedStrat() external view returns (bytes32[] memory);

    function vaults(address vault_)
        external
        view
        returns (
            uint256 balance,
            uint256 lastBalance,
            bytes memory datas,
            bytes32 strat,
            uint256 termEnd
        );
}