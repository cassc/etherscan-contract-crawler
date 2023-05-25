// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 gmDAO
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
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
contract GmStudioFactura is
    ERC721ACommon,
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

    /// @notice Number of mints throught the early access minting interface.
    uint32 internal constant NUM_EARLY_ACCESS_MINTS = 999;

    /// @notice Number of mints for reserved the studio/artist.
    uint32 internal constant NUM_RESERVED_MINTS = 6;

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

    /// @notice Stores the number of tokens minted from a signature during the
    /// early access stage.
    /// @dev Used in `mintEarlyAccess`
    mapping(bytes32 => uint256) public numEarlyAccessMintsFrom;

    /// @notice Stores the number of tokens minted from a signature during the
    /// public minting stage.
    /// @dev Used in `mintPublic`
    mapping(bytes32 => uint256) private _numPublicMintsFrom;

    /// @notice Signature signers for the early access stage.
    /// @dev Removing signers invalidates the corresponding signatures.
    EnumerableSet.AddressSet private _signersEarlyAccess;

    /// @notice Signature signers for the early access stage.
    /// @dev Removing signers invalidates the corresponding signatures.
    EnumerableSet.AddressSet private _signersPublic;

    /// @notice tokenURI() base path.
    /// @dev Without trailing slash
    string internal _baseTokenURI;

    constructor(
        address newOwner,
        address signerEarlyAccess,
        address signerPublic,
        string memory baseTokenURI,
        MintConfig memory config,
        address[] memory payees,
        uint256[] memory shares,
        uint256[] memory sharesRoyalties
    ) ERC721ACommon("Factura by Mathias Isaksen", "FACTURA") {
        _signersEarlyAccess.add(signerEarlyAccess);
        _signersPublic.add(signerPublic);
        _baseTokenURI = baseTokenURI;
        mintConfig = config;

        paymentSplitter = payable(
            PaymentSplitterDeployer.instance().deploy(payees, shares)
        );

        paymentSplitterRoyalties = payable(
            PaymentSplitterDeployer.instance().deploy(payees, sharesRoyalties)
        );

        _setRoyaltyPercentage(750);
        _setRoyaltyReceiver(paymentSplitterRoyalties);

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
    /// @dev Reverts if we are not in the early access minting window or the if
    /// `mintConfig` has not been set yet.
    modifier onlyDuringEarlyAccessMintingPeriod() {
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

    /// @dev Reverts if called by a contract.
    modifier onlyEOA() {
        /* solhint-disable-next-line avoid-tx-origin */
        if (tx.origin != msg.sender) {
            revert OnlyEOA();
        }
        _;
    }

    /// @notice Mints tokens to a given address using a signed message.
    /// @dev The minter might be different than the receiver.
    /// @param to Token receiver
    /// @param num Number of tokens to be minted.
    /// @param numMax Max number of tokens that can be minted to the receiver.
    /// @param nonce additional signature salt.
    /// @param signature to prove that the receiver is allowed to get mints.
    /// @dev The signed messages is generated by concatenating
    /// `address(this) || to || numMax || nonce`.
    function _mintSigned(
        address to,
        uint16 num,
        uint16 numMax,
        uint128 nonce,
        bytes calldata signature,
        EnumerableSet.AddressSet storage signers,
        mapping(bytes32 => uint256) storage numMintedFrom
    ) internal {
        // General checks
        if (num * MINT_PRICE != msg.value) revert InvalidPayment();

        // Signature related checks
        bytes32 message = ECDSA.toEthSignedMessageHash(
            abi.encodePacked(address(this), to, numMax, nonce)
        );

        if (num + numMintedFrom[message] > numMax)
            revert TooManyMintsRequested();

        signers.requireValidSignature(message, signature);
        numMintedFrom[message] += num;

        _processPayment();
        _processMint(to, num);
    }

    /// @notice Mints tokens to a given address using a signed message during
    /// the early access stage.
    /// @dev The minter might be different than the receiver.
    /// @param to Token receiver
    /// @param num Number of tokens to be minted.
    /// @param numMax Max number of tokens that can be minted to the receiver.
    /// @param nonce additional signature salt.
    /// @param signature to prove that the receiver is allowed to get mints.
    function mintEarlyAccess(
        address to,
        uint16 num,
        uint16 numMax,
        uint128 nonce,
        bytes calldata signature
    ) external payable onlyDuringEarlyAccessMintingPeriod nonReentrant {
        if (num > _numEarlyAccessMintsRemaining())
            revert InsufficientTokensRemanining();

        _mintSigned(
            to,
            num,
            numMax,
            nonce,
            signature,
            _signersEarlyAccess,
            numEarlyAccessMintsFrom
        );
    }

    /// @notice Computes the number of remaining early access mints.
    /// @dev This takes into account whether or not the reserve was alredy minted.
    function _numEarlyAccessMintsRemaining() internal view returns (uint256) {
        uint256 maxMints = reserveMinted
            ? NUM_EARLY_ACCESS_MINTS + NUM_RESERVED_MINTS
            : NUM_EARLY_ACCESS_MINTS;
        return maxMints - totalSupply();
    }

    /// @notice Mints tokens for the sender using a signed message during
    /// the public minting stage.
    /// @param num Number of tokens to be minted.
    /// @param numMax Max number of tokens that can be minted.
    /// @param nonce additional signature salt.
    /// @param signature to prove that the receiver is allowed to get mints.
    function mintPublic(
        uint16 num,
        uint16 numMax,
        uint128 nonce,
        bytes calldata signature
    ) external payable onlyDuringPublicMintingPeriod onlyEOA {
        _mintSigned(
            msg.sender,
            num,
            numMax,
            nonce,
            signature,
            _signersPublic,
            _numPublicMintsFrom
        );
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
    function _processMint(address to, uint256 num) internal {
        if (totalSupply() + num > MAX_NUM_TOKENS)
            revert InsufficientTokensRemanining();

        _mint(to, num);
    }

    /// @notice Computes a pseudorandom seed for a mint batch.
    /// @dev Even though this process can be gamed in principle, it is extremly
    /// difficult to do so in practise. Therefore we can still rely on this to
    /// derive fair seeds.
    function _computeBatchSeed(address to) private view returns (uint24) {
        return
            uint24(
                bytes3(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            blockhash(block.number - 1),
                            to
                        )
                    )
                )
            );
    }

    /// @dev Sets the extra data field during token transfers
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual override returns (uint24) {
        // if minting, compute a batch seed
        if (from == address(0)) {
            return _computeBatchSeed(to);
        }
        // else return the current value
        return previousExtraData;
    }

    // -------------------------------------------------------------------------
    //
    //  Signature validataion
    //
    // -------------------------------------------------------------------------

    /// @notice The different minting stages
    enum MintingStage {
        EarlyAccess,
        Public
    }

    /// @notice Helper function the retrieves the correct set of signers for
    /// a given minting stage.
    function _getSigners(MintingStage stage)
        internal
        view
        returns (EnumerableSet.AddressSet storage)
    {
        if (stage == MintingStage.EarlyAccess) return _signersEarlyAccess;
        if (stage == MintingStage.Public) return _signersPublic;
        revert WrongMintingStage();
    }

    /// @notice Removes and adds addresses to the set of allowed signers.
    /// @dev Removal is performed before addition.
    function changeSigners(
        MintingStage stage,
        address[] calldata delSigners,
        address[] calldata addSigners
    ) external onlyOwner {
        EnumerableSet.AddressSet storage _signers = _getSigners(stage);

        for (uint256 idx; idx < delSigners.length; ++idx) {
            _signers.remove(delSigners[idx]);
        }
        for (uint256 idx; idx < addSigners.length; ++idx) {
            _signers.add(addSigners[idx]);
        }
    }

    /// @notice Returns the addresses that are used for signature verification
    /// for a given minting stage.
    function getSigners(MintingStage stage)
        external
        view
        returns (address[] memory signers)
    {
        EnumerableSet.AddressSet storage _signers = _getSigners(stage);

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
    /// @dev The seed is computed from the seed of the batch in which the given
    /// token was minted.
    function tokenSeed(uint256 tokenId)
        public
        view
        tokenExists(tokenId)
        returns (bytes32)
    {
        uint24 batchSeed = _ownershipOf(tokenId).extraData;
        return keccak256(abi.encodePacked(address(this), batchSeed, tokenId));
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
        override(ERC721ACommon, ERC2981)
        returns (bool)
    {
        return
            ERC721ACommon.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
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
    error OnlyEOA();
    error WrongNumberOfReserveMints();
    error SignatureAlreadyUsed();
    error WrongMintingStage();
}