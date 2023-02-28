// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./ITokenFactory.sol";

/**
 * This is a TokenContract, which is an ERC721 token.
 * This contract allows users to buy NFT tokens for any ERC20 token and native currency, provided the admin signs off on the necessary data.
 * System admins can update the parameters, as well as pause the purchase
 * All funds for which users buy tokens can be withdrawn by the main owner of the system.
 */
interface ITokenContract {
    /**
     * @notice The structure that stores information about the minted token
     * @param tokenId the ID of the minted token
     * @param mintedTokenPrice the price to be paid by the user
     * @param tokenURI the token URI hash string
     */
    struct MintedTokenInfo {
        uint256 tokenId;
        uint256 mintedTokenPrice;
        string tokenURI;
    }

    /**
     * @notice The structure that stores TokenContract init params
     * @param tokenName the name of the collection (Uses in ERC721 and ERC712)
     * @param tokenSymbol the symbol of the collection (Uses in ERC721)
     * @param tokenFactoryAddr the address of the TokenFactory contract
     * @param pricePerOneToken the price per token in USD
     * @param voucherTokenContract the address of the voucher token contract
     * @param voucherTokensAmount the amount of voucher tokens
     * @param minNFTFloorPrice the minimal NFT floor price in USD for the NFT by NFT option
     */
    struct TokenContractInitParams {
        string tokenName;
        string tokenSymbol;
        address tokenFactoryAddr;
        uint256 pricePerOneToken;
        address voucherTokenContract;
        uint256 voucherTokensAmount;
        uint256 minNFTFloorPrice;
    }

    /**
     * @notice This event is emitted when the TokenContract parameters are updated
     * @param newPrice the new price per token for this collection
     * @param tokenName the new token name
     * @param tokenSymbol the new token symbol
     */
    event TokenContractParamsUpdated(
        uint256 newPrice,
        uint256 newMinNFTFloorPrice,
        string tokenName,
        string tokenSymbol
    );

    /**
     * @notice This event is emitted when the voucher parameters are updated
     * @param newVoucherTokenContract the new voucher token contract address
     * @param newVoucherTokensAmount the new amount of voucher tokens
     */
    event VoucherParamsUpdated(address newVoucherTokenContract, uint256 newVoucherTokensAmount);

    /**
     * @notice This event is emitted when the owner of the contract withdraws the tokens that users have paid for tokens
     * @param tokenAddr the address of the token to be withdrawn
     * @param recipient the address of the recipient
     * @param amount the number of tokens withdrawn
     */
    event PaidTokensWithdrawn(address indexed tokenAddr, address recipient, uint256 amount);

    /**
     * @notice This event is emitted when the user has successfully minted a new token
     * @param recipient the address of the user who received the token and who paid for it
     * @param mintedTokenInfo the MintedTokenInfo struct with information about minted token
     * @param paymentTokenAddress the address of the payment token contract
     * @param paidTokensAmount the amount of tokens paid
     * @param paymentTokenPrice the price in USD of the payment token
     * @param discount discount value applied
     */
    event SuccessfullyMinted(
        address indexed recipient,
        MintedTokenInfo mintedTokenInfo,
        address indexed paymentTokenAddress,
        uint256 paidTokensAmount,
        uint256 paymentTokenPrice,
        uint256 discount
    );

    /**
     * @notice This event is emitted when the user has successfully minted a new token via NFT by NFT option
     * @param recipient the address of the user who received the token and who paid for it
     * @param mintedTokenInfo the MintedTokenInfo struct with information about minted token
     * @param nftAddress the address of the NFT contract paid for the token mint
     * @param tokenId the ID of the token that was paid for the mint
     * @param nftFloorPrice the floor price of the NFT contract
     */
    event SuccessfullyMintedByNFT(
        address indexed recipient,
        MintedTokenInfo mintedTokenInfo,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 nftFloorPrice
    );

    /**
     * @notice The function for initializing contract variables
     * @param initParams_ the TokenContractInitParams structure with init params
     */
    function __TokenContract_init(TokenContractInitParams calldata initParams_) external;

    /**
     * @notice The function for updating token contract parameters
     * @param newPrice_ the new price per one token
     * @param newMinNFTFloorPrice_ the new minimal NFT floor price
     * @param newTokenName_ the new token name
     * @param newTokenSymbol_ the new token symbol
     */
    function updateTokenContractParams(
        uint256 newPrice_,
        uint256 newMinNFTFloorPrice_,
        string memory newTokenName_,
        string memory newTokenSymbol_
    ) external;

    /**
     * @notice The function for updating voucher parameters
     * @param newVoucherTokenContract_ the address of the new voucher token contract
     * @param newVoucherTokensAmount_ the new voucher tokens amount
     */
    function updateVoucherParams(address newVoucherTokenContract_, uint256 newVoucherTokensAmount_)
        external;

    /**
     * @notice The function for updating all TokenContract parameters
     * @param newPrice_ the new price per one token
     * @param newMinNFTFloorPrice_ the new minimal NFT floor price
     * @param newVoucherTokenContract_ the address of the new voucher token contract
     * @param newVoucherTokensAmount_ the new voucher tokens amount
     * @param newTokenName_ the new token name
     * @param newTokenSymbol_ the new token symbol
     */
    function updateAllParams(
        uint256 newPrice_,
        uint256 newMinNFTFloorPrice_,
        address newVoucherTokenContract_,
        uint256 newVoucherTokensAmount_,
        string memory newTokenName_,
        string memory newTokenSymbol_
    ) external;

    /**
     * @notice The function for pausing mint functionality
     */
    function pause() external;

    /**
     * @notice The function for unpausing mint functionality
     */
    function unpause() external;

    /**
     * @notice Function to withdraw the tokens that users paid to buy tokens
     * @dev Pass parameter tokenAddr_ equals to zero to withdraw the native currency
     * @param tokenAddr_ the address of the token to be withdrawn
     * @param recipient_ the address of the recipient
     */
    function withdrawPaidTokens(address tokenAddr_, address recipient_) external;

    /**
     * @param paymentTokenAddress_ the payment token address
     * @param paymentTokenPrice_ the payment token price in USD
     * @param discount_ the discount value
     * @param endTimestamp_ the end time of signature
     * @param tokenURI_ the tokenURI string
     * @param r_ the r parameter of the ECDSA signature
     * @param s_ the s parameter of the ECDSA signature
     * @param v_ the v parameter of the ECDSA signature
     */
    function mintToken(
        address paymentTokenAddress_,
        uint256 paymentTokenPrice_,
        uint256 discount_,
        uint256 endTimestamp_,
        string memory tokenURI_,
        bytes32 r_,
        bytes32 s_,
        uint8 v_
    ) external payable;

    /**
     * @param nftAddress_ the payment NFT token address
     * @param nftFloorPrice_ the floor price of the NFT collection in USD
     * @param tokenId_ the ID of the token with which you will pay for the mint
     * @param endTimestamp_ the end time of signature
     * @param tokenURI_ the tokenURI string
     * @param r_ the r parameter of the ECDSA signature
     * @param s_ the s parameter of the ECDSA signature
     * @param v_ the v parameter of the ECDSA signature
     */
    function mintTokenByNFT(
        address nftAddress_,
        uint256 nftFloorPrice_,
        uint256 tokenId_,
        uint256 endTimestamp_,
        string memory tokenURI_,
        bytes32 r_,
        bytes32 s_,
        uint8 v_
    ) external;

    /**
     * @notice The function that returns the address of the token factory
     * @return token factory address
     */
    function tokenFactory() external view returns (ITokenFactory);

    /**
     * @notice The function that returns the price per one token
     * @return price per one token in USD
     */
    function pricePerOneToken() external view returns (uint256);

    /**
     * @notice The function to check if there is a token with the passed token URI
     * @param tokenURI_ the token URI string to check
     * @return true if passed token URI exists, false otherwise
     */
    function existingTokenURIs(string memory tokenURI_) external view returns (bool);

    /**
     * @notice The function that returns the address of the voucher token contract
     * @return address of the voucher token contract
     */
    function voucherTokenContract() external view returns (address);

    /**
     * @notice The function that returns the amount of voucher tokens needed to mint one token
     * @return amount of voucher tokens
     */
    function voucherTokensAmount() external view returns (uint256);

    /**
     * @notice The function that returns the minimal NFT floor price
     * @return minimal NFT floor price
     */
    function minNFTFloorPrice() external view returns (uint256);

    /**
     * @notice The function to get an array of tokenIDs owned by a particular user
     * @param userAddr_ the address of the user for whom you want to get information
     * @return tokenIDs_ the array of token IDs owned by the user
     */
    function getUserTokenIDs(address userAddr_) external view returns (uint256[] memory tokenIDs_);
}