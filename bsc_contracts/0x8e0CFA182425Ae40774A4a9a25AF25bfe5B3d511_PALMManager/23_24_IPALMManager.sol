// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {VaultInfo} from "../structs/SPALMManager.sol";
import {Rebalance} from "@arrakisfi/v2-core/contracts/structs/SArrakisV2.sol";

interface IPALMManager {
    event AddVault(address indexed vault, bytes datas, string strat);

    event RemoveVault(address indexed vault, uint256 sendBack);

    event SetVaultData(address indexed vault, bytes data);

    event SetVaultStrat(address indexed vault, bytes32 strat);

    event SetManagerFeeBPS(address indexed vault, uint16 managerFeeBPS);

    event WhitelistStrat(string strat);

    event AddOperators(address[] operators);

    event RemoveOperators(address[] operators);

    event UpdateVaultBalance(address indexed vault, uint256 newBalance);

    event SetGelatoFeeCollector(address gelatoFeeCollector);

    event SetTermEnd(
        address indexed vault,
        uint256 oldtermEnd,
        uint256 newtermEnd
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
        Rebalance calldata rebalanceParams_,
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

    function setVaultStratByName(address vault_, string calldata strat_)
        external;

    function setGelatoFeeCollector(address payable gelatoFeeCollector_)
        external;

    function setManagerFeeBPS(address vault_) external;

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

    function getOperators() external view returns (address[] memory);

    function managerFeeBPS() external view returns (uint16);
}