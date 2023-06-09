// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "src/utils/PaymentSplitter.sol";

interface ICRFTDERC721A {
    /**
     * @dev Emitted when the `baseTokenURI` is set.
     * @param fromBaseURI The current base URI of the collection.
     * @param toBaseURI The updated base URI of the collection.
     */
    event BaseTokenURIUpdated(string fromBaseURI, string toBaseURI);

    /**
     * @dev Emitted when the metadata is frozen (e.g.: `baseTokenURI` and `maxSupply` can no longer be changed).
     * @param baseURI      The base URI of the collection.
     * @param maxSupply    The maxSupply of the collection.
     */
    event MetadataFrozen(string baseURI, uint176 maxSupply);

    /**
     * @dev Emitted when the `operatorFilteringEnabled` is set.
     * @param operatorFilteringEnabled_ The boolean value.
     */
    event OperatorFilteringEnabledSet(bool operatorFilteringEnabled_);

    /**
     * @dev Emitted when the `publicSaleEnabled` is set.
     * @param publicSaleEnabled_ The boolean value.
     */
    event PublicSaleEnabledSet(bool publicSaleEnabled_);

    /**
     * @dev Emitted when the `mintPaused` is set.
     * @param mintPauseEnabled_ The boolean value.
     */
    event MintPauseEnabledSet(bool mintPauseEnabled_);

    /**
     * @dev Emitted when the token `tokenRoyalty` is set.
     * @param tokenId The uint256 value.
     * @param receiver The address of royalty receiver.
     * @param bps The new royalty, measured in basis points.
     */
    event TokenRoyaltySet(uint256 tokenId, address receiver, uint96 bps);

    /**
     * @dev Emitted upon a mint.
     * @param to          The address to mint to.
     * @param value       The total value in `ETH` for mint.
     * @param quantity    The number of minted.
     * @param fromTokenId The first token ID minted.
     */
    event Minted(address to, uint256 value, uint256 quantity, uint256 fromTokenId);

    /**
     * @dev Emitted upon an airdrop.
     * @param to          The recipients of the airdrop.
     * @param quantity    The number of tokens airdropped to each address in `to`.
     * @param fromTokenId The first token ID minted to the first address in `to`.
     */
    event Airdropped(address[] to, uint64[] quantity, uint256 fromTokenId);

    /**
     * @dev Emitted when the token `maxSupply` updates.
     * @param supply  The maxSupply of the collection.
     */
    event MaxSupplySet(uint128 supply);

    /**
     * @dev Emitted when the `revunueSplit` updates.
     * @param payee  The payee of the collection.
     */
    event RevenueSplitUpdated(PaymentSplitter.Payees[] payee);

    /**
     * @dev Emitted when the `phaseSetting` updates.
     *
     * @param index         The index of phase.
     * @param price         The new price for the phase.
     * @param maxSupply     The new max supply for the phase.
     * @param maxPerWallet  The new max per wallet for the phase.
     * @param isActive      The new active setting for the phase.
     * @param root          The new merkle root for the phase.
     *
     */
    event PhaseSettingUpdate(
        uint256 index, uint128 price, uint128 maxSupply, uint64 maxPerWallet, uint64 isActive, bytes32 root
    );

    /**
     * @dev Emitted when the added new `phase`.
     * @param phases The phases of the collection
     */
    event PhaseAdded(PhaseSetting[] phases);

    /**
     * @dev Emitted when the `phase` is set.
     * @param index The index of the phases.
     * @param status The boolean value.
     */
    event PhaseStatusSet(uint256[] index, bool[] status);

    /**
     * @dev Emitted upon initialization.
     * @param name_                    Name of the collection.
     * @param symbol_                  Symbol of the collection.
     * @param baseURI_                 Base URI.
     * @param payees_                  Payees of the collection.
     * @param phase_                   PhaseSetting of the collection.
     * @param initData                 The encoded data of the abi.encodePacked(uint128(price), uint128(maxSupply), uint64(maxPerWallet), address(owner), address(royaltyRecevicer), uint16(flag), uint16(feeNumerator)).
     */
    event CRFTDCollectionInitialized(
        string name_,
        string symbol_,
        string baseURI_,
        PaymentSplitter.Payees[] payees_,
        PhaseSetting[] phase_,
        bytes initData
    );

    /**
     * @dev Emitted when the `phase` is set.
     * @param quantity The max quantity of per wallet.
     */
    event MaxPerWalletSet(uint64 quantity);

    /**
     * @dev Emitted when the public sale price is set.
     * @param price_ The price of mint token.
     */
    event SalePriceSet(uint128 price_);

    /**
     * @dev The contract has already initialized.
     */
    error AlreadyInitialized();

    /**
     * @dev The given merkle proof is invalid.
     */
    error InvalidProof();

    /**
     * @dev The `maxSupply` has reached.
     */
    error MaxMinted();

    /**
     * @dev The given value is incorrect.
     */
    error IncorrectValue();

    /**
     * @dev The given value greater than max bps.
     */
    error ExceedMaxBPS();

    /**
     * @dev The token is not burnable.
     */
    error BurnNotAllowed();

    /**
     * The action is not allowed.
     */
    error NotAllowed();

    /**
     * @dev The wallet reached their max limit.
     */
    error ExceedsLimit();

    /**
     * @dev The token has already revealed.
     */
    error AlreadyReveal();

    /**
     * @dev The token mint is paused.
     */
    error MintPaused();

    /**
     * @dev The given phase is inactive for the mint.
     */
    error InactivePhase();

    /**
     * @dev The public sale of token has not started yet.
     */
    error PublicSaleNotStarted();

    /**
     * @dev The metadata of token is frozen and cannot be changed.
     */
    error MetadataIsFrozen();

    /**
     * @dev The revenue split is frozen and cannot be changed.
     */
    error RevenueSplitIsFrozen();

    /**
     * @dev The mint `quantity` cannot exceed `BATCH_MINT_LIMIT` tokens.
     */
    error ExceedsBatchMintLimit();

    /**
     * @dev When given array length are not same.
     */
    error ArrayLengthMismatch();

    /**
     * @dev Token is soul-bound and cannot be transferred.
     */
    error SoulBoundToken();

    struct PhaseSetting {
        /// @dev price for per mint
        uint128 price;
        /// @dev phase supply
        uint128 maxSupply;
        /// @dev tracks the minted supply
        uint128 mintedSupply;
        /// @dev wallet max mint per wallet (0 for unlimited mint)
        uint64 maxPerWallet;
        /// @dev whether the phase is active
        uint64 isActive;
        /// @dev root for whitelist ( if applicable, otherwise bytes32(0))
        bytes32 merkleRoot;
    }

    /**
     * @dev Emitted upon initialization.
     * @param name_                    Name of the collection.
     * @param symbol_                  Symbol of the collection.
     * @param tokenURI_                Base URI.
     * @param payee_                   Payee of the collection.
     * @param phases_                  PhaseSetting of the collection.
     * @param initData_                The encoded data of the abi.encodePacked(uint128(price), uint128(maxSupply), uint64(maxPerWallet), address(owner), address(royaltyRecevicer), uint16(flag), uint16(feeNumerator)).
     *
     */
    function init(
        string memory name_,
        string memory symbol_,
        string memory tokenURI_,
        PaymentSplitter.Payees[] memory payee_,
        PhaseSetting[] memory phases_,
        bytes memory initData_
    ) external;

    /**
     * @dev Mints `quantity` tokens to addrress `to`
     *      Each token will be assigned a token ID that is consecutively increasing.
     * @param index       Index of mint phase.
     * @param quantity    Number of tokens to mint.
     * @param proof       Proofs of merkleroot if whitelist is enabled else empty
     */
    function mintPhase(uint256 index, uint64 quantity, bytes32[] calldata proof) external payable;

    /**
     * @dev Mints `quantity` tokens to each of the addresses in `to`.
     *
     * @param to           Array of Address to mint.
     * @param quantity     Array of quantity of tokens to mint.
     *
     * Note: only callable by contract owner.
     */
    function airdrop(address[] calldata to, uint64[] calldata quantity) external payable;

    /**
     * @dev Mints the specified quantity of tokens for the caller.
     *
     * @param quantity     Number of tokens to mint.
     */
    function publicMint(uint64 quantity) external payable;

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     *
     * Note: Only callable if `burnFlag` is enabled else will revert.
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev Sets whether OpenSea operator filtering is enabled.
     *
     * @param operatorFilteringEnabled_ The boolean value.
     * Note: Only callable by contract owner.
     */
    function setOperatorFilteringEnabled(bool operatorFilteringEnabled_) external;

    /**
     * @dev Sets the base URI for the token metadata.
     *
     * @param baseURI   The base URI to set.
     * Note: Only callable by contract owner when metadata is not frozen.
     */
    function setBaseURI(string memory baseURI) external;

    /**
     * @dev Sets public mint sale status to the specified value.
     *
     * @param status    The boolean value.
     *
     * Note: Only callable by contract owner.
     */
    function setPublicSaleStatus(bool status) external;

    /**
     * @dev Sets mint pause status to the specified value.
     *
     * @param status    The boolean value.
     *
     * Note: Only callable by contract owner.
     */
    function setMintPause(bool status) external;

    /**
     * @dev Freezes the metadata for the tokens, preventing further updates.
     *
     * Note: Only callable by contract owner.
     */
    function freezeMetadata() external;

    /**
     * @dev Freezes the revenue split for the token sales, preventing further updates.
     *
     * Note: Only callable by contract owner.
     */
    function freezeRevenueSplit() external;

    /**
     * @dev Sets mint sale price and max per wallet to the specified value.
     *
     * @param price_            The new price to mint token.
     * @param maxPerWallet_     The new max limit for the one address.
     *
     * Note: Only callable by owner.
     */
    function setPublicSaleSetting(uint128 price_, uint64 maxPerWallet_) external;

    /**
     * @dev Sets the maximum supply of the tokens to the specified value.
     *
     * @param supply    The new maximum supply.
     *
     * Note: Only able to decrease max supply when metadata is not frozen.
     *       Only callable by owner.
     */
    function setMaxSupply(uint128 supply) external;

    /**
     * @dev Sets the maximum number of tokens that can be owned by a single wallet.
     *
     * @param number The new maximum number of tokens per wallet
     */
    // function setMaxPerWallet(uint64 number) external;

    /**
     * @dev Sets royalty amount in bps (basis points).
     *
     * @param receiver  The receiver address of the royalty.
     * @param bps       The new royalty basis points to be set.
     *
     * Note: Only callable by owner.
     */
    function setRoyalty(address receiver, uint16 bps) external;

    /**
     * @dev Sets the revealed token URI for the tokens;
     *
     * @param uri   The new baseURI of the collection.
     *
     * Note: Only callable by owner.
     */
    function revealTokenURI(string memory uri) external;

    /**
     * @dev Adds new phases for the token sale.
     *
     * @param _phase    An array of `PhaseSetting` struct.
     *
     * Note: Only callble by owner.
     */
    function addPhases(PhaseSetting[] calldata _phase) external;

    /**
     * @dev Sets the settings for a specific phase of the token sale.
     *
     * @param index          The index of phase.
     * @param price_         The new price for the phase.
     * @param maxSupply_     The new max supply for the phase.
     * @param maxPerWallet_  The new max per wallet for the phase.
     * @param isActive_      The new active setting for the phase.
     * @param root_          The new merkle root for the phase.
     *
     * Note: Only callable by owner.
     *
     */
    function setPhaseSettings(
        uint256 index,
        uint128 price_,
        uint128 maxSupply_,
        uint64 maxPerWallet_,
        uint64 isActive_,
        bytes32 root_
    ) external;

    /**
     * @dev Sets the phase status of the token sale.
     *
     * @param indexs    An array of the index of the phase.
     * @param status    An array of boolean values for the phase.
     *
     * Note: Only callable by owner.
     */
    function setPhaseStatus(uint256[] calldata indexs, bool[] calldata status) external;

    /**
     * @dev Changes the revenue split among the specified payees.
     *
     * @param payee An array of `Payees` struct.
     *
     * Note: Only callable by owner.
     */
    function changeRevenueSplit(PaymentSplitter.Payees[] memory payee) external;

    /**
     * @dev Returns the recipient and amount of royalty to be paid (ERC-2981).
     *
     * @param salePrice         The sale price of the token.
     * @return recipient_        The address of the royalty recipient.
     * @return royaltyAmount_   The amount of royalty to be paid.
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address recipient_, uint256 royaltyAmount_);

    /**
     * @dev Returns the locking status of an Soulbound Token (ERC-5192).
     *
     * @param tokenId   The ID of the token to check.
     * @return status   A boolean value.
     */
    function locked(uint256 tokenId) external view returns (bool status);

    /**
     * @dev Checks whether the revenue split settings have been frozen.
     *
     * @return status   A boolean value.
     */
    function isRevenueSplitFrozen() external view returns (bool status);

    /**
     * @dev Checks whether the metadata have been frozen.
     *
     * @return status   A boolean value.
     */
    function isMetadataFrozen() external view returns (bool status);

    /**
     * @dev Checks whether minting is currently paused.
     *
     * @return status   A boolean value.
     */
    function isMintPaused() external view returns (bool status);

    /**
     * @dev Checks whether token is burnable.
     *
     * @return status   A boolean value.
     */
    function isBurnable() external view returns (bool status);

    /**
     * @dev Checks whether the tokens are currently in the pre-reveal.
     *
     * @return status   A boolean value.
     */
    function isPreReveal() external view returns (bool status);

    /**
     * @dev Checks whether the public sale has started.
     *
     * @return status   A boolean value.
     */
    function isPublicSaleStart() external view returns (bool status);

    /**
     * @dev Checks whether OpenSea operator filtering is enabled.
     *
     * @return status   A boolean value.
     */
    function isOperatorFiltering() external view returns (bool status);

    /**
     * @dev Returns the address of the CRFTD Wallet contract instance.
     *
     * @return The address of wallet.
     */
    // function CRFTD_WALLET() external pure returns (address);

    /**
     * @dev Returns the flat fee in wei that is charged per mint.
     *
     * @return The flat fee in wei.
     */
    // function FLAT_FEE() external pure returns (uint64);

    /**
     * @dev Returns the percentage fee in bps that is charged per mint if price is greater than 0.05 ETH.
     *
     * @return The fee percentage in bps.
     */
    // function FEE_PERCENTAGE() external pure returns (uint16);
}