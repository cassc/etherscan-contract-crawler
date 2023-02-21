// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IWorldPassNFT.sol";

interface IBonfire {
    /**
     *  @notice The body of a request to burn old WP & mint new, including dice roll.
     *
     *  @param to The owner of rolled dice & burnt WPs, and receiver of the WP tokens to mint.
     *  @param wpBurnAmount The amount of 1155 WPs to burn. Needs to be <= the amount of WPs owned by `to` address.
     *  @param diceIds Array of original Dice NFT IDs to be reforged (burn old & mint new).
     *  @param diceResults Array of the dice roll results (totals).
     *  @param wpIds Array of the new WP IDs to mint.
     *  @param validityStartTimestamp The unix timestamp after which the payload is valid.
     *  @param validityEndTimestamp The unix timestamp at which the payload expires.
     *  @param uid A unique identifier for the payload.
     */
    struct BurnRequest {
        address to;
        uint128 wpBurnAmount;
        uint256[] diceIds;
        uint8[] diceResults;
        uint8[] wpHouses;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
        bytes32 uid;
    }

    /// @dev Emitted on Bonfire Burn call.
    event BonfireBurn(address indexed mintedTo, BurnRequest burnRequest);

    /// @dev Emitted on Bonfire burnDiceOnly call.
    event BonfireBurnDiceOnly(
        address indexed mintedTo,
        uint256[] indexed burntDiceIDs
    );

    /// @dev Emitted on Bonfire joinScarred call.
    event BonfireJoinScarred(
        address indexed mintedTo,
        uint256 indexed burnAmount
    );

    /**
     *  @notice Verifies that a burn request is signed by a specific account
     *
     *  @param req The payload / burn request.
     *  @param signature The signature produced by an account signing the burn request.
     *
     *  returns (success, signer) Result of verification and the recovered address.
     */
    function verify(BurnRequest calldata req, bytes calldata signature)
        external
        view
        returns (bool success, address signer);

    /**
     *  @notice Mints tokens according to the provided mint request.
     *
     *  @param req The payload / mint request.
     *  @param signature The signature produced by an account signing the mint request.
     *
     *  returns (signer) the recovered address.
     */
    function bonfireBurn(BurnRequest calldata req, bytes calldata signature)
        external
        returns (address signer);

    /**
     *  @notice Allows caller to burn their old dice to mint new ones.
     *
     *  @param diceIds The diceIds to burn & re-mint from new contract.
     */
    function burnDiceOnly(uint256[] calldata diceIds) external;

    /**
     *  @notice Allows caller to burn their old wp to mint new WPs with "Scarred" attribute.
     *
     *  @param burnAmount The amount of old WPs to burn & re-mint from new contract.
     */
    function joinScarred(uint256 burnAmount) external;
}