// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 gmDAO
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
contract GmStudioPlasticity is
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
    uint32 public constant MAX_NUM_TOKENS = 555;

    /// @notice Max number of mints per transaction.
    /// @dev Only for public mints.
    uint32 public constant MAX_MINT_PER_TX = 1;

    /// @notice True if desired to prevent Flashbots from executing more than
    /// one transaction per block
    bool internal constant FLASHBOTS_PROTECTION = true;

    /// @notice Number of mints throught the signed minting interface.
    uint32 internal constant NUM_SIGNED_MINTS = 555;

    /// @notice Number of mints for reserved the studio.
    uint32 internal constant NUM_RESERVED_MINTS = 1;

    /// @notice Currently minted supply of tokens
    uint32 public totalSupply;

    /// @notice Counter for the remaining signed mints
    uint32 internal numSignedMintsRemaining;

    /// @notice Locks the mintReserve function
    bool internal reserveMinted;

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

    /// @notice Keeps track when a given sender made the last tx.
    /// @dev This is used and incremented by the `onlyOncePerBlock` modifier.
    mapping(address => uint256) private _lastTxBlockBy;

    /// @notice Token seeds for the artwork generation code determined at mint.
    /// @dev Determined by `_computeSeed`.
    mapping(uint256 => bytes32) private _seeds;

    constructor(
        address newOwner,
        address signer,
        string memory baseTokenURI,
        address[] memory payees,
        uint256[] memory shares,
        uint256[] memory sharesRoyalties
    ) ERC721Common("Plasticity by p4stoboy", "PLAST") {
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

    /* solhint-disable not-rely-on-time */
    /// @dev Reverts if we are not in the signed minting window or the if
    /// `mintConfig` has not been set yet.
    modifier onlyDuringSignedMintingPeriod() {
        if (
            // solhint-disable-next-line not-rely-on-time
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
    /* solhint-enable not-rely-on-time */

    /// @dev Reverts if called more than once per block. Only applies to
    /// contracts.
    modifier onlyOncePerBlock() {
        /* solhint-disable-next-line avoid-tx-origin */
        if (FLASHBOTS_PROTECTION || tx.origin != msg.sender) {
            if (block.number <= _lastTxBlockBy[msg.sender])
                revert OnlyOneTxPerBlock();
            _lastTxBlockBy[msg.sender] = block.number;
        }
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
        uint16 num,
        uint16 numMax,
        uint16 nonce,
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

    /// @notice Mints tokens to the sender.
    /// @dev The minter might be different than the receiver.
    /// @param num Number of tokens to be minted.
    function mintPublic(uint32 num)
        external
        payable
        onlyDuringPublicMintingPeriod
        onlyOncePerBlock
    {
        if (num > MAX_MINT_PER_TX) revert TooManyMintsRequested();

        uint256 numRemaining = MAX_NUM_TOKENS - totalSupply;
        if (num > numRemaining) revert InsufficientTokensRemanining();

        if (num * MINT_PRICE != msg.value) revert InvalidPayment();

        _processPayment();
        _processMint(msg.sender, num);
    }

    /// @notice Receiver of reserve mints.
    /// @dev `to` corresponds to the address of the receiver and `num` to the
    /// number of tokens to be minted.
    struct ReserveReceiver {
        address to;
        uint32 num;
    }

    /// @notice Mints the initial token reserve.
    /// @param receivers Array of token receivers
    /// @dev The minter might be different than the receiver.
    /// @dev Reverts if the number of minted tokens does not equal
    /// NUM_RESERVED_MINTS
    function mintReserve(ReserveReceiver[] calldata receivers)
        external
        onlyOwner
    {
        if (reserveMinted) revert MintDisabled();
        reserveMinted = true;

        uint256 numReceivers = receivers.length;
        uint256 minted = 0;
        for (uint256 idx = 0; idx < numReceivers; ++idx) {
            minted += receivers[idx].num;
            _processMint(receivers[idx].to, receivers[idx].num);
        }
        if (minted != NUM_RESERVED_MINTS) revert WrongNumberOfReserveMints();
    }

    /// @notice Mints new tokens for the recipient.
    function _processMint(address to, uint32 num) internal {
        uint32 nextTokenId = totalSupply;
        for (uint256 i = 0; i < num; i++) {
            if (MAX_NUM_TOKENS <= nextTokenId) revert SoldOut();
            ERC721._safeMint(to, nextTokenId);
            _seeds[nextTokenId] = _computeSeed(to, nextTokenId);
            nextTokenId++;
        }
        totalSupply = nextTokenId;
    }

    /// @notice Computes a pseudorandom seed for a given token.
    /// @dev Even though this process can be gamed in principle, it is extremly
    /// difficult to do so in practise. Therefore we can still rely on this to
    /// derive fair seeds.
    function _computeSeed(address to, uint32 tokenId)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    block.difficulty,
                    blockhash(block.number - 1),
                    to,
                    tokenId
                )
            );
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

    /// @notice Returns the seed of a token.
    function tokenSeed(uint256 tokenId)
        public
        view
        tokenExists(tokenId)
        returns (bytes32)
    {
        return _seeds[tokenId];
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
    error OnlyOneTxPerBlock();
    error WrongNumberOfReserveMints();
}