// solhint-disable max-states-count
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// library
import { DataTypes } from "../../protocol/earn-protocol-configuration/contracts/libraries/types/DataTypes.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Vault state that can change
 * @author opty.fi
 * @dev The storage contract for opty.fi's interest bearing vault token
 */

contract VaultStorage {
    /**
     * @dev A list to maintain sequence of unprocessed deposits
     */
    DataTypes.UserDepositOperation[] public queue;

    /**
     * @dev Mapping of user account who has not received shares against deposited amount
     */
    mapping(address => uint256) public pendingDeposits;

    /**
     * @dev Mapping of user account against total deposited amount
     */
    mapping(address => uint256) public totalDeposits;

    /**
     * @dev Map the underlying token in vault to the current block for emergency brakes
     */
    mapping(uint256 => DataTypes.BlockVaultValue[]) public blockToBlockVaultValues;

    /**
     * @dev Current vault invest strategy
     */
    bytes32 public investStrategyHash;

    /**
     * @dev Maximum amount in underlying token allowed to be deposited by user
     */
    uint256 public userDepositCapUT;

    /**
     * @dev Minimum deposit value in underlying token required
     */
    uint256 public minimumDepositValueUT;

    /**
     * @notice Fee and vaultvalue jump config params of the vault
     * @dev bit 0-15 deposit fee in underlying token without decimals
     *      bit 16-31 deposit fee in basis points
     *      bit 32-47 withdrawal fee in underlying token without decimals
     *      bit 48-63 withdrawal fee in basis points
     *      bit 64-79 max vault value jump allowed in basis points (standard deviation allowed for vault value)
     *      bit 80-239 vault fee collection address
     *      bit 240-247 risk profile code
     *      bit 248 emergency shutdown flag
     *      bit 249 pause flag (deposit/withdraw is pause when bit is unset, unpause otherwise)
     *      bit 250 white list state flag
     */
    uint256 public vaultConfiguration;

    /**
     * @dev store the underlying token contract address (for example DAI)
     */
    address public underlyingToken;

    /**
     * @notice accounts allowed to interact with vault if whitelisted
     * @dev merkle root hash of whitelisted accounts
     */
    bytes32 public whitelistedAccountsRoot;

    /**
     * @dev Maximum TVL in underlying token allowed for the vault
     */
    uint256 public totalValueLockedLimitUT;
}

contract VaultStorageV2 is VaultStorage {
    /**
     * @dev domain separator for the vault
     */
    bytes32 public _domainSeparator;

    /**
     * @notice underlying tokens's hash
     * @dev keccak256 hash of the underlying tokens and chain id
     */
    bytes32 public underlyingTokensHash;

    /**@notice current strategy metadata*/
    DataTypes.StrategyStep[] public investStrategySteps;

    /**@dev cache strategy metadata*/
    DataTypes.StrategyStep[] internal _cacheNextInvestStrategySteps;
}

contract VaultStorageV3 is VaultStorageV2 {
    /**@dev nonce counter*/
    mapping(address => uint256) internal _nonces;

    /**@dev deposit and withdraw flag*/
    mapping(uint256 => bool) public blockTransaction;
}