// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./ERC1155Base.sol";

/**
 * @author Fount Gallery
 * @title  Mornings Open Editions by Gutty Kreum
 * @notice Mornings is a collection of digital memories exploring morning ambience by pixel artist, Gutty Kreum.
 *         A limited release in collaboration with Fount Gallery, Mornings drops on June 22, 2023.
 *
 * Features:
 *   - Open edition NFTs
 *   - ERC-1155 lazy minting
 *   - Flexible minting conditions with EIP-712 signatures or on-chain Fount Card checks
 *   - Swappable metadata contract
 *   - On-chain royalties standard (EIP-2981)
 *   - Support for OpenSea's Operator Filterer to allow royalties
 */
contract MorningsOpenEditions is ERC1155Base {
    /* ------------------------------------------------------------------------
       S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev Stores information about a given token
    struct TokenData {
        uint128 price;
        uint32 startTime;
        uint32 endTime;
        uint256 gutty_reserve_collected;
        uint256 fount_reserve_collected;
        uint16 perAddressAllowance;
        bool fountExclusive;
        bool requiresSig;
    }

    /// @dev Mapping of token id to token data
    mapping(uint256 => TokenData) internal _idToTokenData;

    /// @dev Check if the artist has minted the batch of 25 prior to launch
    bool public _artistBatchMinted = false;

    /// @notice The amount of tokens reserved for Fount Gallery Patrons
    uint256 public constant FOUNT_PATRON_RESERVE = 100;

    /// @notice The amount of tokens reserved for Gutty Kreum artwork holders
    uint256 public constant GUTTY_KREUM_RESERVE = 225;

    /* ------------------------------------------------------------------------
       M O D I F I E R S
    ------------------------------------------------------------------------ */

    /**
     * @dev Reverts if the caller is not the artist
     */
    modifier onlyArtist() {
        require(msg.sender == artist, "Only the artist can call this function");
        _;
    }

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
    error SoldOut();
    error BatchAlreadyMinted();

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
     * @notice Mints a batch of 25 editions to the artist's wallet
     *
     * Reverts if:
     * - the batch has already been minted
     */
    function mintArtistBatch() external onlyArtist {
        if (_artistBatchMinted) revert BatchAlreadyMinted();

        TokenData memory tokenData = _idToTokenData[3];
        tokenData.gutty_reserve_collected += 25;
        _idToTokenData[3] = tokenData;

        _artistBatchMinted = true;
        _mintToArtistFirst(artist, 3, 25);
        emit CollectedOpenEdition(3);
    }

    /**
     * @notice Mints a number of editions from an open edition NFT
     * @dev Calls internal `_collectEdition` for logic.
     *
     * Reverts if:
     *  - the edition requires an off-chain signature
     *  - see `_collectEdition` for other conditions
     *
     * @param id The id of the edition
     * @param amount_guttys The amount of editions to mint from the Gutty Kreum reserve
     * @param amount_founts The amount of editions to mint from the Fount Gallery Patron Card reserve
     * @param to The address to mint the token to
     */
    function collectEdition(
        uint256 id,
        uint256 amount_guttys,
        uint256 amount_founts,
        address to
    ) external payable {
        TokenData memory tokenData = _idToTokenData[id];
        if (tokenData.requiresSig) revert RequiresSignature();
        _collectEdition(id, amount_guttys, amount_founts, to, tokenData);
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
     * @param amount_guttys The amount of editions to mint from the Gutty Kreum reserve
     * @param amount_founts The amount of editions to mint from the Fount Gallery Patron Card reserve
     * @param to The address to mint the token to
     * @param signature The off-chain signature which permits a mint
     */
    function collectEdition(
        uint256 id,
        uint256 amount_guttys,
        uint256 amount_founts,
        address to,
        bytes calldata signature
    ) external payable {
        TokenData memory tokenData = _idToTokenData[id];
        if (
            tokenData.requiresSig &&
            !_verifyMintSignature(id, amount_guttys, amount_founts, to, signature)
        ) {
            revert InvalidSignature();
        }
        _collectEdition(id, amount_guttys, amount_founts, to, tokenData);
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
     * @param amount_guttys The amount of editions to mint from the Gutty Kreum reserve
     * @param amount_founts The amount of editions to mint from the Fount Gallery Patron Card reserve
     * @param to The address to mint the token to
     * @param tokenData Information about the token
     */
    function _collectEdition(
        uint256 id,
        uint256 amount_guttys,
        uint256 amount_founts,
        address to,
        TokenData memory tokenData
    ) internal {
        uint256 trueGuttysToMintAmount;
        uint256 trueFountsToMintAmount;

        // Check to see if the edition is mintable and the price is correct
        if (tokenData.startTime > block.timestamp) revert OpenEditionNotStartedYet();
        if (tokenData.endTime > 0 && block.timestamp > tokenData.endTime) revert OpenEditionEnded();
        if (msg.value > 0) revert IncorrectPaymentAmount();

        // Check if it's a Fount Gallery exclusive
        if (tokenData.fountExclusive && !_isFountCardHolder(to)) revert RequiresFountCard();

        // Check to see if the mint amounts exceed the reserves
        if (
            GUTTY_KREUM_RESERVE <= tokenData.gutty_reserve_collected &&
            FOUNT_PATRON_RESERVE <= tokenData.fount_reserve_collected
        ) revert SoldOut();

        // If the amount of tokens to mint will exceed the Fount Patron Reserve, only mint the remaining amount
        // eg. 98/100 tokens minted, 5 tokens requested, only 2 tokens will be minted
        if (amount_founts > FOUNT_PATRON_RESERVE - tokenData.fount_reserve_collected) {
            trueFountsToMintAmount = FOUNT_PATRON_RESERVE - tokenData.fount_reserve_collected;
        } else {
            trueFountsToMintAmount = amount_founts;
        }

        // If the amount of tokens to mint will exceed the Gutty Kreum artwork holder Reserve, only mint the remaining amount
        // eg. 223/225 tokens minted, 5 tokens requested, only 2 tokens will be minted
        if (amount_guttys > GUTTY_KREUM_RESERVE - tokenData.gutty_reserve_collected) {
            trueGuttysToMintAmount = GUTTY_KREUM_RESERVE - tokenData.gutty_reserve_collected;
        } else {
            trueGuttysToMintAmount = amount_guttys;
        }

        // Add the new mint to the token data
        unchecked {
            tokenData.gutty_reserve_collected += trueGuttysToMintAmount;
            tokenData.fount_reserve_collected += trueFountsToMintAmount;
        }
        _idToTokenData[id] = tokenData;

        // Calculate the total amount of tokens to mint
        uint256 mintAmount = uint256(trueGuttysToMintAmount) + uint256(trueFountsToMintAmount);

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

    function tokenGuttyReserveCollectedCount(uint256 id) external view returns (uint256) {
        return _idToTokenData[id].gutty_reserve_collected;
    }

    function tokenFountReserveCollectedCount(uint256 id) external view returns (uint256) {
        return _idToTokenData[id].fount_reserve_collected;
    }

    function tokenAllowancePerAddress(uint256 id) external view returns (uint256) {
        return _idToTokenData[id].perAddressAllowance;
    }

    function tokenRemainingAllowanceForAddress(
        uint256 id,
        address account
    ) external view returns (uint256) {
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