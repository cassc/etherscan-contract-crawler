// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721A} from "erc721a/ERC721A.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";

import {IDelegationRegistry} from "./IDelegationRegistry.sol";

// Errors
error InvalidSaleState();
error InvalidSignature();
error AllowlistExceeded();
error InsufficientPayment();
error WalletLimitExceeded();
error InvalidNewSupply();
error SupplyExceeded();
error TokenIsLocked(uint256 tokenId);
error BurnNotOpen();
error EtherNFTNotSet();
error InvalidDelegate();
error WithdrawFailed();

// Interface for EtherNFT contract
interface IEtherNFT {
    function redeem(address to, uint256 tokenId, uint256 lockupExpiration) external;
}

/**
 * @title EtherCapsule
 * @author cygaar <@0xCygaar>
 */
contract EtherCapsule is OperatorFilterer, Ownable, ERC2981, ERC721A {
    using ECDSA for bytes32;

    enum SaleStates {
        CLOSED,
        ALLOWLIST,
        PUBLIC
    }

    // Number of NFTs users can mint in the public sale
    uint256 public constant PUBLIC_MINTS_PER_WALLET = 3;

    // The lockup period for NFTs minted through the free allowlist
    uint256 public constant LOCKUP_PERIOD = 10 weeks;

    // Price for the allowlist mint
    uint256 public allowlistPrice = 0.35 ether;

    // Price for the public mint
    uint256 public publicPrice = 0.65 ether;

    // Total supply of the collection
    uint256 public maxSupply = 10000;

    // Address that signs messages used for minting
    address public mintSigner;

    // Current sale state
    SaleStates public saleState;

    // Whether operator filtering is enabled
    bool public operatorFilteringEnabled;

    // Whether capsules can be burned and redeemed for EtherNFTs
    bool public burnOpen;

    // EtherNFT contract which capsules can be redeemed for
    IEtherNFT public etherNFT;

    // Delegate Cash registry that will be read from for capsule burning
    IDelegationRegistry public constant DELEGATE_REGISTRY =
        IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    // Mapping of token ids to lockup expirations
    mapping(uint256 => uint256) public tokenLockups;

    // Base metadata uri
    string private _baseTokenURI;

    constructor(string memory name, string memory symbol, address _signer, address _royaltyReceiver)
        ERC721A(name, symbol)
    {
        // Set mint signer
        mintSigner = _signer;

        // Setup marketplace operator filtering
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // 5% royalties
        _setDefaultRoyalty(_royaltyReceiver, 500);
    }

    // =========================================================================
    //                              Minting Logic
    // =========================================================================

    /**
     * Free allowlist mint function. Users opting for this method will have a 10 week lockup period.
     * @param to Address that will receive the NFTs
     * @param qty Number of NFTs to mint
     * @param mintLimit Max number of NFTs the user can mint
     * @param signature Signature generated from the backend
     */
    function freeAllowlistMint(address to, uint8 qty, uint8 mintLimit, bytes calldata signature) external {
        if (saleState != SaleStates.ALLOWLIST) revert InvalidSaleState();
        if (_totalMinted() + qty > maxSupply) revert SupplyExceeded();

        // Validate signature
        bytes32 hashVal = keccak256(abi.encodePacked(msg.sender, mintLimit, saleState));
        bytes32 signedHash = hashVal.toEthSignedMessageHash();
        if (signedHash.recover(signature) != mintSigner) revert InvalidSignature();

        // Validate that user still has allowlist spots
        uint64 alMintCount = _getAux(msg.sender) + qty;
        if (alMintCount > mintLimit) revert AllowlistExceeded();

        // Update allowlist used count
        _setAux(msg.sender, alMintCount);

        // Set lockup period for all token ids minted
        uint256 tokenId = _nextTokenId();
        unchecked {
            uint256 lockExpiration = block.timestamp + LOCKUP_PERIOD;
            for (uint256 i; i < qty; ++i) {
                tokenLockups[tokenId + i] = lockExpiration;
            }
        }

        // Mint tokens
        _mint(to, qty);
    }

    /**
     * Paid allowlist mint function. There is no lockup period for tokens minted through this method.
     * @param to Address that will receive the NFTs
     * @param qty Number of NFTs to mint
     * @param mintLimit Max number of NFTs the user can mint
     * @param signature Signature generated from the backend
     */
    function paidAllowlistMint(address to, uint8 qty, uint8 mintLimit, bytes calldata signature) external payable {
        if (saleState != SaleStates.ALLOWLIST) revert InvalidSaleState();
        if (_totalMinted() + qty > maxSupply) revert SupplyExceeded();
        if (msg.value < allowlistPrice * qty) revert InsufficientPayment();

        // Validate signature
        bytes32 hashVal = keccak256(abi.encodePacked(msg.sender, mintLimit, saleState));
        bytes32 signedHash = hashVal.toEthSignedMessageHash();
        if (signedHash.recover(signature) != mintSigner) revert InvalidSignature();

        // Validate that user still has allowlist spots
        uint64 alMintCount = _getAux(msg.sender) + qty;
        if (alMintCount > mintLimit) revert AllowlistExceeded();

        // Update allowlist used count
        _setAux(msg.sender, alMintCount);

        // Mint tokens
        _mint(to, qty);
    }

    /**
     * Public mint function.
     * @param to Address that will receive the NFTs
     * @param qty Number of NFTs to mint
     * @param signature Signature generated from the backend
     */
    function publicMint(address to, uint256 qty, bytes calldata signature) external payable {
        if (saleState != SaleStates.PUBLIC) revert InvalidSaleState();
        if (msg.value < publicPrice * qty) revert InsufficientPayment();
        if (_totalMinted() + qty > maxSupply) revert SupplyExceeded();

        // Determine number of public mints by substracting AL mints from total mints
        if (_numberMinted(msg.sender) - _getAux(msg.sender) + qty > PUBLIC_MINTS_PER_WALLET) {
            revert WalletLimitExceeded();
        }

        // Validate signature
        bytes32 hashVal = keccak256(abi.encodePacked(msg.sender, saleState));
        bytes32 signedHash = hashVal.toEthSignedMessageHash();
        if (signedHash.recover(signature) != mintSigner) revert InvalidSignature();

        // Mint tokens
        _mint(to, qty);
    }

    /**
     * Owner-only mint function. Used to mint the team treasury.
     * @param to Address that will receive the NFTs
     * @param qty Number of NFTs to mint
     */
    function ownerMint(address to, uint256 qty) external onlyOwner {
        if (_totalMinted() + qty > maxSupply) revert SupplyExceeded();
        _mint(to, qty);
    }

    /**
     * Owner-only function to adjust the lockup period for a given token.
     * @param tokenId Token Id to set the lockup period for
     * @param expiration The new lockup expiration
     */
    function setTokenLockup(uint256 tokenId, uint256 expiration) external onlyOwner {
        tokenLockups[tokenId] = expiration;
    }

    /**
     * View function to get number of allowlist mints a user has done.
     * @param user Address to check
     */
    function allowlistMintCount(address user) external view returns (uint64) {
        return _getAux(user);
    }

    /**
     * View function to get number of total mints a user has done.
     * @param user Address to check
     */
    function totalMintCount(address user) external view returns (uint256) {
        return _numberMinted(user);
    }

    // =========================================================================
    //                             Mint Settings
    // =========================================================================

    /**
     * Owner-only function to set the current sale state.
     * @param _saleState New sale state
     */
    function setSaleState(SaleStates _saleState) external onlyOwner {
        saleState = _saleState;
    }

    /**
     * Owner-only function to set the mint prices.
     * @param _allowlistPrice New paid allowlist mint price
     * @param _publicPrice New public mint price
     */
    function setPrices(uint256 _allowlistPrice, uint256 _publicPrice) external onlyOwner {
        allowlistPrice = _allowlistPrice;
        publicPrice = _publicPrice;
    }

    /**
     * Owner-only function to set the mint signer.
     * @param _signer New mint signer
     */
    function setMintSigner(address _signer) external onlyOwner {
        mintSigner = _signer;
    }

    /**
     * Owner-only function to set the collection supply. This value can only be decreased.
     * @param _maxSupply The new supply count
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply >= maxSupply) revert InvalidNewSupply();
        maxSupply = _maxSupply;
    }

    /**
     * Owner-only function to withdraw funds in the contract to a destination address.
     * @param receiver Destination address to receive funds
     */
    function withdrawFunds(address receiver) external onlyOwner {
        (bool sent,) = receiver.call{value: address(this).balance}("");
        if (!sent) {
            revert WithdrawFailed();
        }
    }

    // =========================================================================
    //                              Burning Logic
    // =========================================================================

    /**
     * Function to burn capsules for EtherNFTs. The msg.sender must own all tokens
     * or have an approval on them. Token lockups will be carried over.
     * @param to Address that will receive the EtherNFTs
     * @param tokenIds List of tokenIds to burn
     */
    function burnCapsules(address to, uint256[] calldata tokenIds) external {
        if (!burnOpen) revert BurnNotOpen();
        if (address(etherNFT) == address(0)) revert EtherNFTNotSet();

        for (uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            // Validate ownership or approval before burning
            _burn(tokenId, true);

            // Mint new EtherNFT
            etherNFT.redeem(to, tokenId, tokenLockups[tokenId]);

            // Remove token lockup value
            delete tokenLockups[tokenId];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * Function to burn capsules for EtherNFTs using a delegated wallet. The msg.sender must be
     * delegated to act on behalf of the owner of the given tokens. Token lockups will be carried over.
     * @param to Address that will receive the EtherNFTs
     * @param tokenIds List of tokenIds to burn
     */
    function burnCapsulesWithDelegate(address to, uint256[] calldata tokenIds) external {
        if (!burnOpen) revert BurnNotOpen();
        if (address(etherNFT) == address(0)) revert EtherNFTNotSet();

        for (uint256 i; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];

            // Validate that msg.sender is the delegated wallet for the tokenId owner
            bool isDelegateValid =
                DELEGATE_REGISTRY.checkDelegateForToken(msg.sender, ownerOf(tokenId), address(this), tokenId);
            if (!isDelegateValid) revert InvalidDelegate();

            // Burn without validating ownership because we validated the delegate wallet
            _burn(tokenId, false);

            // Mint new EtherNFT
            etherNFT.redeem(to, tokenId, tokenLockups[tokenId]);

            // Remove token lockup value
            delete tokenLockups[tokenId];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * Owner-only function to open/close the burn phase.
     * @param value New burn open value
     */
    function setBurnOpen(bool value) external onlyOwner {
        burnOpen = value;
    }

    /**
     * Owner-only function to set the EtherNFT contract that will be used for burning.
     * @param _nft Address of the EtherNFT contract
     */
    function setEtherNft(address _nft) external onlyOwner {
        etherNFT = IEtherNFT(_nft);
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    /**
     * Overridden setApprovalForAll with operator filtering.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * Overridden approve with operator filtering.
     */
    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * Overridden transferFrom with operator filtering. For ERC721A, this will also add
     * operator filtering for both safeTransferFrom functions.
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        // Validate that the token is not locked up
        if (tokenLockups[tokenId] >= block.timestamp) {
            revert TokenIsLocked(tokenId);
        }
        super.transferFrom(from, to, tokenId);
    }

    /**
     * Owner-only function to toggle operator filtering.
     * @param value Whether operator filtering is on/off.
     */
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    /**
     * Overridden supportsInterface with IERC721 support and ERC2981 support
     * @param interfaceId Interface Id to check
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    /**
     * Owner-only function to set the royalty receiver and royalty rate
     * @param receiver Address that will receive royalties
     * @param feeNumerator Royalty amount in basis points. Denominated by 10000
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =========================================================================
    //                                 Metadata
    // =========================================================================

    /**
     * Owner-only function to set the base uri used for metadata.
     * @param baseURI uri to use for metadata
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Function to retrieve the metadata uri for a given token. Reverts for tokens that don't exist.
     * @param tokenId Token Id to get metadata for
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }
}