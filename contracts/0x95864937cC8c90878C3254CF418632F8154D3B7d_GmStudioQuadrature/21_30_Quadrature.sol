// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 gmDAO
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier-0-39/contracts/factories/PaymentSplitterDeployer.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "../../utils/ERC2981SinglePercentual.sol";
import "../../utils/IDelegationRegistry.sol";

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
contract GmStudioQuadrature is
    ERC721ACommon,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    ERC2981SinglePercentual
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SignatureChecker for EnumerableSet.AddressSet;
    using Address for address payable;

    /// @notice Timestamps to enable/disable minting interfaces
    struct AuctionConfig {
        uint64 startTimestamp;
        uint64 endTimestamp;
    }

    // @notice The address of the gm.dao token.
    IERC721 public gmToken;

    IDelegationRegistry public delegateCash =
        IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    /// @notice The price for early-access mints by the curation panel
    uint256 public constant MINT_PRICE_CURATION_PANEL = 0.25 ether;

    uint256 public constant GM_TOKEN_DISCOUNT_AMOUNT = 0.25 ether;

    /// @notice Start price of auction
    uint256 public constant MINT_START_PRICE = 4 ether;

    /// @notice End price of auction
    uint256 public constant MINT_END_PRICE = 0.25 ether;

    /// @notice Total maximum amount of tokens
    uint32 public constant MAX_NUM_TOKENS = 300;

    /// @notice Number of mints for reserved the studio/artist.
    uint32 internal constant NUM_RESERVED_MINTS = 6;

    /// @notice Splits payments between the Studio and the artist.
    address payable public immutable paymentSplitter;

    /// @notice Splits payments between the Studio and the artist.
    address payable public immutable paymentSplitterRoyalties;

    /// @notice Locks the mintReserve function
    bool internal reserveMinted;

    /// @notice The number of tokens minted with a possible rebate.
    uint256 internal numRebateMints;

    /// @notice The number of tokens minted with a possible rebate + gm token discount.
    uint256 internal numGMRebateMints;

    /// @notice The final sale price, if sold out.
    uint256 public finalSalePrice;

    /// @notice A map of user -> prices paid for mints. Allows us to calculate rebates.
    mapping(address => uint256[]) internal mintPrices;

    /// @notice A map of gm token id -> mint price. Allows us to calculate rebates with gm discounts.
    mapping(uint256 => uint256) public gmTokenIdToMintPrice;

    /// @notice A map of (minter address -> token IDs). Allows us to restrict rebate claims to the minter,
    /// rather than the token owner, if it is delegated.
    mapping(address => uint256[]) public gmMinterAddressToTokenIds;

    /// @notice The auction configuration
    AuctionConfig public auctionConfig;

    /// @notice tokenURI() base path.
    /// @dev Without trailing slash
    string internal _baseTokenURI;

    /// @notice Stores the number of tokens minted from a signature during the
    /// early access stage.
    /// @dev Used in `mintEarlyAccess`
    mapping(bytes32 => uint256) public numCurationPanelMintsFrom;

    /// @notice Signature signers for the early access stage.
    EnumerableSet.AddressSet private _signersCurationPanelReserve;

    bool public isClosed = false;

    constructor(
        address newOwner,
        string memory baseTokenURI,
        AuctionConfig memory config,
        address[] memory payees,
        uint256[] memory shares,
        uint256[] memory sharesRoyalties,
        address signersCurationPanelReserve,
        IERC721 _gmToken
    ) ERC721ACommon("Quadrature by Darien Brito", "QUAD") {
        _signersCurationPanelReserve.add(signersCurationPanelReserve);
        _baseTokenURI = baseTokenURI;
        auctionConfig = config;
        gmToken = _gmToken;

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
    function setAuctionConfig(AuctionConfig calldata config)
        external
        onlyOwner
    {
        auctionConfig = config;
    }

    /// @notice Sets the delegateCash contract.
    /// @dev mostly used for testing.
    function setDelegationContract(IDelegationRegistry _delegateCash)
        external
        onlyOwner
    {
        delegateCash = _delegateCash;
    }

    /// @notice Changes the closed flag on the sale.
    function setSaleClosed(bool closed) external onlyOwner {
        isClosed = closed;
    }

    /// @notice Reverts if the sale is closed.
    modifier whenNotClosed() {
        if (isClosed) {
            revert SaleClosed();
        }
        _;
    }

    modifier beforeAuctionStarted() {
        if (block.timestamp >= auctionConfig.startTimestamp) {
            revert MintDisabled();
        }
        _;
    }

    /// @dev Reverts if the auction has not started.
    modifier whenAuctionStarted() {
        if (block.timestamp < auctionConfig.startTimestamp) {
            revert MintDisabled();
        }
        _;
    }

    modifier whenAuctionFinished() {
        if (block.timestamp < auctionConfig.endTimestamp) {
            revert AuctionRunning();
        }
        _;
    }

    /// @dev Reverts if called by a contract.
    modifier onlyEOA() {
        /* solhint-disable-next-line avoid-tx-origin */
        if (tx.origin != msg.sender) {
            revert OnlyEOA();
        }
        _;
    }

    /**
     * @notice Returns the current price of the token.
     * @dev This is a linear interpolation between the start and end price.
     */
    function getCurrentPrice() public view returns (uint256) {
        if (finalSalePrice != 0) {
            return finalSalePrice;
        }

        uint256 maxDelta = MINT_START_PRICE - MINT_END_PRICE;
        uint256 timeDifference = auctionConfig.endTimestamp -
            auctionConfig.startTimestamp;

        if (block.timestamp <= auctionConfig.startTimestamp) {
            return MINT_START_PRICE;
        }

        uint256 timeElapsed = block.timestamp - auctionConfig.startTimestamp;
        uint256 delta = (maxDelta * timeElapsed) / timeDifference;
        if (delta > maxDelta) {
            return MINT_END_PRICE;
        }
        return MINT_START_PRICE - delta;
    }

    /// @notice Mints tokens for the sender.
    function mintPublic()
        external
        payable
        whenAuctionStarted
        whenNotClosed
        onlyEOA
    {
        uint256 price = getCurrentPrice();

        // Ensure value is correct. We use < so that we don't fail slight overpayments
        // based on price changing every block. This extra payment will be tracked
        // and claimed along side the rebate.
        if (msg.value < price) revert InvalidPayment();

        // If this is the last mint, set the final sale price.
        if (totalSupply() + 1 == MAX_NUM_TOKENS) {
            finalSalePrice = price;
        }

        // If price is at the resting price, we can send the value directly to
        // the payment splitter.
        if (price == MINT_END_PRICE) {
            paymentSplitter.sendValue(msg.value);
            _processMint(msg.sender, 1);
            return;
        }

        // Otherwise, there could be a rebate, so record the price paid.
        // Note: We record the actual sent amount, not current price.
        mintPrices[msg.sender].push(msg.value);
        numRebateMints++;
        _processMint(msg.sender, 1);
    }

    function mintWithGMToken(uint256 tokenId, address vault)
        external
        payable
        whenAuctionStarted
        whenNotClosed
        onlyEOA
    {
        if (!hasValidGMTokenOwnership(msg.sender, tokenId, vault)) {
            revert NotAuthorized();
        }
        // If price is > 0, then this token has already been used.
        if (gmTokenIdToMintPrice[tokenId] != 0) {
            revert NotAuthorized();
        }
        uint256 price = getCurrentPrice();
        if (msg.value < price) revert InvalidPayment();

        // If this is the last mint, set the final sale price.
        if (totalSupply() + 1 == MAX_NUM_TOKENS) {
            finalSalePrice = price;
        }

        // If price is at the resting price, we can send the value directly to
        // the payment splitter.
        if (price == MINT_END_PRICE) {
            paymentSplitter.sendValue(msg.value);
            _processMint(msg.sender, 1);
            return;
        }

        // We can save gas for token holders by only writing the price if it
        // might be needed for rebates. This technically means that the gm token
        // can be used multiple times, but if the price is at the resting price
        // then there is no discount anyway, so we don't really care.
        gmTokenIdToMintPrice[tokenId] = msg.value;
        gmMinterAddressToTokenIds[msg.sender].push(tokenId);
        numGMRebateMints++;
        _processMint(msg.sender, 1);
    }

    function hasValidGMTokenOwnership(
        address collector,
        uint256 tokenId,
        address vault
    ) internal view returns (bool) {
        address owner = gmToken.ownerOf(tokenId);
        if (owner == collector) {
            return true;
        }
        if (owner == vault) {
            // This cascades down to check delegations at the
            // contract and wallet level too.
            return
                delegateCash.checkDelegateForToken(
                    collector,
                    vault,
                    address(gmToken),
                    tokenId
                );
        }
        return false;
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
        mapping(bytes32 => uint256) storage numMintedFrom,
        uint256 price
    ) internal {
        // General checks
        if (num * price != msg.value) {
            revert InvalidPayment();
        }

        // Signature related checks
        bytes32 message = ECDSA.toEthSignedMessageHash(
            abi.encodePacked(address(this), to, numMax, nonce)
        );

        if (num + numMintedFrom[message] > numMax) {
            revert TooManyMintsRequested();
        }

        signers.requireValidSignature(message, signature);
        numMintedFrom[message] += num;

        paymentSplitter.sendValue(msg.value);
        _processMint(to, num);
    }

    /// @notice Mints tokens to a given address using a signed message during
    /// the curation panels early access before the actual auction starts.
    /// @dev The minter might be different than the receiver.
    /// @param to Token receiver
    /// @param num Number of tokens to be minted.
    /// @param numMax Max number of tokens that can be minted to the receiver.
    /// @param nonce additional signature salt.
    /// @param signature to prove that the receiver is allowed to get mints.
    function mintCurationPanel(
        address to,
        uint16 num,
        uint16 numMax,
        uint128 nonce,
        bytes calldata signature
    ) external payable beforeAuctionStarted whenNotClosed nonReentrant {
        _mintSigned(
            to,
            num,
            numMax,
            nonce,
            signature,
            _signersCurationPanelReserve,
            numCurationPanelMintsFrom,
            MINT_PRICE_CURATION_PANEL
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
        if (totalSupply() + num > MAX_NUM_TOKENS) {
            revert InsufficientTokensRemaining();
        }

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

    /// @notice Removes and adds addresses to the set of allowed signers.
    /// @dev Removal is performed before addition.
    function changeSigners(
        address[] calldata delSigners,
        address[] calldata addSigners
    ) external onlyOwner {
        EnumerableSet.AddressSet
            storage _signers = _signersCurationPanelReserve;

        for (uint256 idx; idx < delSigners.length; ++idx) {
            _signers.remove(delSigners[idx]);
        }
        for (uint256 idx; idx < addSigners.length; ++idx) {
            _signers.add(addSigners[idx]);
        }
    }

    // -------------------------------------------------------------------------
    //
    //  Payment
    //
    // -------------------------------------------------------------------------

    /// @notice Returns the resting price of auction. The resting price is the
    /// final sale price if sold out, otherwise it is the mint end price.
    function _restingPrice() internal view returns (uint256) {
        return finalSalePrice > 0 ? finalSalePrice : MINT_END_PRICE;
    }

    /// @notice Returns the amount of discount for GM token minters.
    /// Discount is the smaller of delta between resting price and final price,
    /// up to the max discount amount.
    /// E.g. if resting price is 0.5 ETH and final price is 0.3 ETH, and discount is 0.1 ETH,
    /// then the user gets a 0.1 ETH discount.
    /// If the resting price is 0.3 ETH and the final price is 0.25 ETH, then the user
    /// gets a 0.05 ETH discount.
    function _discountAmount(uint256 restingPrice)
        internal
        pure
        returns (uint256)
    {
        uint256 restingDelta = restingPrice - MINT_END_PRICE;
        return Math.min(restingDelta, GM_TOKEN_DISCOUNT_AMOUNT);
    }

    /// @notice Returns the total rebate amount for gm and normal mints for the given collector.
    /// @param collector The address of the collector.
    function getTotalRebateAmount(address collector)
        public
        view
        whenAuctionFinished
        returns (uint256)
    {
        return getRebateAmount(collector) + getGMTokenRebateAmount(collector);
    }

    /// @notice Returns the amount of rebate available to the collector.
    /// @param collector The address of the collector.
    /// @dev The rebate is the difference between the price paid and the
    /// resting price.
    function getRebateAmount(address collector)
        public
        view
        whenAuctionFinished
        returns (uint256)
    {
        uint256[] memory amountsPaid = mintPrices[collector];

        // We reuse this storage slot to indicate that the rebate has been claimed.
        if (amountsPaid.length == 0) {
            return 0;
        }

        uint256 restingPrice = _restingPrice();
        uint256 totalRebate = 0;
        for (uint256 i = 0; i < amountsPaid.length; i++) {
            if (amountsPaid[i] > restingPrice) {
                totalRebate += amountsPaid[i] - restingPrice;
            }
        }
        return totalRebate;
    }

    /// @notice Returns the amount of rebate available to the collector for the gm token mints.
    /// @param collector The address of the collector.
    function getGMTokenRebateAmount(address collector)
        public
        view
        whenAuctionFinished
        returns (uint256)
    {
        uint256 restingPrice = _restingPrice();
        uint256 discountAmount = _discountAmount(restingPrice);
        uint256 totalRebate = 0;

        uint256[] storage tokenIds = gmMinterAddressToTokenIds[collector];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 amountPaid = gmTokenIdToMintPrice[tokenIds[i]];
            // Not minted or already claimed
            if (amountPaid == 0) {
                continue;
            }

            // Note that unlike for 'normal' mints, you can still be eligible
            // for a rebate if the amount paid == resting price (because it may
            // be above the final sale price)
            totalRebate += amountPaid - restingPrice + discountAmount;
        }

        return totalRebate;
    }

    /// @notice Claims the rebate for the sender, if available.
    function claimRebate() public whenAuctionFinished {
        uint256 totalRebate = getTotalRebateAmount(msg.sender);

        if (totalRebate == 0) {
            revert NoRebateAvailable();
        }

        // Delete the rebate amounts so they cannot be claimed again.
        delete (mintPrices[msg.sender]);

        // Delete gm token mints so they cannot be claimed again.
        delete gmMinterAddressToTokenIds[msg.sender];

        // External call, ensure rebate is marked as claimed before calling for reentrancy.
        payable(msg.sender).sendValue(totalRebate);
    }

    /// @notice Flushes the pending money to the payment splitter.
    /// @dev During the auction, we do not know the final price, so we
    /// buffer money in the contract to allow rebates to be claimed.
    /// Once the final price is known, we can forward that money to the splitter.
    /// Note that mints which are made at the known final price go directly to
    /// the splitter.
    function forwardPaymentToSplitter() public whenAuctionFinished {
        // Nothing to do if no mints have a rebate.
        if (numRebateMints == 0 && numGMRebateMints == 0) {
            return;
        }

        uint256 restingPrice = _restingPrice();
        uint256 totalNonTokenValue = numRebateMints * restingPrice;

        uint256 totalGMTokenValue = numGMRebateMints *
            (restingPrice - _discountAmount(restingPrice));

        // Set the pending rebates to 0, so that we can't flush twice.
        numRebateMints = 0;
        numGMRebateMints = 0;

        paymentSplitter.sendValue(totalNonTokenValue + totalGMTokenValue);
    }

    /// @notice Emergency withdraw funds from the contract.
    /// This will only be used in case of an emergency like a critical bug or misconfiguration.
    function emergencyWithdraw() external onlyOwner {
        address payable studioMultisig = payable(
            0x16485319Aa0aD7a4E68176FBaadA235c92ACae2E
        );
        studioMultisig.sendValue(address(this).balance);
    }

    // -------------------------------------------------------------------------
    //
    //  Metadata
    //
    // -------------------------------------------------------------------------

    /// @notice Change tokenURI() base path.
    /// @param uri The new base path (must not contain trailing slash)
    function setBaseTokenURI(string calldata uri) external onlyOwner {
        require(bytes(uri).length > 0, "Base token URI cannot be empty");
        require(
            bytes(uri)[bytes(uri).length - 1] != "/",
            "Base token URI must not contain trailing slash"
        );

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
    //  Operator filtering
    //
    // -------------------------------------------------------------------------

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
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
    error InsufficientTokensRemaining();
    error InvalidPayment();
    error OnlyEOA();
    error WrongNumberOfReserveMints();
    error AuctionRunning();
    error NoRebateAvailable();
    error NotAuthorized();
    error SaleClosed();
}