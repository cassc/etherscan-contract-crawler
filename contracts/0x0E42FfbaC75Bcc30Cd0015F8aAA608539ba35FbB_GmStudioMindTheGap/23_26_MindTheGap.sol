// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 GmDAO
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Common.sol";
import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/factories/PaymentSplitterDeployer.sol";
import "../../utils/ERC2981SinglePercentual.sol";

//                                           __                    __ __
//                                          |  \                  |  \  \
//   ______  ______ ____           _______ _| ▓▓_   __    __  ____| ▓▓\▓▓ ______
//  /      \|      \    \         /       \   ▓▓ \ |  \  |  \/      ▓▓  \/      \
// |  ▓▓▓▓▓▓\ ▓▓▓▓▓▓\▓▓▓▓\       |  ▓▓▓▓▓▓▓\▓▓▓▓▓▓ | ▓▓  | ▓▓  ▓▓▓▓▓▓▓ ▓▓  ▓▓▓▓▓▓\
// | ▓▓  | ▓▓ ▓▓ | ▓▓ | ▓▓        \▓▓    \  | ▓▓ __| ▓▓  | ▓▓ ▓▓  | ▓▓ ▓▓ ▓▓  | ▓▓
// | ▓▓__| ▓▓ ▓▓ | ▓▓ | ▓▓__      _\▓▓▓▓▓▓\ | ▓▓|  \ ▓▓__/ ▓▓ ▓▓__| ▓▓ ▓▓ ▓▓__/ ▓▓
//  \▓▓    ▓▓ ▓▓ | ▓▓ | ▓▓  \    |       ▓▓  \▓▓  ▓▓\▓▓    ▓▓\▓▓    ▓▓ ▓▓\▓▓    ▓▓
//  _\▓▓▓▓▓▓▓\▓▓  \▓▓  \▓▓\▓▓     \▓▓▓▓▓▓▓    \▓▓▓▓  \▓▓▓▓▓▓  \▓▓▓▓▓▓▓\▓▓ \▓▓▓▓▓▓
// |  \__| ▓▓
//  \▓▓    ▓▓
//   \▓▓▓▓▓▓
//
contract GmStudioMindTheGap is
    ERC721Common,
    ReentrancyGuard,
    ERC2981SinglePercentual
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SignatureChecker for EnumerableSet.AddressSet;
    using Address for address payable;

    /// @notice Price for minting
    uint256 public constant MINT_PRICE = 0.15 ether;

    /// @notice Splits payments between the Studio and the artist.
    address payable public immutable paymentSplitter;

    /// @notice Splits payments between the Studio and the artist.
    address payable public immutable paymentSplitterRoyalties;

    /// @notice Total maximum amount of tokens
    uint32 public constant MAX_NUM_TOKENS = 999;

    /// @notice Max number of mints per transaction.
    /// @dev Only for public mints.
    uint32 public constant MAX_MINT_PER_TX = 1;

    /// @notice Number of mints throught the signed minting interface.
    uint32 internal constant NUM_SIGNED_MINTS = 300;

    /// @notice Number of mints for reserved the studio.
    uint32 internal constant NUM_RESERVED_MINTS = 1;

    /// @notice Currently minted supply of tokens
    uint32 public totalSupply;

    /// @notice Counter for the remaining signed mints
    uint32 internal numSignedMintsRemaining;

    /// @notice Locks the mintReserve function
    bool internal reserveMinted;

    /// @notice Locks the code storing function
    bool internal codeStoreLocked;

    /// @notice Timestamps to enables/eisables minting interfaces
    /// @dev The following order is assumed
    /// signedMintOpeningTimestamp < publicMintOpeningTimestamp < mintClosingTimestamp
    struct MintConfig {
        uint64 signedMintOpeningTimestamp;
        uint64 publicMintOpeningTimestamp;
        uint64 mintClosingTimestamp;
    }

    /// @notice The minting configuration
    MintConfig public mintConfig;

    /// @notice Stores the number of tokens minted from a signature
    /// @dev Used in mintSigned
    mapping(bytes32 => uint256) public numSignedMintsFrom;

    /// @notice Signature signers for the early access phase.
    /// @dev Removing signers invalidates the corresponding signatures.
    EnumerableSet.AddressSet private _signers;

    /// @notice tokenURI() base path.
    /// @dev Without trailing slash
    string internal _baseTokenURI;

    constructor(
        address newOwner,
        address signer,
        string memory baseTokenURI,
        address[] memory payees,
        uint256[] memory shares,
        uint256[] memory sharesRoyalties
    ) ERC721Common("Mind the Gap by MountVitruvius", "MTG") {
        _signers.add(signer);
        _baseTokenURI = baseTokenURI;

        paymentSplitter = payable(
            PaymentSplitterDeployer.instance().deploy(payees, shares)
        );

        paymentSplitterRoyalties = payable(
            PaymentSplitterDeployer.instance().deploy(payees, sharesRoyalties)
        );

        _setRoyaltyPercentage(750);
        _setRoyaltyReceiver(paymentSplitterRoyalties);

        numSignedMintsRemaining = NUM_SIGNED_MINTS;
        transferOwnership(newOwner);
    }

    // -------------------------------------------------------------------------
    //
    //  Minting
    //
    // -------------------------------------------------------------------------

    /// @notice Toggle minting relevant flags.
    function setMintConfig(MintConfig calldata config) external onlyOwner {
        mintConfig = config;
    }

    /// @dev Reverts if we are not in the signed minting window or the if
    /// `mintConfig` has not been set yet.
    modifier onlyDuringSignedMintingPeriod() {
        if (
            block.timestamp < mintConfig.signedMintOpeningTimestamp ||
            block.timestamp > mintConfig.publicMintOpeningTimestamp
        ) revert MintDisabled();
        _;
    }

    /// @dev Reverts if we are not in the public minting window or the if
    /// `mintConfig` has not been set yet.
    modifier onlyDuringPublicMintingPeriod() {
        if (
            block.timestamp < mintConfig.publicMintOpeningTimestamp ||
            block.timestamp > mintConfig.mintClosingTimestamp
        ) revert MintDisabled();
        _;
    }

    /// @notice Mints tokens to a given address using a signed message.
    /// @dev The minter might be different than the receiver.
    /// @param to Token receiver
    /// @param num Number of tokens to be minted.
    /// @param numMax Max number of tokens that can be minted to the receiver
    /// @param signature to prove that the receiver is allowed to get mints.
    /// @dev The signed messages is generated from `to || numMax`.
    function mintSigned(
        address to,
        uint32 num,
        uint32 numMax,
        uint256 nonce,
        bytes calldata signature
    ) external payable nonReentrant onlyDuringSignedMintingPeriod {
        bytes32 message = ECDSA.toEthSignedMessageHash(
            abi.encodePacked(to, numMax, nonce)
        );

        if (num + numSignedMintsFrom[message] > numMax)
            revert TooManyMintsRequested();

        if (num > numSignedMintsRemaining)
            revert InsufficientTokensRemanining();

        if (num * MINT_PRICE != msg.value) revert InvalidPayment();

        _signers.requireValidSignature(message, signature);
        numSignedMintsFrom[message] += num;
        numSignedMintsRemaining -= num;

        _processPayment();
        _processMint(to, num);
    }

    /// @notice Mints tokens to a given address.
    /// @dev The minter might be different than the receiver.
    /// @param to Token receiver
    /// @param num Number of tokens to be minted.
    function mintPublic(address to, uint32 num)
        external
        payable
        nonReentrant
        onlyDuringPublicMintingPeriod
    {
        if (num > MAX_MINT_PER_TX) revert TooManyMintsRequested();

        uint256 numRemaining = MAX_NUM_TOKENS - totalSupply;
        if (num > numRemaining) revert InsufficientTokensRemanining();

        if (num * MINT_PRICE != msg.value) revert InvalidPayment();

        _processPayment();
        _processMint(to, num);
    }

    /// @notice Mints the DAO allocated tokens.
    /// @dev The minter might be different than the receiver.
    /// @param to Token receiver
    function mintReserve(address to) external onlyOwner {
        if (reserveMinted) revert MintDisabled();
        reserveMinted = true;
        _processMint(to, NUM_RESERVED_MINTS);
    }

    /// @notice Mints new tokens for the recipient.
    function _processMint(address to, uint32 num) internal {
        uint32 supply = totalSupply;
        for (uint256 i = 0; i < num; i++) {
            if (MAX_NUM_TOKENS <= supply) revert SoldOut();
            ERC721._safeMint(to, supply);
            supply++;
        }
        totalSupply = supply;
    }

    // -------------------------------------------------------------------------
    //
    //  Signature validataion
    //
    // -------------------------------------------------------------------------

    /// @notice Removes and adds addresses to the set of allowed signers.
    /// @dev Removal is performed before addition.
    function changeSigners(
        address[] calldata delSigners,
        address[] calldata addSigners
    ) external onlyOwner {
        for (uint256 idx; idx < delSigners.length; ++idx) {
            _signers.remove(delSigners[idx]);
        }
        for (uint256 idx; idx < addSigners.length; ++idx) {
            _signers.add(addSigners[idx]);
        }
    }

    /// @notice Returns the addresses that are used for signature verification
    function getSigners() external view returns (address[] memory signers) {
        uint256 len = _signers.length();
        signers = new address[](len);
        for (uint256 idx = 0; idx < len; ++idx) {
            signers[idx] = _signers.at(idx);
        }
    }

    // -------------------------------------------------------------------------
    //
    //  Payment
    //
    // -------------------------------------------------------------------------

    /// @notice Default function for receiving funds
    /// @dev This enables the contract to be used as splitter for royalties.
    receive() external payable {
        _processPayment();
    }

    /// @notice Processes an incoming payment and sends it to the payment
    /// splitter.
    function _processPayment() internal {
        paymentSplitter.sendValue(msg.value);
    }

    // -------------------------------------------------------------------------
    //
    //  Metadata
    //
    // -------------------------------------------------------------------------

    /// @notice This function is intended to store (genart) code onchain in
    // calldata.
    function storeCode(bytes calldata) external {
        if (
            codeStoreLocked ||
            (mintConfig.signedMintOpeningTimestamp > 0 &&
                block.timestamp > mintConfig.signedMintOpeningTimestamp)
        ) revert CodeStoreLocked();
        codeStoreLocked = true;
    }

    /// @notice Change tokenURI() base path.
    /// @param uri The new base path (must not contain trailing slash)
    function setBaseTokenURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    /// @notice Returns the URI for token metadata.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseTokenURI,
                    "/",
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }

    // -------------------------------------------------------------------------
    //
    //  Internals
    //
    // -------------------------------------------------------------------------

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Common, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // -------------------------------------------------------------------------
    //
    //  Errors
    //
    // -------------------------------------------------------------------------

    error MintDisabled();
    error TooManyMintsRequested();
    error InsufficientTokensRemanining();
    error InvalidPayment();
    error SoldOut();
    error InvalidSignature();
    error ExeedsOwnerAllocation();
    error NotAllowedToOwnerMint();
    error NotAllowToChangeAddress();
    error CodeStoreLocked();
}