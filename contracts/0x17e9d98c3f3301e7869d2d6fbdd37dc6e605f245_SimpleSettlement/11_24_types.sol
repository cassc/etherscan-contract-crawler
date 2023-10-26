// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

struct Bid {
    // vault selling structures
    address vault;
    // Indicated how much the vault is short or long this instrument in a structure
    int256[] weights;
    // option ids
    uint256[] options;
    // id of the asset
    uint8 premiumId;
    // premium paid to vault
    int256 premium;
    // expiration of bid
    uint256 expiry;
    // Number only used once
    uint256 nonce;
    // Signature recovery id
    uint8 v;
    // r portion of the ECSDA signature
    bytes32 r;
    // s portion of the ECSDA signature
    bytes32 s;
}

/**
 * @dev Position struct
 * @param tokenId option token id
 * @param amount number option tokens
 */
struct Position {
    uint256 tokenId;
    uint64 amount;
}

/**
 * @dev struct representing the current balance for a given collateral
 * @param collateralId asset id
 * @param amount amount the asset
 */
struct Balance {
    uint8 collateralId;
    uint80 amount;
}

struct Collateral {
    // Grappa asset Id
    uint8 id;
    // ERC20 token address for the required collateral
    address addr;
    // the amount of decimals or token
    uint8 decimals;
}

/**
 * @notice The action type for the execute function
 * @dev    unitary representation of the ActionArgs struct from the core physical and cash engines
 */
struct ActionArgs {
    // action type represented as uint8 (see enum ActionType)
    uint8 action;
    // data payload for the action
    bytes data;
}

/**
 * @notice The batch action type for the execute function
 * @dev    unitary representation of the BatchExecute struct from the core physical and cash engines
 */
struct BatchExecute {
    // address of the account to execute the batch
    address subAccount;
    // array of actions to execute
    ActionArgs[] actions;
}