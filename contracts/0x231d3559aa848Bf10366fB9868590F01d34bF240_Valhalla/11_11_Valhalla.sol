// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./token/ERC721V.sol";
import "./utils/ERC2981.sol";
import "./utils/IERC165.sol";
import "./utils/Ownable.sol";
import "./utils/ECDSA.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    ██╗░░░██╗░█████╗░██╗░░░░░██╗░░██╗░█████╗░██╗░░░░░██╗░░░░░░█████╗░    //
//    ██║░░░██║██╔══██╗██║░░░░░██║░░██║██╔══██╗██║░░░░░██║░░░░░██╔══██╗    //
//    ╚██╗░██╔╝███████║██║░░░░░███████║███████║██║░░░░░██║░░░░░███████║    //
//    ░╚████╔╝░██╔══██║██║░░░░░██╔══██║██╔══██║██║░░░░░██║░░░░░██╔══██║    //
//    ░░╚██╔╝░░██║░░██║███████╗██║░░██║██║░░██║███████╗███████╗██║░░██║    //
//    ░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝    //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////

/**
 * Subset of a Presale with only the methods that the main minting contract will call.
 */
interface Presale {
    function selectedBids(address presaleAddr) external view returns (uint256);
}

/**
 * Subset of the IOperatorFilterRegistry with only the methods that the main minting contract will call.
 * The owner of the collection is able to manage the registry subscription on the contract's behalf
 */
interface IOperatorFilterRegistry {
    function isOperatorAllowed(
        address registrant,
        address operator
    ) external returns (bool);
}

contract Valhalla is ERC721V, Ownable, ERC2981 {
    using ECDSA for bytes32;

    // =============================================================
    //                            Structs
    // =============================================================

    // Compiler will pack this into one 256-bit word
    struct AuctionParams {
        // auctionNumber; also tracks which bidIndexes are currently live
        uint16 index;
        // Following 2 values will be multiplied by 1 GWEI or 0.000000001 ETH
        // Bid values with GWEI lower than this denomination do NOT add to a bid.
        uint56 startPrice;
        uint56 minStackedBidIncrement;
        // new bids must beat the lowest bid by this percentage. This is a whole
        // percentage number, a value of 10 means new bids must beat old ones by 10%
        uint8 minBidIncrementPercentage;
        // Optional parameter for if a bid was submitted within seconds of ending,
        // endTimestamp will extend to block.timestamp+timeBuffer if that value is greater.
        uint16 timeBuffer;
        // When the auction can start getting bidded on
        uint48 startTimestamp;
        // When the auction can no longer get bidded on
        uint48 endTimestamp;
        // How many tokens are up for auction. If 0, there is NO auction live.
        uint8 numTokens;
    }

    struct Bid {
        address bidder;
        uint192 amount;
        uint64 bidTime;
    }

    struct BidIndex {
        uint8 index;
        bool isSet;
    }

    // =============================================================
    //                            Constants
    // =============================================================

    // Set on contract initialization
    address public immutable PRESALE_ADDRESS;

    // Proof of hash will be given after reveal.
    string public MINT_PROVENANCE_HASH = "037226b21636376001dbfd22f52d1dd72845efa9613baf51a6a011ac731b2327";
    // Owner will be minting this amount to the treasury which happens before
    // any presale or regular sale. Once totalSupply() is over this amount,
    // no more can get minted by {mintDev}
    uint256 public constant TREASURY_SUPPLY = 300;
    // Maximum tokens that can be minted from {mintTier} and {mintPublic}
    uint256 public constant MINT_CAP = 9000;

    // Public mint is unlikely to be enabled as it will get botted, but if
    // is needed this will make it a tiny bit harder to bot the entire remaining.
    uint256 public constant MAX_PUBLIC_MINT_TXN_SIZE = 5;

    // Proof of hash will be given after all tokens are auctioned.
    string public AUCTION_PROVENANCE_HASH = "eb8c88969a4b776d757de962a194f5b4ffaaadb991ecfbb24d806c7bc6397d30";
    // Multiplier for minBidPrice and minBidIncrement to verify bids are large enough
    // Is used so that we can save storage space and fit the auctionParams into one uint256
    uint256 public constant AUCTION_PRICE_MULTIPLIER = 1 gwei;
    uint256 public constant AUCTION_SUPPLY = 1000;
    // At most 5 tokens can be bid on at once
    uint256 public constant MAX_NUM_BIDS = 5;

    // Cheaper gaswise to set this as 10000 instead of MINT_CAP + AUCTION_SUPPLY
    uint256 public constant TOTAL_SUPPLY = 10000;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // Address that houses the implemention to check if operators are allowed or not
    address public operatorFilterRegistryAddress;
    // Address this contract verifies with the registryAddress for allowed operators.
    address public filterRegistrant;

    // Address that will link to the tokenDNA which the metadata relies on.
    address public dnaContractAddress;

    /**
     * Lockup timestamps are saved in uint24 to fit into the _extraData for the _packedOwnerships
     * mapping of ERC721A tokens. In order to still represent a large range of times, we will
     * be saving the hour the token gets unlocked.
     *
     * In {_beforeTokenTransfers}, _extraData * 3600 will be compared with the current block.timestamp.
     */
    uint24 public firstUnlockTime;
    uint24 public secondUnlockTime;
    uint24 public thirdUnlockTime;

    // Determines whether a presale address has already gotten its presale tokens
    mapping(address => bool) public presaleMinted;
    // If a presale address wants their tokens to land in a different wallet
    mapping(address => address) public presaleDelegation;

    string public tokenUriBase;

    // Address used for {mintTier} which will be a majority of the transactions
    address public signer;
    // Used to quickly invalidate batches of signatures if needed.
    uint256 public signatureVersion;
    // Mapping that shows if a tier is active or not
    mapping(string => bool) public isTierActive;
    mapping(bytes32 => bool) public signatureUsed;

    // Price of a single public mint, {mintPublic} is NOT enabled while this value is 0.
    uint256 public publicMintPrice;

    // Address that is permitted to start and stop auctions
    address public auctioneer;
    // The current highest bids made in the auction
    Bid[MAX_NUM_BIDS] public activeBids;
    // The mapping between an address and its active bid. The isSet flag differentiates the default
    // uint value 0 from an actual 0 value.
    mapping(uint256 => mapping(address => BidIndex)) public bidIndexes;

    // All parameters needed to run an auction
    AuctionParams public auctionParams;
    // ETH reserved due to a live auction, cannot be withdrawn by the owner until the
    // owner calls {endAuction} which also mints out the tokens.
    uint256 public reserveAuctionETH;

    // =============================================================
    //                            Events
    // =============================================================

    event TokenLocked(uint256 indexed tokenId, uint256 unlockTimeHr);
    event TokenUnlocked(uint256 indexed tokenId);

    event AuctionStarted(uint256 indexed index);
    event NewBid(
        uint256 indexed auctionIndex,
        address indexed bidder,
        uint256 value
    );
    event BidIncreased(
        uint256 indexed auctionIndex,
        address indexed bidder,
        uint256 oldValue,
        uint256 increment
    );
    event AuctionExtended(uint256 indexed index);

    // =============================================================
    //                          Constructor
    // =============================================================

    constructor(address initialPresale) ERC721V("Valhalla", "VAL") {
        PRESALE_ADDRESS = initialPresale;
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721V, ERC2981) returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            ERC721V.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // =============================================================
    //                           IERC2981
    // =============================================================

    /**
     * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =============================================================
    //                        Token Metadata
    // =============================================================

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return string(abi.encodePacked(tokenUriBase, _toString(tokenId)));
    }

    /**
     * @notice Allows the owner to set the base token URI.
     */
    function setTokenURI(string memory newUriBase) external onlyOwner {
        tokenUriBase = newUriBase;
    }

    /**
     * @notice Allows the owner to set the dna contract address.
     */
    function setDnaContract(address dnaAddress) external onlyOwner {
        dnaContractAddress = dnaAddress;
    }

    // =============================================================
    //                 Operator Filter Registry
    // =============================================================
    /**
     * @dev Stops operators from being added as an approved address to transfer.
     * @param operator the address a wallet is trying to grant approval to.
     */
    function _beforeApproval(address operator) internal virtual override {
        if (operatorFilterRegistryAddress.code.length > 0) {
            if (
                !IOperatorFilterRegistry(operatorFilterRegistryAddress)
                    .isOperatorAllowed(filterRegistrant, operator)
            ) {
                revert OperatorNotAllowed();
            }
        }
        super._beforeApproval(operator);
    }

    /**
     * @dev Stops operators that are not approved from doing transfers.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual override {
        if (operatorFilterRegistryAddress.code.length > 0) {
            if (
                !IOperatorFilterRegistry(operatorFilterRegistryAddress)
                    .isOperatorAllowed(filterRegistrant, msg.sender)
            ) {
                revert OperatorNotAllowed();
            }
        }
        // expiration time represented in hours. multiply by 60 * 60, or 3600.
        if (_getExtraDataAt(tokenId) * 3600 > block.timestamp)
            revert TokenTransferLocked();
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    /**
     * @notice Allows the owner to set a new registrant contract.
     */
    function setOperatorFilterRegistryAddress(
        address registryAddress
    ) external onlyOwner {
        operatorFilterRegistryAddress = registryAddress;
    }

    /**
     * @notice Allows the owner to set a new registrant address.
     */
    function setFilterRegistrant(address newRegistrant) external onlyOwner {
        filterRegistrant = newRegistrant;
    }

    // =============================================================
    //                          Presale
    // =============================================================

    /**
     * @notice Allows the owner to mint from treasury supply.
     */
    function mintDev(
        address[] memory mintAddresses,
        uint256[] memory mintQuantities
    ) external onlyOwner {
        for (uint256 i = 0; i < mintAddresses.length; ++i) {
            _mint(mintAddresses[i], mintQuantities[i]);
            if (totalSupply() > TREASURY_SUPPLY) revert OverDevSupplyLimit();
        }
    }

    /**
     * @notice Allows the owner to set the presale unlock times.
     */
    function setUnlockTimes(
        uint24 first,
        uint24 second,
        uint24 third
    ) external onlyOwner {
        firstUnlockTime = first;
        secondUnlockTime = second;
        thirdUnlockTime = third;
    }

    /**
     * @notice Allows selected presale addresses to assign wallet address to receive presale mints.
     * @dev This does not do anything for addresses that were not selected on the presale contract.
     */
    function setPresaleMintAddress(address addr) external {
        presaleDelegation[msg.sender] = addr;
    }

    /**
     * @notice Allows owner to mint presale tokens. The ordering is randomzied on-chain so
     * that the owner does not have control over which users get which tokens when uploading
     * an array of presaleUsers
     * @dev Presale contract already guarantees a cap on the # of presale tokens, so
     * we will not check supply against the MINT_CAP in order to save gas.
     */
    function mintPresale(address[] memory presaleUsers) external onlyOwner {
        uint256 nextId = _nextTokenId();

        uint256 supplyLeft = presaleUsers.length;
        while (supplyLeft > 0) {
            // generate a random index less than the supply left
            uint256 randomIndex = uint256(
                keccak256(abi.encodePacked(block.timestamp, supplyLeft))
            ) % supplyLeft;
            address presaleUser = presaleUsers[randomIndex];

            if (presaleMinted[presaleUser])
                revert PresaleAddressAlreadyMinted();
            presaleMinted[presaleUser] = true;

            uint256 tokensOwed = Presale(PRESALE_ADDRESS).selectedBids(
                presaleUser
            );
            _mintPresaleAddress(presaleUser, nextId, tokensOwed);

            unchecked {
                --supplyLeft;
                // Replace the chosen address with the last address not chosen
                presaleUsers[randomIndex] = presaleUsers[supplyLeft];
                nextId += tokensOwed;
            }
        }
    }

    /**
     * @dev mints a certain amount of tokens to the presale address or its delegation
     * if it has delegated another wallet. These tokens will be locked up and released
     * 1/3rd of the amounts at a time.
     */
    function _mintPresaleAddress(
        address presale,
        uint256 nextId,
        uint256 amount
    ) internal {
        if (presaleDelegation[presale] != address(0)) {
            _mint(presaleDelegation[presale], amount);
        } else {
            _mint(presale, amount);
        }

        unchecked {
            // Cheaper gas wise to do every 3 tokens and deal with the remainder afterwards
            // than to do if statements within the loop.
            for (uint256 j = 0; j < amount / 3; ) {
                uint256 start = nextId + j * 3;

                _setExtraDataAt(start, thirdUnlockTime);
                _setExtraDataAt(start + 1, secondUnlockTime);
                _setExtraDataAt(start + 2, firstUnlockTime);
                emit TokenLocked(start, thirdUnlockTime);
                emit TokenLocked(start + 1, secondUnlockTime);
                emit TokenLocked(start + 2, firstUnlockTime);

                ++j;
            }

            // temporarily adjust nextId to do minimal subtractions
            // when setting `extraData` field
            nextId += amount - 1;
            if (amount % 3 == 2) {
                _setExtraDataAt(nextId - 1, thirdUnlockTime);
                emit TokenLocked(nextId - 1, thirdUnlockTime);

                _setExtraDataAt(nextId, secondUnlockTime);
                emit TokenLocked(nextId, secondUnlockTime);
            } else if (amount % 3 == 1) {
                _setExtraDataAt(nextId, thirdUnlockTime);
                emit TokenLocked(nextId, thirdUnlockTime);
            }
        }
    }

    // =============================================================
    //                   External Mint Methods
    // =============================================================

    /**
     * @notice Allows the owner to change the active version of their signatures, this also
     * allows a simple invalidation of all signatures they have created on old versions.
     */
    function setSigner(address signer_) external onlyOwner {
        signer = signer_;
    }

    /**
     * @notice Allows the owner to change the active version of their signatures, this also
     * allows a simple invalidation of all signatures they have created on old versions.
     */
    function setSignatureVersion(uint256 version) external onlyOwner {
        signatureVersion = version;
    }

    /**
     * @notice Allows owner to sets if a certain tier is active or not.
     */
    function setIsTierActive(
        string memory tier,
        bool active
    ) external onlyOwner {
        isTierActive[tier] = active;
    }

    /**
     * @notice Tiered mint for allegiants, immortals, and presale bidders.
     * @dev After a tier is activated by the owner, users with the proper signature for that
     * tier are able to mint based on what the owner has approved for their wallet.
     */
    function mintTier(
        string memory tier,
        uint256 price,
        uint256 version,
        uint256 allowedAmount,
        uint256 buyAmount,
        bytes memory sig
    ) external payable {
        if (totalSupply() + buyAmount > MINT_CAP) revert OverMintLimit();
        if (!isTierActive[tier]) revert TierNotActive();
        if (version != signatureVersion) revert InvalidSignatureVersion();

        if (buyAmount > allowedAmount) revert InvalidSignatureBuyAmount();
        if (msg.value != price * buyAmount) revert IncorrectMsgValue();

        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encode(
                    tier,
                    address(this),
                    price,
                    version,
                    allowedAmount,
                    msg.sender
                )
            )
        );
        if (signatureUsed[hash]) revert SignatureAlreadyUsed();
        signatureUsed[hash] = true;
        if (hash.recover(sig) != signer) revert InvalidSignature();

        _mint(msg.sender, buyAmount);
    }

    /**
     * @notice Allows the owner to set the public mint price.
     * @dev If this is 0, it is assumed that the public mint is not active.
     */
    function setPublicMintPrice(uint256 price) external onlyOwner {
        publicMintPrice = price;
    }

    /**
     * @notice Public mint method. Will not work while {publicMintPrice} is 0.
     * Unlikely to be enabled because it can be easily botted.
     */
    function mintPublic(uint256 amount) external payable {
        if (tx.origin != msg.sender) revert NotEOA();
        if (totalSupply() + amount > MINT_CAP) revert OverMintLimit();
        if (publicMintPrice == 0) revert PublicMintNotLive();
        if (amount > MAX_PUBLIC_MINT_TXN_SIZE) revert OverMintLimit();

        if (msg.value != amount * publicMintPrice) revert IncorrectMsgValue();
        _mint(msg.sender, amount);
    }

    // =============================================================
    //                       Auction Methods
    // =============================================================

    /**
     * @notice Allows the owner to set the auction parameters
     */
    function setOverallAuctionParams(
        uint40 startPrice_,
        uint40 minStackedBidIncrement_,
        uint8 minBidIncrementPercentage_,
        uint16 timeBuffer_
    ) external onlyOwner {
        auctionParams.startPrice = startPrice_;
        auctionParams.minStackedBidIncrement = minStackedBidIncrement_;
        auctionParams.minBidIncrementPercentage = minBidIncrementPercentage_;
        auctionParams.timeBuffer = timeBuffer_;
    }

    /**
     * @notice Allows the owner to set the auctioneer address.
     */
    function setAuctioneer(address auctioneer_) external onlyOwner {
        auctioneer = auctioneer_;
    }

    /**
     * @notice Allows the autioneer to start the auction of `numTokens` from `startTime` to `endTime`.
     * @dev Auctions can only start after all minting has terminated. We cannot auction more than
     * MAX_NUM_BIDS at a time. Only one auction can be live at a time.
     */
    function startAuction(
        uint8 numTokens,
        uint48 startTime,
        uint48 endTime
    ) external {
        if (auctioneer != msg.sender) revert CallerNotAuctioneer();
        if (totalSupply() < MINT_CAP) revert MintingNotFinished();
        if (totalSupply() + numTokens > TOTAL_SUPPLY) revert OverTokenLimit();
        if (numTokens > MAX_NUM_BIDS) revert OverMaxBids();
        if (auctionParams.numTokens != 0) revert AuctionStillLive();
        if (auctionParams.startPrice == 0) revert AuctionParamsNotInitialized();

        auctionParams.numTokens = numTokens;
        auctionParams.startTimestamp = startTime;
        auctionParams.endTimestamp = endTime;

        emit AuctionStarted(auctionParams.index);
    }

    /**
     * @notice Allows the auctioneer to end the auction.
     * @dev Auctions can end at any time by the owner's discretion and when it ends all
     * current bids are accepted. The owner is also now able to withdraw the funds
     * that were reserved for the auction, and active bids data id reset.
     */
    function endAuction() external {
        if (auctioneer != msg.sender) revert CallerNotAuctioneer();
        if (auctionParams.numTokens == 0) revert AuctionNotLive();

        uint256 lowestPrice = activeBids[getBidIndexToUpdate()].amount;
        for (uint256 i = 0; i < auctionParams.numTokens; ) {
            if (activeBids[i].bidder == address(0)) {
                break;
            }

            _mint(activeBids[i].bidder, 1);

            // getBidIndex to update gaurantees no activeBids[i] is less than lowestPrice.
            unchecked {
                _transferETH(
                    activeBids[i].bidder,
                    activeBids[i].amount - lowestPrice
                );
                ++i;
            }
        }

        unchecked {
            ++auctionParams.index;
        }
        auctionParams.numTokens = 0;
        delete activeBids;
        reserveAuctionETH = 0;
    }

    /**
     * @notice Gets the index of the entry in activeBids to update
     * @dev The index to return will be decided by the following rules:
     * If there are less than auctionTokens bids, the index of the first empty slot is returned.
     * If there are auctionTokens or more bids, the index of the lowest value bid is returned. If
     * there is a tie, the most recent bid with the low amount will be returned. If there is a tie
     * among bidTimes, the highest index is chosen.
     */
    function getBidIndexToUpdate() public view returns (uint8) {
        uint256 minAmount = activeBids[0].amount;
        // If the first value is 0 then we can assume that no bids have been submitted
        if (minAmount == 0) {
            return 0;
        }

        uint8 minIndex = 0;
        uint64 minBidTime = activeBids[0].bidTime;

        for (uint8 i = 1; i < auctionParams.numTokens; ) {
            uint256 bidAmount = activeBids[i].amount;
            uint64 bidTime = activeBids[i].bidTime;

            // A zero bidAmount means the slot is empty because we enforce non-zero bid amounts
            if (bidAmount == 0) {
                return i;
            } else if (
                bidAmount < minAmount ||
                (bidAmount == minAmount && bidTime >= minBidTime)
            ) {
                minAmount = bidAmount;
                minIndex = i;
                minBidTime = bidTime;
            }

            unchecked {
                ++i;
            }
        }

        return minIndex;
    }

    /**
     * @notice Handle users' bids
     * @dev Bids must be made while the auction is live. Bids must meet a minimum reserve price.
     *
     * The first {auctionParams.numTokens} bids made will be accepted as valid. Subsequent bids must be a percentage
     * higher than the lowest of the active bids. When a low bid is replaced, the ETH will
     * be refunded back to the original bidder.
     *
     * If a valid bid comes in within the last `timeBuffer` seconds, the auction will be extended
     * for another `timeBuffer` seconds. This will continue until no new active bids come in.
     *
     * If a wallet makes a bid while it still has an active bid, the second bid will
     * stack on top of the first bid. If the second bid doesn't meet the `minStackedBidIncrement`
     * threshold, an error will be thrown. A wallet will only have one active bid at at time.
     */
    function bid() external payable {
        if (msg.sender != tx.origin) revert NotEOA();
        if (auctionParams.numTokens == 0) {
            revert AuctionNotInitialized();
        }
        if (
            block.timestamp < auctionParams.startTimestamp ||
            block.timestamp > auctionParams.endTimestamp
        ) {
            revert AuctionNotLive();
        }

        BidIndex memory existingIndex = bidIndexes[auctionParams.index][
            msg.sender
        ];
        if (existingIndex.isSet) {
            // Case when the user already has an active bid
            if (
                msg.value <
                auctionParams.minStackedBidIncrement * AUCTION_PRICE_MULTIPLIER
            ) {
                revert BidIncrementTooLow();
            }

            uint192 oldValue = activeBids[existingIndex.index].amount;
            unchecked {
                reserveAuctionETH += msg.value;
                activeBids[existingIndex.index].amount =
                    oldValue +
                    uint192(msg.value);
            }
            activeBids[existingIndex.index].bidTime = uint64(block.timestamp);

            emit BidIncreased(
                auctionParams.index,
                msg.sender,
                oldValue,
                msg.value
            );
        } else {
            if (
                msg.value < auctionParams.startPrice * AUCTION_PRICE_MULTIPLIER
            ) {
                revert ReservePriceNotMet();
            }

            uint8 lowestBidIndex = getBidIndexToUpdate();
            uint256 lowestBidAmount = activeBids[lowestBidIndex].amount;
            address lowestBidder = activeBids[lowestBidIndex].bidder;

            unchecked {
                if (
                    msg.value <
                    lowestBidAmount +
                        (lowestBidAmount *
                            auctionParams.minBidIncrementPercentage) /
                        100
                ) {
                    revert IncrementalPriceNotMet();
                }
                reserveAuctionETH += msg.value - lowestBidAmount;
            }

            // Refund lowest bidder and remove bidIndexes entry
            if (lowestBidder != address(0)) {
                delete bidIndexes[auctionParams.index][lowestBidder];
                _transferETH(lowestBidder, lowestBidAmount);
            }

            activeBids[lowestBidIndex] = Bid({
                bidder: msg.sender,
                amount: uint192(msg.value),
                bidTime: uint64(block.timestamp)
            });

            bidIndexes[auctionParams.index][msg.sender] = BidIndex({
                index: lowestBidIndex,
                isSet: true
            });

            emit NewBid(auctionParams.index, msg.sender, msg.value);
        }

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        if (
            auctionParams.endTimestamp - block.timestamp <
            auctionParams.timeBuffer
        ) {
            unchecked {
                auctionParams.endTimestamp = uint48(
                    block.timestamp + auctionParams.timeBuffer
                );
            }
            emit AuctionExtended(auctionParams.index);
        }
    }

    // =============================================================
    //                        Miscellaneous
    // =============================================================

    /**
     * @notice Allows owner to emit TokenUnlocked events
     * @dev This method does NOT need to be called for locked tokens to be unlocked.
     * It is here to emit unlock events for marketplaces to know when tokens are
     * eligible for trade. The burden to call this method on the right tokens at the
     * correct timestamp is on the owner of the contract.
     */
    function emitTokensUnlocked(uint256[] memory tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; ) {
            emit TokenUnlocked(tokens[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allows owner to withdraw a specified amount of ETH to a specified address.
     */
    function withdraw(
        address withdrawAddress,
        uint256 amount
    ) external onlyOwner {
        unchecked {
            if (amount > address(this).balance - reserveAuctionETH) {
                amount = address(this).balance - reserveAuctionETH;
            }
        }

        if (!_transferETH(withdrawAddress, amount)) revert WithdrawFailed();
    }

    /**
     * @notice Internal function to transfer ETH to a specified address.
     */
    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30000 }(new bytes(0));
        return success;
    }

    error AuctionNotInitialized();
    error AuctionNotLive();
    error AuctionParamsNotInitialized();
    error AuctionStillLive();
    error BidIncrementTooLow();
    error CallerNotAuctioneer();
    error IncorrectMsgValue();
    error IncrementalPriceNotMet();
    error InvalidSignatureBuyAmount();
    error InvalidSignature();
    error InvalidSignatureVersion();
    error MintingNotFinished();
    error NotEOA();
    error OverDevSupplyLimit();
    error OverMintLimit();
    error OverTokenLimit();
    error OverMaxBids();
    error OperatorNotAllowed();
    error PublicMintNotLive();
    error PresaleAddressAlreadyMinted();
    error ReservePriceNotMet();
    error SignatureAlreadyUsed();
    error TierNotActive();
    error TokenTransferLocked();
    error WithdrawFailed();
}