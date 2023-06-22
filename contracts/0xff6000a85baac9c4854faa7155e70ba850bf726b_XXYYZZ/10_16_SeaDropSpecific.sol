// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct PublicDrop {
    uint80 mintPrice; // 80/256 bits
    uint48 startTime; // 128/256 bits
    uint48 endTime; // 176/256 bits
    uint16 maxTotalMintableByWallet; // 224/256 bits
    uint16 feeBps; // 240/256 bits
    bool restrictFeeRecipients; // 248/256 bits
}

interface ISeaDrop {
    /**
     * @notice Updates the public drop data for the nft contract
     *         and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param publicDrop The public drop data.
     */
    function updatePublicDrop(PublicDrop calldata publicDrop) external;

    /**
     * @notice Updates the creator payout address and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param payoutAddress The creator payout address.
     */
    function updateCreatorPayoutAddress(address payoutAddress) external;

    /**
     * @notice Updates the allowed fee recipient and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param feeRecipient The fee recipient.
     * @param allowed      If the fee recipient is allowed.
     */
    function updateAllowedFeeRecipient(address feeRecipient, bool allowed) external;

    /**
     * @notice Updates the allowed payer and emits an event.
     *
     *         This method assume msg.sender is an nft contract and its
     *         ERC165 interface id matches INonFungibleSeaDropToken.
     *
     *         Note: Be sure only authorized users can call this from
     *         token contracts that implement INonFungibleSeaDropToken.
     *
     * @param payer   The payer to add or remove.
     * @param allowed Whether to add or remove the payer.
     */
    function updatePayer(address payer, bool allowed) external;
}