// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice Contains all events emitted by the party
 * @dev Events emitted by a party
 */
interface IPartyEvents {
    /**
     * @notice Emitted exactly once by a party when #initialize is first called
     * @param partyCreator Address of the user that created the party
     * @param partyName Name of the party
     * @param isPublic Visibility of the party
     * @param dAsset Address of the denomination asset for the party
     * @param minDeposit Minimum deposit of the party
     * @param maxDeposit Maximum deposit of the party
     * @param mintedPT Minted party tokens for creating the party
     * @param bio Bio of the party
     * @param img Img url of the party
     * @param model Model of party created
     * @param purpose Purpose of party created
     */
    event PartyCreated(
        address partyCreator,
        string partyName,
        bool isPublic,
        address dAsset,
        uint256 minDeposit,
        uint256 maxDeposit,
        uint256 mintedPT,
        string bio,
        string img,
        string model,
        string purpose
    );

    /**
     * @notice Emitted when a user joins a party
     * @param member Address of the user
     * @param asset Address of the denomination asset
     * @param amount Amount of the deposit
     * @param fee Collected fee
     * @param mintedPT Minted party tokens for joining
     */
    event Join(
        address member,
        address asset,
        uint256 amount,
        uint256 fee,
        uint256 mintedPT
    );

    /**
     * @notice Emitted when a member deposits denomination assets into a party
     * @param member Address of the user
     * @param asset Address of the denomination asset
     * @param amount Amount of the deposit
     * @param fee Collected fee
     * @param mintedPT Minted party tokens for depositing
     */
    event Deposit(
        address member,
        address asset,
        uint256 amount,
        uint256 fee,
        uint256 mintedPT
    );

    /**
     * @notice Emitted when quotes are filled by 0x for allocation of funds
     * @dev SwapToken is not included on this event, since its have the same information
     * @param member Address of the user
     * @param sellTokens Array of sell tokens
     * @param buyTokens Array of buy tokens
     * @param soldAmounts Array of sold amount of tokens
     * @param boughtAmounts Array of bought amount of tokens
     * @param partyValueDA The party value in denomination asset prior to the allocation
     */
    event AllocationFilled(
        address member,
        address[] sellTokens,
        address[] buyTokens,
        uint256[] soldAmounts,
        uint256[] boughtAmounts,
        uint256 partyValueDA
    );

    /**
     * @notice Emitted when a member redeems shares from a party
     * @param member Address of the user
     * @param burnedPT Burned party tokens for redemption
     * @param liquidate Redemption by liquitating shares into denomination asset
     * @param redeemedAssets Array of asset addresses
     * @param redeemedAmounts Array of asset amounts
     * @param redeemedFees Array of asset fees
     * @param redeemedNetAmounts Array of net asset amounts
     */
    event RedeemedShares(
        address member,
        uint256 burnedPT,
        bool liquidate,
        address[] redeemedAssets,
        uint256[] redeemedAmounts,
        uint256[] redeemedFees,
        uint256[] redeemedNetAmounts
    );

    /**
     * @notice Emitted when a member withdraws from a party
     * @param member Address of the user
     * @param burnedPT Burned party tokens of member
     */
    event Withdraw(address member, uint256 burnedPT);

    /**
     * @notice Emitted when quotes are filled by 0x in the same tx
     * @param member Address of the user
     * @param sellToken Sell token address
     * @param buyToken Buy token address
     * @param soldAmount Sold amount of token
     * @param boughtAmount Bought amount of token
     * @param fee fee collected
     */
    event SwapToken(
        address member,
        address sellToken,
        address buyToken,
        uint256 soldAmount,
        uint256 boughtAmount,
        uint256 fee
    );

    /**
     * @notice Emitted when a member gets kicked from a party
     * @param kicker Address of the kicker (owner)
     * @param kicked Address of the kicked member
     * @param burnedPT Burned party tokens of member
     */
    event Kick(address kicker, address kicked, uint256 burnedPT);

    /**
     * @notice Emitted when a member leaves a party
     * @param member Address of the user
     * @param burnedPT Burned party tokens for withdrawing
     */
    event Leave(address member, uint256 burnedPT);

    /**
     * @notice Emitted when the owner closes a party
     * @param member Address of the user (should be party owner)
     * @param supply Total supply of party tokens when the party closed
     */
    event Close(address member, uint256 supply);

    /**
     * @notice Emitted when the party information changes after creation
     * @param name Name of the party
     * @param bio Bio of the party
     * @param img Img url of the party
     * @param model Model of party created
     * @param purpose Purpose of party created
     * @param isPublic Visibility of the party
     * @param minDeposit Minimum deposit of the party
     * @param maxDeposit Maximum deposit of the party
     */
    event PartyInfoEdit(
        string name,
        string bio,
        string img,
        string model,
        string purpose,
        bool isPublic,
        uint256 minDeposit,
        uint256 maxDeposit
    );

    /**
     * @notice Emitted when the party creator adds or remove a party manager
     * @param manager Address of the user
     * @param isManager Whether to set the user was set as manager or removed from it
     */
    event PartyManagersChange(address manager, bool isManager);
}