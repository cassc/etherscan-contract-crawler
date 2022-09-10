// SPDX-License-Identifier: CC0
// Copyright (c) 2022 unReal Accelerator, LLC (https://unrealaccelerator.io)
pragma solidity ^0.8.9;

/// @title: AlphaseekFoundersPass
/// @author: [email protected]

import "erc721a/contracts/extensions/ERC4907A.sol";
import "./crypto/SignatureEvaluator.sol";
import "./crypto/AllowedEvaluator.sol";
import "./utils/AccountLimiter.sol";
import "./interfaces/IClaimable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AlphaseekFoundersPass is
    ERC4907A,
    ERC2981,
    Ownable,
    SignatureEvaluator,
    AllowedEvaluator,
    AccountLimiter,
    IClaimable,
    ReentrancyGuard
{
    /////////  libs
    using Strings for uint256;

    /////////  types

    enum MintPhase {
        paused,
        privateMint,
        waitlistMint,
        publicMint
    }

    /////////  state variables

    // this is a one-shot flag to prevent transfers of the
    // token during the evaluation and testing period of
    // the Alphaseek exchange launch
    bool public isHalted = true;

    // mint pools
    uint256 public constant TOKEN_SUPPLY = 1383;
    uint256 public constant LIMITED_EDITION_TOKENS = 300;
    uint256 public constant PROMOTION_TOKENS = 50;

    // mint controls
    MintPhase public phase = MintPhase.paused;
    bool public preminted;
    uint256 public currentMintPrice = 3.33 ether;
    bool public signatureRequired = true;
    bool public allowListRequired = true;
    bool public walletLimitRequired = true;

    // mapping for tracking minted `connected` address for claims
    mapping(address => uint256) public addressClaimCount;
    uint256 public totalClaimCount;
    uint256 public constant THE_300_CLAIM_MULTIPLIER = 5;

    // metadata URIs
    string public contractURI; // set after deploy
    string public baseTokenURI; // set after deploy
    string public baseExtension = ".json";

    /// recipient of revenues
    address payable public beneficiary;

    // security
    address public administrator;

    /////////  errors

    error CallerIsContract();
    error NotAuthorized();
    error InvalidAddress();
    error PremintRequired();
    error PremintCompleted();
    error MintingPaused();
    error MintPhaseAlreadySet(MintPhase phase);
    error WrongEtherAmount();
    error InsufficentSupply();
    error InvalidSignature();
    error AddressNotListed();
    error WalletLimit();
    error WrongAmount();
    error TokenTransfersHalted();

    /////////  events

    event MintPhaseSet(MintPhase phase);

    /////////  modifiers

    /**
     * @dev Modifier to check that the caller is a user
     */
    modifier callerIsUser() {
        if (tx.origin != _msgSender()) revert CallerIsContract();
        _;
    }

    /**
     * @dev Modifier to check for active sale
     */
    modifier onlyActiveSale() {
        validateActiveSale();
        _;
    }

    /**
     * @dev Modifier to check for Admin or Owner role
     */
    modifier onlyAuthorized() {
        validateAuthorized();
        _;
    }

    /////////  functions

    constructor(
        string memory name,
        string memory symbol,
        address signer,
        address administrator_,
        address payable beneficiary_,
        address royaltyReceiver,
        uint96 feeBasisPoints
    ) ERC721A(name, symbol) SignatureEvaluator(signer) {
        if (administrator_ == address(0)) revert InvalidAddress();
        if (beneficiary_ == address(0)) revert InvalidAddress();
        if (royaltyReceiver == address(0)) revert InvalidAddress();
        administrator = administrator_;
        beneficiary = beneficiary_;
        ERC2981._setDefaultRoyalty(payable(royaltyReceiver), feeBasisPoints);
    }

    /**
     * @dev Fallback functions in case someone sends ETH to the contract
     */
    receive() external payable {}

    fallback() external payable {}

    ///////// External Functions

    /**
     * @dev premint of project tokens
     * @notice this can only be executed once, and must be executed prior to waitlist or public mints
     * @notice these tokens are not eligble for claims
     */
    function premint() external onlyAuthorized {
        if (preminted) revert PremintCompleted();
        AccountLimiter._incrementAccountCount(_msgSender(), PROMOTION_TOKENS);
        preminted = true;
        _mint(_msgSender(), PROMOTION_TOKENS);
    }

    /**
     * @dev mint to an account
     * @notice For each phase of minting, the merkle proof and wallet limits
     * will be updated for the allowed addresses. for public mint, allow list
     * requirement is disabled
     */
    function mint(
        address to,
        uint256 amount,
        string calldata nonce,
        bytes calldata signature,
        bytes32[] calldata merkleProof
    ) external payable callerIsUser onlyActiveSale {
        if (amount <= 0) revert WrongAmount();
        if (currentMintPrice * amount > msg.value) revert WrongEtherAmount();
        if (to == address(0)) revert InvalidAddress();
        if (
            phase == MintPhase.privateMint &&
            totalSupply() + amount > LIMITED_EDITION_TOKENS
        ) revert InsufficentSupply();
        if (totalSupply() + amount > TOKEN_SUPPLY) revert InsufficentSupply();
        // uses the `connected` address
        if (
            signatureRequired &&
            !SignatureEvaluator._validateSignature(
                abi.encodePacked(_msgSender(), nonce, amount),
                signature
            )
        ) revert InvalidSignature();
        // uses the `to` address
        if (
            allowListRequired &&
            !AllowedEvaluator._validateMerkleProof(to, merkleProof)
        ) revert AddressNotListed();
        // uses the `to` address
        if (
            walletLimitRequired &&
            !AccountLimiter._validateAccountCount(to, amount)
        ) revert WalletLimit();
        // increment the count of mints for the `to` address
        AccountLimiter._incrementAccountCount(to, amount);
        // increment the claim count for the `connected` address
        unchecked {
            uint256 claimMultiplier = (phase == MintPhase.privateMint)
                ? THE_300_CLAIM_MULTIPLIER
                : 1;
            uint256 claimAmount = amount * claimMultiplier;
            addressClaimCount[_msgSender()] += claimAmount;
            totalClaimCount += claimAmount;
        }
        _mint(to, amount);
    }

    /**
     * @dev Deactivate all minting
     */
    function setMintingPaused() external onlyAuthorized {
        phase = MintPhase.paused;
        emit MintPhaseSet(phase);
    }

    /**
     * @dev Activate Private minting
     */
    function startPrivateMint(
        bytes32 privateMerkleRoot,
        uint256 walletLimit,
        uint256 mintPrice_
    ) external onlyAuthorized {
        if (phase == MintPhase.privateMint) revert MintPhaseAlreadySet(phase);
        setMintConditions(
            privateMerkleRoot,
            walletLimit,
            mintPrice_,
            MintPhase.privateMint
        );
    }

    /**
     * @dev Activate Waitlist minting
     */
    function startWaitlistMint(
        bytes32 waitlistMerkleRoot,
        uint256 walletLimit,
        uint256 mintPrice_
    ) external onlyAuthorized {
        if (!preminted) revert PremintRequired();
        if (phase == MintPhase.waitlistMint) revert MintPhaseAlreadySet(phase);
        setMintConditions(
            waitlistMerkleRoot,
            walletLimit,
            mintPrice_,
            MintPhase.waitlistMint
        );
    }

    /**
     * @dev Activate Public minting
     */
    function startPublicMint(uint256 walletLimit, uint256 mintPrice_)
        external
        onlyAuthorized
    {
        if (!preminted) revert PremintRequired();
        if (phase == MintPhase.publicMint) revert MintPhaseAlreadySet(phase);
        allowListRequired = false;
        // allow token tranfers and approvals
        isHalted = false;
        setMintConditions(0, walletLimit, mintPrice_, MintPhase.publicMint);
    }

    /**
     * @dev Sets royalty info for market places See {ERC2981-_setDefaultRoyalty}
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyAuthorized
    {
        ERC2981._setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /**
     * @dev Sets the contract uri for marketplaces
     */
    function setContractURI(string calldata contractURI_)
        external
        onlyAuthorized
    {
        contractURI = contractURI_;
    }

    /**
     * @dev Sets the base token uri
     */
    function setBaseTokenURI(string calldata baseTokenURI_)
        external
        onlyAuthorized
    {
        baseTokenURI = baseTokenURI_;
    }

    /**
     * @dev Set the price for minting at any time
     */
    function setMintPrice(uint256 mintPrice_) external onlyAuthorized {
        currentMintPrice = mintPrice_;
    }

    /**
     * @dev Flag to control signature gated minting
     */
    function setSignatureRequired(bool _signatureRequired)
        external
        onlyAuthorized
    {
        signatureRequired = _signatureRequired;
    }

    /**
     * @dev Flag to control wallet limit gated minting
     */
    function setWalletLimitRequired(bool _walletLimitRequired)
        external
        onlyAuthorized
    {
        walletLimitRequired = _walletLimitRequired;
    }

    /**
     * @dev {See AccountLimiter-_setAccountLimitDefault}
     */
    function setWalletLimitDefault(uint256 walletMintLimitDefault_)
        external
        onlyAuthorized
    {
        AccountLimiter._setAccountLimitDefault(walletMintLimitDefault_);
    }

    /**
     * @dev {See AccountLimiter-_setAccountLimit}
     */
    function setWalletLimit(address account, uint256 walletMintLimit_)
        external
        onlyAuthorized
    {
        AccountLimiter._setAccountLimit(account, walletMintLimit_);
    }

    /**
     * @dev Set the merkle root. {See AllowedEvaluator-_setAllowedMerkleRoot}
     * @notice This will only be used if the allowed list needs to be updated
     * without changing the mint phase
     */
    function setMerkleRoot(bytes32 merkleRoot) external onlyAuthorized {
        AllowedEvaluator._setAllowedMerkleRoot(merkleRoot);
    }

    /**
     * @dev Set the signer. {See SignatureEvaluator-_setSigner}
     */
    function setSigner(address _signer) external onlyAuthorized {
        SignatureEvaluator._setSigner(_signer);
    }

    /**
     * @dev Sets the recipient of revenues.
     */
    function setBeneficiary(address payable beneficiary_)
        external
        onlyAuthorized
    {
        beneficiary = beneficiary_;
    }

    /**
     * @dev Sets the administrator address.
     * @notice Only the Owner can set the administrator
     */
    function setAdministrator(address administrator_) external onlyOwner {
        administrator = administrator_;
    }

    ///////// External Functions that are view

    /**
     * @dev {See AccountLimiter-_getAccountLimit}. Useful for web3 interfaces
     */
    function getWalletLimit(address account) external view returns (uint256) {
        return AccountLimiter._getAccountLimit(account);
    }

    /**
     * @dev {See AccountLimiter-_getAccountCount}. Useful for web3 interfaces
     */
    function getWalletCount(address account) external view returns (uint256) {
        return AccountLimiter._getAccountCount(account);
    }

    /**
     * @dev Get the merkle root (for testing). {See AllowedEvaluator-_allowedMerkleRoot}
     */
    function getMerkleRoot() external view returns (bytes32) {
        return AllowedEvaluator._allowedMerkleRoot;
    }

    /**
     * @dev Get the signer (for testing). {See SignatureEvaluator-_getSigner}
     */
    function getSigner() external view returns (address) {
        return SignatureEvaluator._getSigner();
    }

    /**
     * @dev Returns list of token ids owned by address
     */
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](balanceOf(_owner));
        uint256 k = 0;
        for (uint256 i = 1; i <= TOKEN_SUPPLY; i++) {
            if (_exists(i) && _owner == ownerOf(i)) {
                tokenIds[k] = i;
                k++;
            }
        }
        delete k;
        return tokenIds;
    }

    /**
     * @dev Returns list of valid token ids rented by address
     */
    function walletOfUser(address _user)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](balanceOfUser(_user));
        uint256 k = 0;
        for (uint256 i = 1; i <= TOKEN_SUPPLY; i++) {
            if (_exists(i) && _user == userOf(i)) {
                tokenIds[k] = i;
                k++;
            }
        }
        delete k;
        return tokenIds;
    }

    ///////// External Functions that are pure

    ///////// Public functions

    /**
     * @dev Returns the balance of valid tokens rented by an address
     */
    function balanceOfUser(address _user) public view returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 1; i <= TOKEN_SUPPLY; i++) {
            // the user rented this id and is it not expired
            if (_user == userOf(i)) {
                balance++;
            }
        }
        return balance;
    }

    /**
     * @dev Returns the URI to the tokens metadata
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), baseExtension));
    }

    ///////// Internal functions

    /**
     * @dev Internal function to return the base uri for all tokens
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Internal function to set the starting token id
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    ///////// Private functions

    /**
     * @dev Validate authorized addresses
     */
    function validateAuthorized() private view {
        if (_msgSender() != owner() && _msgSender() != administrator)
            revert NotAuthorized();
    }

    /**
     * @dev Validate if the sale is active
     */
    function validateActiveSale() private view {
        if (phase == MintPhase.paused) revert MintingPaused();
    }

    /**
     * @dev common function for updating mint phases
     */
    function setMintConditions(
        bytes32 merkleRoot,
        uint256 walletLimit,
        uint256 mintPrice_,
        MintPhase phase_
    ) private {
        AllowedEvaluator._setAllowedMerkleRoot(merkleRoot);
        AccountLimiter._setAccountLimitDefault(walletLimit);
        currentMintPrice = mintPrice_;
        phase = phase_;
        emit MintPhaseSet(phase);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC4907A, IClaimable)
        returns (bool)
    {
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        // - IERC4907: 0xad092b5c
        // - IClaimable - 0x144d0cd6
        return
            ERC2981.supportsInterface(interfaceId) ||
            ERC721A.supportsInterface(interfaceId) ||
            ERC4907A.supportsInterface(interfaceId) ||
            type(IClaimable).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Release the halt; emergency switch in case public mint is not required
     * @notice there is no way to reset isHalted to true; so this is a one-shot
     */
    function releaseHalt() external onlyAuthorized {
        isHalted = false;
    }

    /**
     * @dev Halt token transfers during initial mint phases
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, tokenId, 1);
        // if halting is enforced, prevent token transfers
        if (isHalted) {
            // so that we can still mint during a Halt
            // only prevent transfers for existing token ids
            if (_exists(tokenId)) revert TokenTransfersHalted();
        }
    }

    /**
     * @dev Halt token approvals during initial mint phases
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        super.setApprovalForAll(operator, approved);
        if (isHalted) revert TokenTransfersHalted();
    }

    /**
     * @dev Halt token approvals during initial mint phases
     */
    function approve(address to, uint256 tokenId) public virtual override {
        super.approve(to, tokenId);
        if (isHalted) revert TokenTransfersHalted();
    }

    function withdraw() external payable onlyAuthorized {
        (bool success, ) = payable(beneficiary).call{
            value: address(this).balance
        }("");
        require(success);
    }
}