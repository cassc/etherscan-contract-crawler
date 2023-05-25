// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { ERC1155 } from "@rari-capital/solmate/src/tokens/ERC1155.sol";

import { Signable } from "../generic/Signable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

import { Errors } from "../generic/Errors.sol";
import { Helpers } from "../Helpers.sol";
import { Types } from "../Types.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title InspiredByLedger
 */
contract InspiredByLedger is ERC1155, Signable, IERC2981, AccessControl {
    event FeaturesEnabled(Feature[] features);
    event FeatureStatusChanged(Feature features, bool status);
    event DefaultMaxSupplyChanged(uint256 defaultMaxSupply);
    event MaxSupplyPerTokenChanged(uint256[] tokenIds, uint256[] maxSupplies);
    event SeasonUpdated(uint16 seasonId);
    event ETHMintPricePerTokenChanged(uint256[] tokenIds, uint256[] prices);
    event TokenURIChanged(uint256 tokenId, string tokenURI);
    event TokenTypesChanged(address[] tokens, TokenType[] tokenTypes);
    event TokenDeadlinesChanged(uint256[] tokenIds, uint256[][] deadlines);
    event ContractURIChanged(string contractUri);
    event DefaultMaxMintChanged(uint256 defaultMaxMint);
    event MaxMintPerTokenChanged(uint256[] tokenIds, uint256[] maxMints);
    event DefaultRoyaltyReceiverChanged(address defaultRoyaltyReceiver);
    event RoyaltiesInfoUpdated(
        uint256 tokenId,
        address royaltyReceiver,
        uint256 percentage
    );
    event TipReceived(address indexed sender, uint256 amount);
    event TokenInitialized(
        uint256 tokenId,
        uint256 maxSupply,
        uint256 maxMintPerToken,
        uint256 mintPrice,
        address withdrawalAddress,
        address royaltyReceiver,
        uint256 royaltiesPercentage,
        string tokenURI,
        uint256[2] deadlines
    );
    event WithdrawalAddressesChanged(
        uint256 tokenId,
        address withdrawalAddress
    );

    event DefaultWithdrawalAddressChanged(address defaultWithdrawalAddress);

    enum Feature {
        MINTER_CAN_MINT,
        ETH_WITH_SIGN,
        ETH_PUBLIC
    }

    enum TokenType {
        NONE,
        INFINITY,
        GENESIS
    }

    /*//////////////////////////////-////////////////////////////////
                            Storage
    ////////////////////////////////-//////////////////////////////*/
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public name;
    string public symbol;

    // Addresses where money from the contract will go if the owner of the contract will call withdrawAll function
    address public defaultWithdrawalAddress;

    //Addresses where money for specific the contract will go if the owner of the token will call withdraw function
    mapping(uint256 => address) public withdrawalAddresses;

    // Bit mapping of active features
    uint256 private featureEnabledBitMap;

    // Base contract URI
    string private baseContractURI;

    // Token URIs
    mapping(uint256 => string) private tokenURIs;

    /// @notice Mint prices, can be configured
    /// @return supply per specified token
    mapping(uint256 => uint256) public mintPrices;

    /// @notice Default max supply for token if not specified.
    /// @return default max supply
    uint256 public defaultMaxSupply = 100000;

    /// @notice Max supply per token
    mapping(uint256 => uint256) private maxSupplyPerToken;

    /// @notice Current supply per token
    /// @return supply per specified token
    mapping(uint256 => uint256) public currentSupplyPerToken;

    /// @notice Number of already minted tokens per account
    /// @return mapping
    mapping(address => mapping(uint256 => uint256)) public minted;

    /// @notice SeasonId for which signature will be valid for private sales. If seasonId is changed all signatures will be invalid and new ones should be generated
    uint16 public seasonId;

    /// @notice Token type per token
    mapping(address => TokenType) public tokenTypes;

    /// @notice Token deadlines
    mapping(uint256 => uint256[]) public tokenDeadlines;

    /// @notice Default max mint for an account on the public sale if specific mint for token is not specified.
    /// @return default number of mints
    uint256 public defaultMaxMint = 1000;

    /// @notice Max mint amounts, can be configured
    /// @return list of tokens with their's max amounts
    mapping(uint256 => uint256) public maxMintPerToken;

    /// @notice Used TokenGated Ids
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => bool))))
        public usedInfinityPasses;

    /// @notice Used TokenGated Ids within a season
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))))
        public usedGenesisPasses;

    mapping(uint256 => address) public royaltiesReceivers;
    address public defaultRoyaltyReceiver;

    // Base is 10000, 1000 = 10%
    mapping(uint256 => uint256) private royaltiesPercentage;

    //keeps track how much funds needs to be send to token owner
    mapping(uint256 => uint256) public tokenEscrow;
    //keeps track for total allocation for token owners. This is used to calculate how much funds in excess the contract has and could to be send to contract owner
    uint256 public tips;

    /*//////////////////////////////-////////////////////////////////
                                Modifiers
    ////////////////////////////////-//////////////////////////////*/

    // Modifier is used to check if the feature rule is met
    modifier featureRequired(Feature feature_) {
        if (!isFeatureEnabled(feature_)) revert Errors.MintNotAvailable();
        _;
    }

    // Modifier is used to check if the signature is still valid
    modifier onlyWithinDeadline(uint256[] calldata deadlines) {
        for (uint256 i; i < deadlines.length; ) {
            if (block.timestamp > deadlines[i]) {
                revert Errors.MintDeadlinePassed();
            }
            unchecked {
                ++i;
            }
        }

        _;
    }

    /**
     * @notice Checks the validity of a given token based on its deadlines.
     * @param tokenId The ID of the token to check validity for.
     * @dev This function reverts with an error message if the deadlines have not been set for the token or if the current block timestamp falls outside the token's specified deadlines.
     */
    function checkTokenValidity(uint256 tokenId) internal view {
        uint256[] memory deadlines = tokenDeadlines[tokenId];
        if (deadlines.length == 0) {
            revert Errors.DeadlineNotSet();
        }

        if (
            block.timestamp < tokenDeadlines[tokenId][0] ||
            block.timestamp > tokenDeadlines[tokenId][1]
        ) {
            revert Errors.TokenSaleClosed(tokenId);
        }
    }

    function onlyMatchingLengths(uint256 a, uint256 b) internal pure {
        if (a != b) revert Errors.MismatchLengths();
    }

    /**
     * @notice Initialize the contract. Call once upon deploy.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _baseContractURI The base URI used for generating contract-level metadata URI.
     * @param _defaultRoyaltyReceiver This will be the default royalty receiver for all tokens if not set explicitly.
     * @param _defaultWithdrawalAddress Default withdrawal address for the contract.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseContractURI,
        address _defaultRoyaltyReceiver,
        address _defaultWithdrawalAddress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        name = _name;
        symbol = _symbol;
        baseContractURI = _baseContractURI;
        defaultRoyaltyReceiver = _defaultRoyaltyReceiver;
        defaultWithdrawalAddress = _defaultWithdrawalAddress;
    }

    /**
     * @dev The Ether received will be logged with {TipReceived} events.
     */
    receive() external payable virtual {
        tips += msg.value;
        emit TipReceived(msg.sender, msg.value);
    }

    fallback() external payable virtual {
        tips += msg.value;
        emit TipReceived(msg.sender, msg.value);
    }

    /*//////////////////////////////-////////////////////////////////
                            External functions
    ////////////////////////////////-//////////////////////////////*/

    /**
     * @notice Account with a MINTER_ROLE can call this function to mint `amounts` of specified tokens into account with the address `to`
     * @param to Address on which tokens will be minted
     * @param tokenId The ID of the token to mint
     * @param amount The amount of the token to mint
     * @param data Tokens
     */
    function minterMint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) featureRequired(Feature.MINTER_CAN_MINT) {
        _mintLogic(to, tokenId, amount, data, false);
    }

    /**
     * @notice Mint function used with signature. Must be executed by an account with a MINTER_ROLE.
     * @dev This function mints the given tokens for the msg.sender, after verifying the signature for each mint request.
     * @param args An array of TokenGatedMintArgs struct, which represents the tokens to be minted and the pass required to mint them.
     * @param signatures An array of bytes, which represents the signature for each TokenGatedMintArgs struct.
     * @param deadlines An array of uint256, which represents the deadline timestamp for each signature.
     */
    function minterMintSign(
        Types.TokenGatedMintArgs[] calldata args,
        bytes[] calldata signatures,
        uint256[] calldata deadlines,
        bytes calldata data
    )
        external
        onlyRole(MINTER_ROLE)
        featureRequired(Feature.MINTER_CAN_MINT)
        featureRequired(Feature.ETH_WITH_SIGN)
        onlyWithinDeadline(deadlines)
    {
        _mintSignLogic(args, signatures, deadlines, data);
    }

    /**
     * @notice Function used to do minting (with signature). Contract feature `ETH_PUBLIC` must be enabled
     * @param tokenId The ID of the token to mint
     * @param amount The amount of the token to mint
     * @param data data
     */
    function mint(
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) external payable featureRequired(Feature.ETH_PUBLIC) {
        checkTokenValidity(tokenId);

        uint256 totalPrice = priceETH(tokenId, amount);

        if (msg.value < totalPrice) {
            revert Errors.InsufficientFunds();
        }

        tokenEscrow[tokenId] += totalPrice;

        if (msg.value > totalPrice) {
            tips += msg.value - totalPrice;
        }

        _mintLogic(msg.sender, tokenId, amount, data, false);
    }

    /**
     * @notice Mint function used with signature.
     * @dev This function mints the given tokens for the msg.sender, after verifying the signature for each mint request.
     * @param args An array of TokenGatedMintArgs struct, which represents the tokens to be minted and the pass required to mint them.
     * @param signatures An array of bytes, which represents the signature for each TokenGatedMintArgs struct.
     * @param deadlines An array of uint256, which represents the deadline timestamp for each signature.
     */
    function mintSign(
        Types.TokenGatedMintArgs[] calldata args,
        bytes[] calldata signatures,
        uint256[] calldata deadlines,
        bytes calldata data
    )
        external
        payable
        featureRequired(Feature.ETH_WITH_SIGN)
        onlyWithinDeadline(deadlines)
    {
        Types.TokenGatedMintArgs[] memory tmpArgs = args;
        uint256 totalCost = 0;

        for (uint256 i; i < tmpArgs.length; ) {
            uint256 currentPrice = priceETH(
                tmpArgs[i].tokenId,
                tmpArgs[i].amount
            );
            tokenEscrow[tmpArgs[i].tokenId] += currentPrice;
            totalCost += currentPrice;

            unchecked {
                ++i;
            }
        }

        if (msg.value < totalCost) revert Errors.InsufficientFunds();

        if (msg.value > totalCost) {
            tips += msg.value - totalCost;
        }

        _mintSignLogic(args, signatures, deadlines, data);
    }

    /**
     * @notice Burn specified amount of a given token ID from the specified token owner address
     * @param tokenId The ID of the token to burn
     * @param amount The amount of the token to burn
     * @param tokenOwner The address of the token owner whose tokens will be burned
     * @dev Only callable by an account with the BURNER_ROLE
     * @dev If the specified token owner does not have a sufficient balance of the given token to burn, this function will revert with an InsufficientBalance error
     * @dev Decreases the token owner's balance of the given token by the specified amount and decreases the current supply of the given token by the same amount
     */
    function burn(
        uint256 tokenId,
        uint256 amount,
        address tokenOwner
    ) external onlyRole(BURNER_ROLE) {
        if (balanceOf[tokenOwner][tokenId] < amount) {
            revert Errors.InsufficientBalance();
        }

        super._burn(tokenOwner, tokenId, amount);

        unchecked {
            minted[tokenOwner][tokenId] -= amount;
            currentSupplyPerToken[tokenId] -= amount;
        }
    }

    /**
     * @notice Contract owner can call this function to withdraw all ETH in excess (all per-token allocations remain intact) from the contract into a defined wallet
     */
    function withdrawAll() external onlyOwner {
        uint256 balance = tips;
        if (tips == 0) revert Errors.NothingToWithdraw();
        tips = 0;
        (defaultWithdrawalAddress.call{ value: balance }(""));
    }

    /**
     * @notice Owner of the token can call this function to withdraw all allocated ETH per this token
     * @param tokenId The ID of the token to burn
     */
    function withdrawPerToken(uint256 tokenId) external {
        if (msg.sender != withdrawalAddresses[tokenId])
            revert Errors.NotAuthorized();

        uint256 balance = tokenEscrow[tokenId];
        if (balance == 0) revert Errors.NothingToWithdraw();

        tokenEscrow[tokenId] = 0;

        (withdrawalAddresses[tokenId].call{ value: balance }(""));
    }

    /*//////////////////////////////-////////////////////////////////
                                Setters
    ////////////////////////////////-//////////////////////////////*/
    /**
     * @notice Init all necessary configuration per token
     * @param tokenId_ The ID of the token to initialize
     * @param maxSupply_ The maximum supply of the token
     * @param maxMintPerToken_ The maximum amount of tokens that can be minted per account
     * @param mintPrice_ The price of the token
     * @param withdrawalAddresses_ The address of the withdrawal wallet for the token
     * @param royaltyReceiver_ The address of the royalty receiver
     * @param royaltiesPercentage_ The percentage of royalties to be paid
     * @param tokenURI_ The URI of the token
     * @param deadlines_ An array of uint256, which represents the start and end timestamps for the token. Can be 0 based. Start cannot be greater than the end.
     */
    function initializeToken(
        uint256 tokenId_,
        uint256 maxSupply_,
        uint256 maxMintPerToken_,
        uint256 mintPrice_,
        address withdrawalAddresses_,
        address royaltyReceiver_,
        uint256 royaltiesPercentage_,
        string memory tokenURI_,
        uint256[2] memory deadlines_
    ) external onlyOwner {
        //in case we want to initialize with no certain dates yet, we should skip this check
        if (deadlines_[0] > deadlines_[1]) {
            revert Errors.InvalidDeadlines();
        }

        if (royaltiesPercentage_ > 10000) {
            revert Errors.RoyaltiesPercentageTooHigh();
        }

        maxSupplyPerToken[tokenId_] = maxSupply_;
        maxMintPerToken[tokenId_] = maxMintPerToken_;
        mintPrices[tokenId_] = mintPrice_;
        withdrawalAddresses[tokenId_] = withdrawalAddresses_;
        royaltiesReceivers[tokenId_] = royaltyReceiver_;
        royaltiesPercentage[tokenId_] = royaltiesPercentage_;
        tokenURIs[tokenId_] = tokenURI_;
        tokenDeadlines[tokenId_] = deadlines_;

        emit TokenInitialized(
            tokenId_,
            maxSupply_,
            maxMintPerToken_,
            mintPrice_,
            withdrawalAddresses_,
            royaltyReceiver_,
            royaltiesPercentage_,
            tokenURI_,
            deadlines_
        );
    }

    /**
     * @notice Set the enabled features for the contract
     * @param features An array of Feature enum values representing the features to be enabled
     * @dev Sets the featureEnabledBitMap variable to a bit map with the features that are enabled. Each bit position in the bit map corresponds to a Feature enum value, with a bit value of 1 indicating that the feature is enabled and 0 indicating that it is disabled.This function can only be called by the owner of the contract.
     */
    function setEnabledFeatures(Feature[] memory features) external onlyOwner {
        uint256 featuresBitMap = 0;
        for (uint256 i = 0; i < features.length; i++) {
            uint256 featureIndex = uint256(features[i]);
            featuresBitMap = featuresBitMap | (1 << featureIndex);
        }
        featureEnabledBitMap = featuresBitMap;
        emit FeaturesEnabled(features);
    }

    /**
     * @notice Sets the status of a particular feature
     * @param feature The feature to set the status for
     * @param status The desired status for the feature
     * If status is true, the feature will be enabled, otherwise it will be disabled.
     */
    function setFeatureStatus(Feature feature, bool status) external onlyOwner {
        uint256 featureIndex = uint256(feature);
        if (status == true) {
            featureEnabledBitMap = featureEnabledBitMap | (1 << featureIndex);
        } else {
            featureEnabledBitMap = featureEnabledBitMap & ~(1 << featureIndex);
        }

        emit FeatureStatusChanged(feature, status);
    }

    /**
     * @notice Set max supply specified token.
     * @param tokenIds_ Token Ids
     * @param maxSupplies_ Supplies of corresponding tokens by indexes
     */
    function setMaxSupplyPerToken(
        uint256[] calldata tokenIds_,
        uint256[] calldata maxSupplies_
    ) external onlyOwner {
        onlyMatchingLengths(tokenIds_.length, maxSupplies_.length);

        for (uint256 i; i < tokenIds_.length; ) {
            maxSupplyPerToken[tokenIds_[i]] = maxSupplies_[i];
            unchecked {
                i++;
            }
        }

        emit MaxSupplyPerTokenChanged(tokenIds_, maxSupplies_);
    }

    /**
     * @notice Increment season.
     * @dev When season is incremented, all issued signatures become invalid.
     */
    function updateSeason() external onlyOwner {
        ++seasonId;
        emit SeasonUpdated(seasonId);
    }

    /**
     * @notice Set mint prices for specified tokens. Override default mint price for specified tokens
     * @param tokenIds_ Token Ids
     * @param mintPrices_ Prices of corresponding tokens by indexes
     */
    function setETHMintPricePerToken(
        uint256[] calldata tokenIds_,
        uint256[] calldata mintPrices_
    ) external onlyOwner {
        onlyMatchingLengths(tokenIds_.length, mintPrices_.length);

        for (uint256 i; i < tokenIds_.length; ) {
            mintPrices[tokenIds_[i]] = mintPrices_[i];
            unchecked {
                i++;
            }
        }

        emit ETHMintPricePerTokenChanged(tokenIds_, mintPrices_);
    }

    /**
     * @notice Sets a new URI for all token types, by relying on the token type ID
     * @param tokenId_ tokenId for which uri to be set
     * @param uri_ Used as the URI for token type
     */
    function setTokenURI(
        uint256 tokenId_,
        string calldata uri_
    ) external onlyOwner {
        if (bytes(uri_).length == 0) {
            revert Errors.InvalidBaseURI();
        }
        tokenURIs[tokenId_] = uri_;

        emit TokenURIChanged(tokenId_, uri_);
    }

    /**
     * @notice Set token type
     * @param addresses_ array of token addresses
     * @param types_ types of token passes
     * @dev set infinity or genesis
     */
    function setTokenTypes(
        address[] calldata addresses_,
        TokenType[] calldata types_
    ) external onlyOwner {
        onlyMatchingLengths(addresses_.length, types_.length);
        for (uint256 i; i < addresses_.length; ) {
            tokenTypes[addresses_[i]] = types_[i];
            unchecked {
                i++;
            }
        }

        emit TokenTypesChanged(addresses_, types_);
    }

    /**
     * @notice Set token deadline
     * @param tokenIds_ token address
     * @param deadlines_ token address
     * @dev set infinity or genesis
     */
    function setTokenDeadlines(
        uint256[] calldata tokenIds_,
        uint256[][] calldata deadlines_
    ) external onlyOwner {
        onlyMatchingLengths(tokenIds_.length, deadlines_.length);

        for (uint256 i; i < tokenIds_.length; ) {
            if (deadlines_[i].length != 2) {
                revert Errors.InvalidDeadlineLength();
            }

            tokenDeadlines[tokenIds_[i]] = deadlines_[i];
            unchecked {
                i++;
            }
        }

        emit TokenDeadlinesChanged(tokenIds_, deadlines_);
    }

    /**
     * @notice Set contract URI
     * @param baseContractURI_ Base contract URI
     */
    function setContractURI(
        string calldata baseContractURI_
    ) external onlyOwner {
        if (bytes(baseContractURI_).length == 0)
            revert Errors.InvalidBaseContractURL();

        baseContractURI = baseContractURI_;
        emit ContractURIChanged(baseContractURI_);
    }

    /**
     * @notice Set default max mint amount for all tokens
     * @param defaultMaxMint_ default max mint amount
     */
    function setDefaultMaxMint(uint256 defaultMaxMint_) external onlyOwner {
        defaultMaxMint = defaultMaxMint_;
        emit DefaultMaxMintChanged(defaultMaxMint_);
    }

    /**
     * @notice Set max supply specified token.
     * @param tokenIds_ Token Ids
     * @param maxMints_ Max mints of corresponding tokens by indexes
     */
    function setMaxMintPerToken(
        uint256[] calldata tokenIds_,
        uint256[] calldata maxMints_
    ) external onlyOwner {
        onlyMatchingLengths(tokenIds_.length, maxMints_.length);

        for (uint256 i; i < tokenIds_.length; ) {
            maxMintPerToken[tokenIds_[i]] = maxMints_[i];
            unchecked {
                i++;
            }
        }

        emit MaxMintPerTokenChanged(tokenIds_, maxMints_);
    }

    /**
     * @notice Set default max supply
     * @param defaultMaxSupply_ default max supply amount
     */
    function setDefaultMaxSupply(uint256 defaultMaxSupply_) external onlyOwner {
        defaultMaxSupply = defaultMaxSupply_;
        emit DefaultMaxSupplyChanged(defaultMaxSupply_);
    }

    function setDefaultRoyaltyReceiver(
        address defaultRoyaltyReceiver_
    ) external onlyOwner {
        defaultRoyaltyReceiver = defaultRoyaltyReceiver_;
        emit DefaultRoyaltyReceiverChanged(defaultRoyaltyReceiver_);
    }

    /**
     * @notice Sets the royalties information for a given token.
     * @param tokenId The ID of the token to set royalties percentage for.
     * @param royaltyReceiver_ The address to which royalties will be sent.
     * @param royaltiesPercentage_ The new royalties percentage for the token.
     * @dev This function can only be called by the owner of the contract. If the provided royalties percentage is greater than 10000, this function will revert with an error message. Otherwise, it sets the new royalties percentage for the token and emits a `RoyaltiesPercentageChanged` event.
     */
    function setRoyaltiesInfo(
        uint256 tokenId,
        address royaltyReceiver_,
        uint256 royaltiesPercentage_
    ) external onlyOwner {
        if (royaltiesPercentage_ > 10000) {
            revert Errors.RoyaltiesPercentageTooHigh();
        }

        royaltiesPercentage[tokenId] = royaltiesPercentage_;
        royaltiesReceivers[tokenId] = royaltyReceiver_;

        emit RoyaltiesInfoUpdated(
            tokenId,
            royaltyReceiver_,
            royaltiesPercentage_
        );
    }

    /**
     * @notice Sets the default withdrawal address for the contract
     * @param defaultWithdrawalAddress_ The new default withdrawal address which can call `withdrawAll`
     * @dev Only the contract owner is authorized to call this function
     */
    function setDefaultWithdrawalAddress(
        address defaultWithdrawalAddress_
    ) external onlyOwner {
        defaultWithdrawalAddress = defaultWithdrawalAddress_;
        emit DefaultWithdrawalAddressChanged(defaultWithdrawalAddress_);
    }

    /**
     * @notice Sets the withdrawal address for a specific token
     * @param tokenId The ID of the token to set the withdrawal address for
     * @param withdrawalAddress_ The new withdrawal address to be set for the specified token
     * @dev Only the contract owner is authorized to call this function
     */
    function setWithdrawalAddressPerToken(
        uint256 tokenId,
        address withdrawalAddress_
    ) external onlyOwner {
        withdrawalAddresses[tokenId] = withdrawalAddress_;
        emit WithdrawalAddressesChanged(tokenId, withdrawalAddress_);
    }

    /*//////////////////////////////-////////////////////////////////
                                Getters
    ////////////////////////////////-//////////////////////////////*/

    /**
     * @notice Return contract URI
     * @return Contract URI
     */
    function contractURI() external view returns (string memory) {
        return baseContractURI;
    }

    /**
     * @notice Calculate total price of specified tokens depends on their's amounts
     * @param tokenIds List of tokens
     * @param amounts Amounts of corresponding tokens by indexes
     * @return totalPrice Total price
     */
    function totalPriceETH(
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) public view returns (uint totalPrice) {
        for (uint i; i < tokenIds.length; ) {
            totalPrice += priceETH(tokenIds[i], amounts[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Get price of specified token depends on it's amount
     * @param tokenId Token
     * @param amount Amounts of token
     * @return Token Price
     */
    function priceETH(
        uint256 tokenId,
        uint256 amount
    ) public view returns (uint256) {
        return mintPrices[tokenId] * amount;
    }

    function isFeatureEnabled(Feature feature) public view returns (bool) {
        return (featureEnabledBitMap & (1 << uint256(feature))) != 0;
    }

    function uri(
        uint256 tokenId_
    ) public view override returns (string memory) {
        return tokenURIs[tokenId_];
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155, AccessControl, IERC165)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    /**
     * @dev See IERC2981
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        receiver = royaltiesReceivers[tokenId] != address(0)
            ? royaltiesReceivers[tokenId]
            : defaultRoyaltyReceiver;

        return (receiver, (salePrice * royaltiesPercentage[tokenId]) / 10000);
    }

    /**
     * @notice Maximum mint per token
     * @param tokenId, Token
     * @return Max mint amount per token
     */
    function getMaxMintPerToken(uint256 tokenId) public view returns (uint256) {
        return
            maxMintPerToken[tokenId] > 0
                ? maxMintPerToken[tokenId]
                : defaultMaxMint;
    }

    /**
     * @notice Maximum supply per token
     * @param tokenId, Token
     * @return Max supply per token
     */
    function getMaxSupplyPerToken(
        uint256 tokenId
    ) public view returns (uint256) {
        return
            maxSupplyPerToken[tokenId] > 0
                ? maxSupplyPerToken[tokenId]
                : defaultMaxSupply;
    }

    /*//////////////////////////////-////////////////////////////////
                            Private functions
    ////////////////////////////////-//////////////////////////////*/

    function _mintSignLogic(
        Types.TokenGatedMintArgs[] calldata args,
        bytes[] calldata signatures,
        uint256[] calldata deadlines,
        bytes calldata data
    ) private {
        Types.TokenGatedMintArgs[] memory tmpArgsArr = args;
        uint256[] memory tmpDeadlines = deadlines;
        bytes[] memory tmpSignatures = signatures;
        bytes memory tmpData = data;

        onlyMatchingLengths(tmpArgsArr.length, tmpSignatures.length);
        onlyMatchingLengths(tmpSignatures.length, tmpDeadlines.length);

        for (uint i = 0; i < tmpArgsArr.length; ) {
            if (
                tokenTypes[tmpArgsArr[i].pass] != TokenType.GENESIS &&
                tokenTypes[tmpArgsArr[i].pass] != TokenType.INFINITY
            ) {
                revert Errors.TokenNotSupported();
            }

            Types.TokenGatedMintArgs memory tmpArgs = tmpArgsArr[i];

            checkTokenValidity(tmpArgs.tokenId);

            if (
                !Helpers._verify(
                    signer(),
                    Helpers._hash(tmpArgs, tmpDeadlines[i], seasonId),
                    tmpSignatures[i]
                )
            ) revert Errors.InvalidSignature();

            if (tokenTypes[tmpArgs.pass] == TokenType.GENESIS) {
                _processGenesisPass(
                    tmpArgs.pass,
                    tmpArgs.tokenGatedId,
                    tmpArgs.tokenId
                );
            } else {
                _processInfinityPass(tmpArgs.pass, tmpArgs.tokenGatedId);
            }

            _mintLogic(
                msg.sender,
                tmpArgs.tokenId,
                tmpArgs.amount,
                tmpData,
                true
            );

            unchecked {
                ++i;
            }
        }
    }

    function _processGenesisPass(
        address pass,
        uint256 tokenGatedId,
        uint256 tokenId
    ) private {
        if (usedGenesisPasses[pass][tokenGatedId][seasonId][tokenId]) {
            revert Errors.TokenGatedIdAlreadyUsed(tokenGatedId);
        }

        usedGenesisPasses[pass][tokenGatedId][seasonId][tokenId] = true;
    }

    function _processInfinityPass(address pass, uint256 tokenGatedId) private {
        if (usedInfinityPasses[pass][tokenGatedId][msg.sender][seasonId]) {
            revert Errors.TokenGatedIdAlreadyUsedInSeason(
                tokenGatedId,
                seasonId
            );
        }
        usedInfinityPasses[pass][tokenGatedId][msg.sender][seasonId] = true;
    }

    function _mintLogic(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data,
        bool isTokenGated
    ) private {
        if (
            currentSupplyPerToken[tokenId] + amount >
            getMaxSupplyPerToken(tokenId)
        ) {
            revert Errors.SupplyLimitReached();
        }

        if (
            !isTokenGated &&
            minted[to][tokenId] + amount > getMaxMintPerToken(tokenId)
        ) {
            revert Errors.AccountAlreadyMintedMax();
        }

        minted[to][tokenId] += amount;
        currentSupplyPerToken[tokenId] += amount;

        super._mint(to, tokenId, amount, data);
    }
}