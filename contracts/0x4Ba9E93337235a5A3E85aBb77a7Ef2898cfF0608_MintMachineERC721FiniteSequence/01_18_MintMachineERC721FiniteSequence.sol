// SPDX-License-Identifier: MIT
// Copyright (c) 2021 Benjamin Bryant LLC
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./extensions/FiniteTokenSequence.sol";
import "./libraries/SignatureVerification.sol";

/**
 * @title MintMachine ERC-721 Contract, Finite Sequence (v0.1.2)
 * @author bhbryant.eth
 * @custom:url https://www.mintmachine.xyz
 * @dev This contract provides for:
 *
 *  - Sequential minting of a finite sequence of ERC-721 tokens
 *  - Restrictions on the number of tokens per transaction
 *  - Fixed pricing per token
 *  - Restricted minting with custom token counts and pricing
 *    through an external signature
 *  - Direct minting to address by Owner
 *  - Disabling / Pausing minting
 *  - A settable baseURI used for building the token metadata URI
 *  - Freezing of baseURI to permanately fix token metadata URI
 *  - A settable contractURI endpoing
 *  - Events for tracking state change and signed mints
 *  - Fund withdawal by Owner
 *
 *  - It inherits ECR-721 Enumberable extension
 *
 *   Contract template by bhbryant.eth
 *
 *   https://github.com/mintmachine-xyz/mint-machine-erc721
 *
 *   Manage your own drop at https://www.mintmachine.xyz
 **/
contract MintMachineERC721FiniteSequence is
    ERC721,
    ERC721Enumerable,
    FiniteTokenSequence,
    Ownable,
    ReentrancyGuard
{
    /**
     * @dev Controls minting state
     * PAUSED - No sales allowed
     * PRIVATE - Signed mints only (eg. pre-sales or server managed sales)
     * PUBLIC - unrestricted minting (signed mints still work)
     */
    enum ContractState {
        PAUSED,
        PRIVATE,
        PUBLIC
    }

    /**********************************************
     * Events
     **********************************************/

    /**
     * @dev provide feedback on mint key used for signed mints
     */
    event MintKeyClaimed(
        address indexed claimer,
        address indexed mintKey,
        uint256 tokenCount
    );

    /**
     * @dev provides feedback on contract state changes
     */
    event StateChanged(ContractState newState);

    /**********************************************
     * Instance Variables
     **********************************************/

    /**
     * @dev indicates that the contract base uri is fozen
     * prevents metadata from being changed
     */
    bool internal _freezeURI = false;

    /**
     * @dev Contract Metadata URI, see {https://docs.opensea.io/docs/contract-level-metadata}.
     */
    string internal _contractURI;

    /**
     * @dev Key(address) mapping to a claimed key.
     * Used to prevent address from rebroadcasting mint transactions
     */
    mapping(address => bool) private _claimedMintKeys;

    /**
     * @dev The maximum number of tokens that can be minted per public transaction
     * Zero means unlimited
     */
    uint256 private _maximumPublicTokensPerTransaction;

    /**
     * @dev default price for public (unsigned) mint
     */
    uint256 private _publicMintPrice;

    /**
     * @dev State of the contract
     */
    ContractState private _state = ContractState.PAUSED;

    /**
     * @dev Metadata Base URI, used for referencing metadata
     */
    string private _uri;

    /**
     * @dev public address used to sign function calls parameters
     */
    address private _verificationAddress;

    /**********************************************
     * Constructor
     **********************************************/

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     * @param name_ Name of contract
     * @param symbol_ Symbol for Contract
     * @param maximumSupply_ Maximum number of tokens
     * @param publicMintPrice_ Price per token
     * @param maximumPublicTokensPerTransaction_ Maximum mintable tokens per transaction
     * @param verificationAddress_ Recovery address used to verify signature
     * @param baseURI_ Base URI used for building token metadata URI
     * @param contractURI_ Contract metadata URI
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maximumSupply_,
        uint256 publicMintPrice_,
        uint256 maximumPublicTokensPerTransaction_,
        address verificationAddress_,
        string memory baseURI_,
        string memory contractURI_
    ) ERC721(name_, symbol_) FiniteTokenSequence(maximumSupply_) {
        _publicMintPrice = publicMintPrice_;
        _maximumPublicTokensPerTransaction = maximumPublicTokensPerTransaction_;
        _verificationAddress = verificationAddress_;
        _uri = baseURI_;
        _contractURI = contractURI_;
    }

    /**********************************************
     * Public Mint functions
     **********************************************/

    /**
     * @dev Public mint contract.
     *      Requires:
     *          1. contract to have active public sale state
     *          2. tokenCount to be less than per transaction maximum, unless maximum is zero
     *          3. token count to not exceed available supply
     *          4. ETH payment to match minting price
     *
     * @param tokenCount Number of tokens to mint
     */
    function mint(uint256 tokenCount) external payable nonReentrant {
        // contract state
        require(_state == ContractState.PUBLIC, "public minting is disabled");

        // tokenCount, zero and available supply resrictions handled by _mintInSequenceToAddress
        require(
            _maximumPublicTokensPerTransaction == 0 ||
                tokenCount <= _maximumPublicTokensPerTransaction,
            "tokenCount exceeds per transaction limit"
        );

        // payable
        require(
            _publicMintPrice * tokenCount == msg.value,
            "payable does match require amount"
        ); // checked block, overflow raised by Solidity > 0.8.0

        _mintInSequenceToAddress(msg.sender, tokenCount);
    }

    /**
     * @dev Private mint contract.
     *      Requires:
     *          1. contract to have active sale state (private or public sale)
     *          2. ETH payment to match minting price
     *          3. nonce is new (> last used)
     *          4. parameters match signature
     *
     * @param tokenCount Number of tokens to mint
     * @param valueInWei Total payable value of mint
     * @param mintKey Unique identifier for this transaction
     * @param signature Signature used to validate mint params
     */
    function mintWithSignature(
        uint256 tokenCount,
        uint256 valueInWei,
        address mintKey,
        bytes memory signature
    ) external payable nonReentrant {
        // contract state
        require(
            _state == ContractState.PRIVATE || _state == ContractState.PUBLIC,
            "minting is disabled"
        );

        // tokenCount, > zero and < available supply handled by_mintInSequenceToAddress

        // payable
        require(valueInWei == msg.value, "payable does match require amount");

        // verify fresh nonce
        require(_claimedMintKeys[mintKey] == false, "mintKey already claimed");

        // Verify signature
        require(
            _verificationAddress != address(0),
            "verification address not set"
        );

        SignatureVerification.requireValidSignature(
            abi.encodePacked(msg.sender, tokenCount, valueInWei, mintKey, this),
            signature,
            _verificationAddress
        );

        // claim mint key
        _claimedMintKeys[mintKey] = true;

        // mint
        _mintInSequenceToAddress(msg.sender, tokenCount);

        emit MintKeyClaimed(msg.sender, mintKey, tokenCount);
    }

    /**
     * @dev Owner restricted mint function
     * @param destination The address to send tokens to
     * @param tokenCount The number of tokens to mint
     */
    function mintToAddress(address destination, uint256 tokenCount)
        external
        onlyOwner
    {
        // _mintInSequenceToAddress enforces tokenCount and available supply
        // _mintInSequenceToAddress uses _safeMint

        _mintInSequenceToAddress(destination, tokenCount);
    }

    /**********************************************
     * Config -- restricted to owner
     **********************************************/

    /**
     * @dev freezes the contract
     * this is a onetime change to contract state that cannot be reverted
     */
    function freezeBaseURI() external onlyOwner {
        require(!_freezeURI, "baseURI is frozen");

        _freezeURI = true;
    }

    /**
     * @dev set baseURI for metadata
     * @param uri Base URI for meta data. Must include trailing "/"
     *
     * When calling tokenURI the returned format will be `${baseUri}${tokenId}`.
     */
    function setBaseURI(string memory uri) external onlyOwner {
        require(!_freezeURI, "baseURI is frozen");

        _uri = uri;
    }

    /**
     * @dev set contractURI for metadata
     * @param uri Contract URI for contract metadata.
     */
    function setContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
    }

    /**
     * @dev sets the maximum number of tokens that can be minted using the public mint transaction
     * zero means no limit
     * @param maximumPublicTokensPerTransaction_ Maximum number of tokens per transaction
     */
    function setMaximumPublicTokensPerTransaction(
        uint256 maximumPublicTokensPerTransaction_
    ) external onlyOwner {
        _maximumPublicTokensPerTransaction = maximumPublicTokensPerTransaction_;
    }

    /**
     * @dev sets the price per token for public sale
     * @param publicMintPrice_ Mint price
     */
    function setPublicMintPrice(uint256 publicMintPrice_) external onlyOwner {
        _publicMintPrice = publicMintPrice_;
    }

    /**
     * @dev sets contract state
     * @param state New Contract state (PAUSED, PRIVATE, PUBLIC)
     */
    function setState(ContractState state) external onlyOwner {
        _state = state;

        emit StateChanged(state);
    }

    /**
     * @dev sets the address used for verifying the signature on private sale mints
     * @param verificationAddress_ Verifcation address
     */
    function setVerificationAddress(address verificationAddress_)
        external
        onlyOwner
    {
        _verificationAddress = verificationAddress_;
    }

    /**********************************************
     * Payment Management -- restricted to owner
     **********************************************/

    /**
     * @dev transfers full balance of contract to contract owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**********************************************
     * Public Accessors
     **********************************************/

    /**
     * @dev returns the total tokens available
     */
    function availableSupply() external view returns (uint256) {
        return _availableSupply();
    }

    /**
     * @dev View only resource for metadata base uri
     */
    function baseURI() external view returns (string memory) {
        if (bytes(_baseURI()).length == 0) {
            return "";
        }
        return _baseURI();
    }

    /**
     * @dev View only resource for contract level metadata uri
     * See {https://docs.opensea.io/docs/contract-level-metadata}.
     */
    function contractURI() external view returns (string memory) {
        if (bytes(_contractURI).length == 0) {
            return "";
        }

        return _contractURI;
    }

    /**
     * @dev returns contract state
     */
    function getState() external view returns (ContractState) {
        return _state;
    }

    /**
     * @dev return state of mint key
     * @param mintKey Key(address) to look up
     */
    function isClaimed(address mintKey) external view returns (bool) {
        return _claimedMintKeys[mintKey];
    }

    /**
     * @dev return true if contact frozen
     */
    function isBaseURIFrozen() external view returns (bool) {
        return _freezeURI;
    }

    /**
     * @dev returns the maximum number of tokens that can be minted in a single public transaction
     */
    function maximumPublicTokensPerTransaction()
        external
        view
        returns (uint256)
    {
        return _maximumPublicTokensPerTransaction;
    }

    /**
     * @dev returns the cost per token for a public transaction
     */
    function publicMintPrice() external view returns (uint256) {
        return _publicMintPrice;
    }

    /**********************************************
     * Overrides
     **********************************************/

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev map _uri param to _baseURI used by erc271 metadata stuff
     */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }
}