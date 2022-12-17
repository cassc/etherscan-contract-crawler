// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**

  ##########      ##########      #####   #####    #####   ############   ##########        ##########
  ############    ############    #####   #####    #####   ############   ############     ############
  #####   #####   #####  ######   #####   #####    #####   ############   #####  ######   ######  ######
  #####   #####   #####   #####   #####   #####    #####   #####          #####   #####   ######  ######
  #####   #####   #####   #####   #####    ####    ####    #####          #####   #####   #######
  #####   #####   #####  #####    #####    ####    ####    ##########     #####  #####     ##########
  #####   #####   ###########     #####    ####    ####    ##########     ###########       ###########
  #####   #####   ############    #####    ####    ####    #####          ############           #######
  #####   #####   #####   #####   #####     ####  ####     #####          #####   #####   ######  ######
  #####   #####   #####   #####   #####     ##########     ############   #####   #####   ######  ######
  ############    #####   #####   #####      ########      ############   #####   #####    ############
  ##########      #####   #####   #####        ####        ############   #####   #####     ##########

  By Everfresh

*/

import "./ERC1155Base.sol";

/**
 * @author Fount Gallery
 * @title  Drivers Open Editions by Everfresh
 * @notice Drivers is celebrated motion artist Everfresh's first Fount Gallery release. Driven by
 * the rhythm of skate culture and dance, the Drivers collection delivers an immersive world of
 * form and flow.
 *
 * Features:
 *   - Open edition NFTs
 *   - ERC-1155 lazy minting
 *   - Flexible minting conditions with EIP-712 signatures or on-chain Fount Card checks
 *   - Swappable metadata contract
 *   - On-chain royalties standard (EIP-2981)
 *   - Support for OpenSea's Operator Filterer to allow royalties
 */
contract DriversOpenEditions is ERC1155Base {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev Stores information about a given token
    struct TokenData {
        uint128 price;
        uint32 startTime;
        uint32 endTime;
        uint32 collected;
        uint16 perAddressAllowance;
        bool fountExclusive;
        bool requiresSig;
    }

    /// @dev Mapping of token id to token data
    mapping(uint256 => TokenData) internal _idToTokenData;

    /* ------------------------------------------------------------------------
       E R R O R S
    ------------------------------------------------------------------------ */

    /** TOKEN DATA ---------------------------------------------------------- */
    error TokenDataDoesNotExist();
    error TokenDataAlreadyExists();
    error CannotSetStartTimeToZero();
    error CannotSetEndTimeToThePast();

    /** SALE CONDITIONS ---------------------------------------------------- */
    error RequiresFountCard();
    error RequiresSignature();
    error InvalidSignature();

    /** PURCHASING --------------------------------------------------------- */
    error NotForSale();
    error IncorrectPaymentAmount();
    error AmountExceedsMaxWalletMint();
    error AmountExceedsWalletAllowance();

    /** EDITIONS ----------------------------------------------------------- */
    error OpenEditionEnded();
    error OpenEditionNotStartedYet();

    /* ------------------------------------------------------------------------
       E V E N T S
    ------------------------------------------------------------------------ */

    event TokenDataAdded(uint256 indexed id, TokenData tokenData);
    event TokenDataSaleTimesUpdated(uint256 indexed id, TokenData tokenData);
    event TokenDataSalePriceUpdated(uint256 indexed id, TokenData tokenData);
    event TokenDataSaleConditionsUpdated(uint256 indexed id, TokenData tokenData);

    event CollectedOpenEdition(uint256 indexed id);

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ The owner of the contract
     * @param admin_ The admin of the contract
     * @param payments_ The address where payments should be sent
     * @param royaltiesAmount_ The royalty percentage with two decimals (10,000 = 100%)
     * @param metadata_ The initial metadata contract address
     * @param fountCard_ The address of the Fount Gallery Patron Card
     */
    constructor(
        address owner_,
        address admin_,
        address payments_,
        uint256 royaltiesAmount_,
        address metadata_,
        address fountCard_
    ) ERC1155Base(owner_, admin_, payments_, royaltiesAmount_, metadata_, fountCard_) {}

    /* ------------------------------------------------------------------------
       O P E N   E D I T I O N S
    ------------------------------------------------------------------------ */

    /**
     * @notice Mints a number of editions from an open edition NFT
     * @dev Calls internal `_collectEdition` for logic.
     *
     * Reverts if:
     *  - the edition requires an off-chain signature
     *  - see `_collectEdition` for other conditions
     *
     * @param id The id of the edition
     * @param amount The amount to mint
     * @param to The address to mint the token to
     */
    function collectEdition(
        uint256 id,
        uint256 amount,
        address to
    ) external payable {
        TokenData memory tokenData = _idToTokenData[id];
        if (tokenData.requiresSig) revert RequiresSignature();
        _collectEdition(id, amount, to, tokenData);
    }

    /**
     * @notice Mints a number of editions from an open edition NFT with an off-chain signature
     * @dev Calls internal `_collectEdition` for logic.
     *
     * Reverts if:
     *  - the edition requires an off-chain signature and the signature is invalid
     *  - see `_collectEdition` for other conditions
     *
     * @param id The id of the edition
     * @param amount The amount to mint
     * @param to The address to mint the token to
     * @param signature The off-chain signature which permits a mint
     */
    function collectEdition(
        uint256 id,
        uint256 amount,
        address to,
        bytes calldata signature
    ) external payable {
        TokenData memory tokenData = _idToTokenData[id];
        if (tokenData.requiresSig && !_verifyMintSignature(id, amount, to, signature)) {
            revert InvalidSignature();
        }
        _collectEdition(id, amount, to, tokenData);
    }

    /**
     * @notice Internal function to mint some editions with some conditions
     * @dev Allows minting to a different address from msg.sender.
     *
     * Reverts if:
     *  - the edition has not started
     *  - the edition has ended
     *  - msg.value does not equal the required amount
     *  - the edition requires a Fount Card, but `to` does not hold one
     *
     * @param id The token id of the edition
     * @param amount The amount of editions to mint
     * @param to The address to mint the token to
     * @param tokenData Information about the token
     */
    function _collectEdition(
        uint256 id,
        uint256 amount,
        address to,
        TokenData memory tokenData
    ) internal {
        uint256 mintAmount = amount;

        // Check to see if the edition is mintable and the price is correct
        if (tokenData.startTime > block.timestamp) revert OpenEditionNotStartedYet();
        if (tokenData.endTime > 0 && block.timestamp > tokenData.endTime) revert OpenEditionEnded();
        if (tokenData.price > 0 && tokenData.price * amount != msg.value) {
            revert IncorrectPaymentAmount();
        }

        // Check if it's a Fount Gallery exclusive
        if (tokenData.fountExclusive && !_isFountCardHolder(to)) revert RequiresFountCard();

        // Check if there's a cap on mints per wallet
        if (tokenData.perAddressAllowance > 0) {
            // Check the amount doesn't exceed the per wallet allowance to mint
            if (amount > tokenData.perAddressAllowance) revert AmountExceedsMaxWalletMint();

            // Get the accounts remaining balance for this edition
            uint256 currentBalance = balanceOf[to][id];
            uint256 remainingAllowance = currentBalance >= tokenData.perAddressAllowance
                ? 0
                : tokenData.perAddressAllowance - currentBalance;

            // Set the mint amount based on the remaining allowance of `to`
            if (amount > remainingAllowance) {
                mintAmount = remainingAllowance;
            }

            // If there's no allowed tokens to mint, then revert
            if (mintAmount == 0) revert AmountExceedsWalletAllowance();

            // If the request amount was over the actual mint amount, refund any ETH to the msg.sender
            if (tokenData.price > 0 && amount > mintAmount) {
                _transferETHWithFallback(msg.sender, (amount - mintAmount) * tokenData.price);
            }
        }

        // Add the new mint to the token data
        unchecked {
            tokenData.collected += uint32(mintAmount);
        }
        _idToTokenData[id] = tokenData;

        // Mint the NFT to the `to` address
        _mintToArtistFirst(to, id, mintAmount);
        emit CollectedOpenEdition(id);
    }

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /** ADD TOKEN DATA ----------------------------------------------------- */

    /**
     * @notice Admin function to make a token available for sale
     * @dev As soon as the token data is registered, the NFT will be available to collect.
     *
     * Reverts if:
     *  - `startTime` is zero (used to check if a token can be sold or not)
     *  - `endTime` is in the past
     *  - the token data already exists (to update token data, use the other admin
     *    functions to set price and sale conditions)
     *
     * @param id The token id
     * @param price The sale price, if any
     * @param startTime The start time of the sale
     * @param endTime The end time of the sale, if any
     * @param mintPerAddress The max amount that can be minted for a wallet, if any
     * @param fountExclusive If the sale requires a Fount Gallery Patron card
     * @param requiresSig If the sale requires an off-chain signature
     */
    function addTokenForSale(
        uint256 id,
        uint128 price,
        uint32 startTime,
        uint32 endTime,
        uint16 mintPerAddress,
        bool fountExclusive,
        bool requiresSig
    ) external onlyOwnerOrAdmin {
        // Check that start time is valid. This value is used to check if the token data
        // exists. Setting to zero will effectively "delete" the token data for other functions.
        if (startTime == 0) revert CannotSetStartTimeToZero();

        // Check the end time is not in the past
        if (endTime > 0 && block.timestamp > endTime) revert CannotSetEndTimeToThePast();

        TokenData memory tokenData = _idToTokenData[id];

        // Check the token data is empty before adding
        if (tokenData.startTime != 0) revert TokenDataAlreadyExists();

        // Set the new token data
        tokenData.price = price;
        tokenData.startTime = startTime;
        tokenData.endTime = endTime;
        tokenData.perAddressAllowance = mintPerAddress;
        tokenData.fountExclusive = fountExclusive;
        tokenData.requiresSig = requiresSig;
        _idToTokenData[id] = tokenData;
        emit TokenDataAdded(id, tokenData);
    }

    /** SET SALE PRICE ----------------------------------------------------- */

    /**
     * @notice Admin function to update the sale price for a token
     * @dev Sets the start and end time values for a token. Setting `endTime` to zero
     * effectively keeps the edition open forever.
     *
     * Reverts if:
     *  - `startTime` is zero (used to check if a token can be sold or not)
     *  - `endTime` is in the past
     *  - the token data does not exist, must be added with `addTokenForSale` first
     *
     * @param id The token id
     * @param startTime The new start time of the sale
     * @param endTime The new end time of the sale
     */
    function setTokenSaleTimes(
        uint256 id,
        uint32 startTime,
        uint32 endTime
    ) external onlyOwnerOrAdmin {
        // Check that start time is not zero. This value is used to check if the token data
        // exists. Setting to zero will effectively "delete" the token data for other functions.
        if (startTime == 0) revert CannotSetStartTimeToZero();

        // Check the end time is not in the past
        if (endTime > 0 && block.timestamp > endTime) revert CannotSetEndTimeToThePast();

        TokenData memory tokenData = _idToTokenData[id];

        // Check the token data already exists.
        // If not, it should be created with `addTokenForSale` first.
        if (tokenData.startTime == 0) revert TokenDataDoesNotExist();

        // Set the new sale price
        tokenData.startTime = startTime;
        tokenData.endTime = endTime;
        _idToTokenData[id] = tokenData;
        emit TokenDataSaleTimesUpdated(id, tokenData);
    }

    /** SET SALE TIMES ----------------------------------------------------- */

    /**
     * @notice Admin function to update the sale price for a token
     * @dev Reverts if the token data does not exist. Must be added with `addTokenForSale` first.
     * @param id The token id
     * @param price The new sale price
     */
    function setTokenSalePrice(uint256 id, uint128 price) external onlyOwnerOrAdmin {
        TokenData memory tokenData = _idToTokenData[id];

        // Check the token data already exists.
        // If not, it should be created with `addTokenForSale` first.
        if (tokenData.startTime == 0) revert TokenDataDoesNotExist();

        // Set the new sale price
        tokenData.price = price;
        _idToTokenData[id] = tokenData;
        emit TokenDataSalePriceUpdated(id, tokenData);
    }

    /** SET SALE CONDITIONS ------------------------------------------------ */

    /**
     * @notice Admin function to update the sale conditions for a token
     * @dev Reverts if the token data does not exist. Must be added with `addTokenForSale` first.
     * @param id The token id
     * @param mintPerAddress The max amount that can be minted for a wallet, if any
     * @param fountExclusive If the sale requires a Fount Gallery Patron card
     * @param requiresSig If the sale requires an off-chain signature
     */
    function setTokenSaleConditions(
        uint256 id,
        uint16 mintPerAddress,
        bool fountExclusive,
        bool requiresSig
    ) external onlyOwnerOrAdmin {
        TokenData memory tokenData = _idToTokenData[id];

        // Check the token data already exists.
        // If not, it should be created with `addTokenForSale` first.
        if (tokenData.startTime == 0) revert TokenDataDoesNotExist();

        tokenData.perAddressAllowance = mintPerAddress;
        tokenData.fountExclusive = fountExclusive;
        tokenData.requiresSig = requiresSig;
        _idToTokenData[id] = tokenData;

        emit TokenDataSaleConditionsUpdated(id, tokenData);
    }

    /* ------------------------------------------------------------------------
                                   G E T T E R S
    ------------------------------------------------------------------------ */

    function tokenPrice(uint256 id) external view returns (uint256) {
        return _idToTokenData[id].price;
    }

    function tokenStartTime(uint256 id) external view returns (uint256) {
        return _idToTokenData[id].startTime;
    }

    function tokenEndTime(uint256 id) external view returns (uint256) {
        return _idToTokenData[id].endTime;
    }

    function tokenCollectedCount(uint256 id) external view returns (uint256) {
        return _idToTokenData[id].collected;
    }

    function tokenAllowancePerAddress(uint256 id) external view returns (uint256) {
        return _idToTokenData[id].perAddressAllowance;
    }

    function tokenRemainingAllowanceForAddress(uint256 id, address account)
        external
        view
        returns (uint256)
    {
        TokenData memory tokenData = _idToTokenData[id];
        uint256 currentBalance = balanceOf[account][id];
        uint256 remainingAllowance = currentBalance > tokenData.perAddressAllowance
            ? 0
            : tokenData.perAddressAllowance - currentBalance;
        return remainingAllowance;
    }

    function tokenIsFountExclusive(uint256 id) external view returns (bool) {
        return _idToTokenData[id].fountExclusive;
    }

    function tokenRequiresOffChainSignatureToMint(uint256 id) external view returns (bool) {
        return _idToTokenData[id].requiresSig;
    }
}