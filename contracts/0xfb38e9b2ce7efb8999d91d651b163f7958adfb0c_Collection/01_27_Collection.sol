// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

/**
          █████             ╨████████▀              ▌██████▌┌──└▌█████               █████          
         ▐▀█████              ╫█████                  █████       ╙████▌            ▄▀█████         
         ▀ █████▌             ╟████                   █████        █████            ⌐ █████▄        
        ▌   █████             ╟████                   █████        █████           ▌   █████        
       ╫     █████            ╟████                   █████       ▄████           ▌     █████       
      ╓─     ▀█████           ╟████                   █████╥╥╥╥╥▄███             ▐      ▓█████      
      ▌       █████▄          ╟████                   █████       ─█████         ▀       █████▄     
     ▓         █████          ╟████                   █████         █████       ▓         █████     
    ▄           █████         ╟████            ▓▌     █████         █████▌     ╫          └█████    
   ╓▌           ██████        ╟████            █▌     █████         █████▀    ╓▀           ██████   
  ╓█             █████▄       ╟████          ███▌     █████         █████    ▄█             █████▄  
,█████▌         ,███████     ▄██████▄     ,█████▌    ███████      █████╨   ,█████▌         ,███████ 
└└└└└└└└       └└└└└└└└└└   └└└└└└└└└└┌─┌└└└└└└└    └└└└└└└└└└──└└─        └└└└└└└─       └└└└└└└└└└ 
*/

import {AccessControlEnumerable} from "openzeppelin-contracts/access/AccessControlEnumerable.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {ERC721AUpgradeable} from "erc721a/ERC721AUpgradeable.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC2981} from "openzeppelin-contracts/interfaces/IERC2981.sol";
import {OperatorFiltererUpgradeable} from "operator-filter-registry/upgradeable/OperatorFiltererUpgradeable.sol";

import {IAlbaDelegate} from "./IAlbaDelegate.sol";
import {IPaymentSplitter} from "./IPaymentSplitter.sol";
import {CollectionConfig, SaleConfig, RoyaltyConfig, SaleType} from "./Types.sol";

/**
 * @title Collection
 * @notice The Alba Collection contract.
 * @dev This contract uses `ERC721AUpgradeable`, but that is because it is deployed as a minimal proxy
 * to a base collection for implementation. This contract itself is *not* upgradeable.
 */
contract Collection is
    Initializable,
    ERC721AUpgradeable,
    OperatorFiltererUpgradeable,
    Ownable,
    AccessControlEnumerable
{
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");
    bytes32 public constant ROLE_ARTIST = keccak256("ROLE_ARTIST");

    // Differentiate signature type
    uint8 private constant SIG_TYPE_RESERVED = 0xFF;

    error InvalidConfiguration();
    error InvalidPayment();
    error TooManyMintsRequested();
    error InsufficientTokensRemanining();
    error SaleNotActive();
    error NoRebateAvailable();
    error UnknownToken();
    error Unauthorized();
    error InvalidRoyaltyPercentage();
    error PaymentFailed();
    error AuctionStillActive();
    error HoFNotAvailable();

    event SaleFinished();
    event RebateClaimed(address claimer, address recipient, uint256 amount);
    event PaymentFlushed(uint256 amount);
    event PaymentsClaimed(address user);
    event AlbaEjected();

    IAlbaDelegate public albaDelegate;
    SaleConfig public saleConfig;
    CollectionConfig public collectionConfig;
    RoyaltyConfig public royaltyConfig;

    // Location of primary sale payment splitter.
    address payable public paymentSplitter;

    // Location of secondary sale payment splitter.
    address payable public paymentSplitterRoyalties;

    /* Mint mechanics */

    // Flag to indicate that the sale has been closed.
    // This is different to selling out or the auction ending.
    // It is only used when the sale is explcitly closed by the artist.
    bool public isSaleClosed;

    // Keeps track of the number of reserved tokens minted (keyed by message hash)
    mapping(bytes32 => uint256) private numReserveMintedFrom;
    // Tracks the total number of reserve mints to ensure we don't mint more than the max.
    // This allows us to overallocate reserves if we want to.
    uint256 public numReservedMinted;
    // Tracks the number of retained tokens minted by the artist.
    uint256 public numRetainedMinted;
    // Tracks if the Hall of Fame piece has been minted.
    bool public isHofMinted;

    /* Auction specific properties */

    // Final price used for rebates.
    uint256 public finalSalePrice;
    // Number of _potential_ 'rebate mints' i.e. mints which might be eligible for a rebate.
    uint256 private numRebateMints;
    // Purchase prices used to compute rebates.
    mapping(address => uint256[]) public mintPrices;

    // Modifiers

    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) revert UnknownToken();
        _;
    }

    modifier managerOrArtist() {
        if (!hasRole(ROLE_MANAGER, msg.sender) && !hasRole(ROLE_ARTIST, msg.sender)) revert Unauthorized();
        _;
    }

    modifier onlyArtist() {
        if (!hasRole(ROLE_ARTIST, msg.sender)) revert Unauthorized();
        _;
    }

    modifier artistOrAlbaReceiver() {
        if (!hasRole(ROLE_ARTIST, msg.sender) && msg.sender != albaDelegate.getAlbaFeeReceiver()) revert Unauthorized();
        _;
    }

    modifier onlyManager() {
        if (!hasRole(ROLE_MANAGER, msg.sender)) revert Unauthorized();
        _;
    }

    modifier mintingActive() {
        if (isSaleClosed || block.timestamp < saleConfig.startTime) revert SaleNotActive();
        _;
    }

    modifier onlyAlbaReceiver() {
        if (msg.sender != albaDelegate.getAlbaFeeReceiver()) revert Unauthorized();
        _;
    }

    function initialize(
        IAlbaDelegate _albaDelegate,
        CollectionConfig memory _config,
        SaleConfig memory _saleConfig,
        RoyaltyConfig memory _royaltyConfig,
        address albaManager,
        address artist
    ) public initializerERC721A initializer {
        __ERC721A_init(_config.name, _config.token);

        _setupRole(DEFAULT_ADMIN_ROLE, albaManager);
        _setupRole(ROLE_MANAGER, albaManager);
        _setupRole(ROLE_ARTIST, artist);

        albaDelegate = _albaDelegate;
        collectionConfig = _config;
        saleConfig = _saleConfig;
        royaltyConfig = _royaltyConfig;

        _validateSaleConfig(saleConfig);

        // Split all sales between the artist and Alba.
        address albaReceiver = _albaDelegate.getAlbaFeeReceiver();
        _setupPrimarySplitter(artist, albaReceiver, _royaltyConfig);
        _setupSecondarySplitter(artist, albaReceiver, _royaltyConfig);

        // If we are enforcing royalties, then we need to setup the operator filterer.
        // If the contract is deployed without royalties, this must be configured manually
        // in the registry at a later date.
        if (_royaltyConfig.enforceRoyalties) {
            __OperatorFilterer_init(_albaDelegate.operatorFilterSubscription(), true);
        }

        // Make the artist the owner of the contract.
        // Note that this leaves in place the manager role for the Alba
        // platform to continue to manage the contract. This will let
        // Alba make changes to the contract in the future, such as replacing
        // the delegate to fix issues or change things like the way on-chain
        // HTML is built.
        // To remove Alba's managaer role, see `assumeTotalOwnership`.
        _transferOwnership(artist);
    }

    // Minting

    /**
     * @notice Mint a number of tokens to a user.
     * @param collectionId The collection ID.
     * @param user The user to mint to.
     * @param num The number of tokens to mint.
     * @param nonce The nonce to use for the signature.
     * @param signature The signature to verify.
     * @dev We use a signature to verify the mints. This gives us an opportunity to
     * prevent bots.
     */
    function mint(
        bytes16 collectionId,
        address user,
        uint16 num,
        uint32 nonce,
        bytes calldata signature
    ) external payable mintingActive {
        // Max mints do not include reserved mints.
        uint256 publicMinted = _salePiecesMinted() - numReservedMinted;
        uint256 publicLimit = saleConfig.maxSalePieces - saleConfig.numReserved;
        if (publicMinted + num > publicLimit) revert InsufficientTokensRemanining();

        albaDelegate.verifyMint(collectionId, user, num, nonce, signature);

        _mintInternal({user: user, num: num, isReserve: false});
    }

    function mintReserved(
        bytes16 collectionId,
        address user,
        uint16 num,
        uint16 maxMints,
        uint32 nonce,
        bytes calldata signature
    ) external payable mintingActive {
        // Ensure signature is valid
        bytes32 message = _reserveMessage(collectionId, user, maxMints, nonce);
        albaDelegate.verifyMintReserve(message, signature);

        if (num + numReserveMintedFrom[message] > maxMints) revert TooManyMintsRequested();

        if (numReservedMinted + num > saleConfig.numReserved) revert InsufficientTokensRemanining();

        if (_salePiecesMinted() + num > saleConfig.maxSalePieces) revert InsufficientTokensRemanining();

        // Record how many reserved mints have been made from this address
        numReserveMintedFrom[message] += num;
        numReservedMinted += num;

        _mintInternal({user: user, num: num, isReserve: true});
    }

    /**
     * @notice Mints tokens for the artist only.
     * @dev This does not call mintInternal because these mints are completely separate from the sale.
     * They can happen at any time, cost nothing, and are only limited by the number of tokens
     * in the configuration.
     */
    function mintRetained(uint16 num) external onlyArtist {
        if (numRetainedMinted + num > saleConfig.numRetained) revert InsufficientTokensRemanining();
        numRetainedMinted += num;
        _mint(msg.sender, num);
    }

    /**
     * @notice Mints the hall of fame piece.
     * This is a special piece for the Alba gallery, used to share and exhibit the work.
     * This can be called by Alba, even if the contract is fully owned by the artist.
     */
    function mintHallOfFame(address to) external onlyAlbaReceiver {
        if (isHofMinted) {
            revert HoFNotAvailable();
        }
        isHofMinted = true;
        _mint(to, 1);
    }

    /**
     * @dev Internal mint function.
     * This does the standard checks and records generic information about the sale.
     * It also controls the auction mechanics.
     * Callers must verify that the mint signature is valid before using this function.
     * Any extra money sent for the mints is kept by the contract, though will be returned
     * as part of the rebate if the rebate is enabled. We do this to avoid issues with
     * continuous auctions where the price may change between when the transaction is sent and
     * included in a block.
     * NOTE: It is important to understand that reserve mints can happen after the _auction_
     * has finished. This means that mints _may_ happen after the final price is set. However,
     * reserve mints cannot _set_ the final price.
     */
    function _mintInternal(address user, uint256 num, bool isReserve) private {
        uint256 price = _getPrice();
        if (msg.value < num * price) revert InvalidPayment();

        // We don't want to wait for all reserves to mint to 'sell out', as they may be
        // held for a long time. However, we still treat the mints the same as public ones
        // (i.e. eligible for rebate if applicable).
        if (!isReserve) {
            uint256 publicMinted = _salePiecesMinted() - numReservedMinted;
            uint256 publicPieceLimit = saleConfig.maxSalePieces - saleConfig.numReserved;
            // If the final price is not already set, then set it if we've sold out
            if (finalSalePrice == 0 && publicMinted + num == publicPieceLimit) {
                finalSalePrice = price;
                emit SaleFinished();
            }
        }

        // If the auction has a rebate and the resting price has not been discovered,
        // record the price paid for each mint.
        // Record that these mints are 'rebate mints' so we know how much money
        // to flush later on.
        if (saleConfig.hasRebate && finalSalePrice == 0 && price > saleConfig.finalPrice) {
            for (uint256 i = 0; i < num; i++) {
                mintPrices[user].push(price);
            }
            numRebateMints += num;
        }

        // Do the mint
        _mint(user, num);

        // Send the payment on to the splitter.
        // If there is a rebate, the value will stay in the contract waiting to be claimed.
        // However, once the auction is finished, we know that the mint price is always
        // the final price, so we can send the payment on to the splitter immediately. This
        // removes the need for having the artist flush the payment more than once, and subsequently
        // we don't need to keep track of which mints are already accounted for in the flushing
        // process.
        // We send the payment directly if:
        // 1. There is no rebate on the sale
        // 2. The final price is not 0 (i.e. the sale has finished)
        // 3. The price paid is not the final price (i.e. the auction is still ongoing)
        // 4. The auction has finished - this case ensures we send value after the auction is there's no sellout.
        if (!saleConfig.hasRebate || finalSalePrice != 0 || price == saleConfig.finalPrice || _hasAuctionFinished()) {
            (bool success, ) = paymentSplitter.call{value: msg.value}("");
            if (!success) revert PaymentFailed();
        }
    }

    /**
     * @notice Returns the number of reserves used by the given user.
     */
    function reservesUsed(
        bytes16 collectionId,
        address user,
        uint16 maxMints,
        uint32 nonce
    ) external view returns (uint256) {
        bytes32 message = _reserveMessage(collectionId, user, maxMints, nonce);
        return numReserveMintedFrom[message];
    }

    /**
     * @notice Returns the message that is used for reserve mints.
     * @dev This can be used to verify signatures as well as check the number of mints used.
     * We prepend a type byte before the collectionID to ensure that we don't have any overlapping
     * signatures (without this the params may be identical to the public mint signature). This is
     * in place of the typed signature EIP which we should upgrade to ideally.
     */
    function _reserveMessage(
        bytes16 collectionId,
        address user,
        uint16 maxMints,
        uint32 nonce
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(SIG_TYPE_RESERVED, collectionId, user, maxMints, nonce, block.chainid))
            );
    }

    // Auction functions

    /**
     * @notice Returns the number of pieces that have been minted in the sale.
     * This exludes the artist 'retained' mints, but does include the reserved mints.
     */
    function _salePiecesMinted() internal view returns (uint256) {
        return totalSupply() - numRetainedMinted;
    }

    /**
     * @notice Returns true if the auction has finished.
     * Note that the auction finishing is not the same as the sale finishing.
     * The auction finishes when the price stops changing, but the sale can
     * continue after that indefinitely until stopped by the artist.
     */
    function _hasAuctionFinished() internal view returns (bool) {
        return block.timestamp >= saleConfig.auctionEndTime;
    }

    function getPrice() external view returns (uint256) {
        return _getPrice();
    }

    /**
     * @notice Returns the current price of the sale.
     * @dev Wrapper for different pricing strategies based on sale type.
     */
    function _getPrice() internal view returns (uint256) {
        if (saleConfig.saleType == SaleType.FixedPrice) {
            return saleConfig.initialPrice;
        }
        if (block.timestamp <= saleConfig.startTime) {
            return saleConfig.initialPrice;
        }
        if (finalSalePrice != 0) {
            return finalSalePrice;
        }
        if (saleConfig.saleType == SaleType.TieredDutchAuction) {
            return _getPriceTieredDA();
        }
        if (saleConfig.saleType == SaleType.ContinuousDutchAuction) {
            return _getPriceContinuousDA();
        }
        revert InvalidConfiguration();
    }

    /**
     * @notice Returns the current price of the sale using a tiered dutch auction pricing strategy.
     * @dev This works by computing the tier that the sale is currently in based on
     * the 'decay period', and then using that bucket to compute the price based on the amount
     * of decay per bucket. Note that the decay rate is defined as the number of basis points
     * from the original price, and does not change over time.
     * For example, a decay rate of 1000 bases points means that the price will decay by 10% of
     * the initial price per bucket. If the price starts at 1 ether, the price will hit 0 ether
     * after 10 buckets.
     */
    function _getPriceTieredDA() internal view returns (uint256) {
        uint256 bucket = (block.timestamp - saleConfig.startTime) / saleConfig.decayPeriodSeconds;
        uint256 delta = (saleConfig.decayRateBasisPoints * bucket * saleConfig.initialPrice) / 10000;
        uint256 maxDelta = saleConfig.initialPrice - saleConfig.finalPrice;
        if (delta > maxDelta) {
            return saleConfig.finalPrice;
        }
        return saleConfig.initialPrice - delta;
    }

    /**
     * @notice Returns the current price of the sale using a continuous dutch auction pricing strategy.
     * @dev This works by computing the time elapsed since the start of the auction, and then interpolating
     * the price based on the initial price and the final price. The interpolation is linear.
     */
    function _getPriceContinuousDA() internal view returns (uint256) {
        uint256 priceDifference = saleConfig.initialPrice - saleConfig.finalPrice;
        uint256 timeDifference = saleConfig.auctionEndTime - saleConfig.startTime;

        uint256 timeElapsed = block.timestamp - saleConfig.startTime;
        uint256 delta = (priceDifference * timeElapsed) / timeDifference;
        uint256 maxDelta = saleConfig.initialPrice - saleConfig.finalPrice;
        if (delta > maxDelta) {
            return saleConfig.finalPrice;
        }
        return saleConfig.initialPrice - delta;
    }

    /**
     * @notice Allows users to claim a rebate if applicable.
     * @dev Rebates are only available if the sale has a rebate, and if:
     * - The auction period has finished, or
     * - The sale has finished (sold out).
     * If the sale has finished, the rebate is calculated based on the final price paid.
     * otherwise, it's based on the final price of the auction.
     */
    function claimRebate(address payable recipient) external {
        uint256 totalRebate = getRebateAmount(msg.sender);
        if (totalRebate == 0) {
            revert NoRebateAvailable();
        }

        delete (mintPrices[msg.sender]);

        // External call, ensure rebate is marked as claimed before calling for reentrancy.
        (bool success, ) = recipient.call{value: totalRebate}("");
        require(success, "Transfer failed");
        emit RebateClaimed(msg.sender, recipient, totalRebate);
    }

    /**
     * @notice Returns the amount of rebate that a user is eligible for.
     */
    function getRebateAmount(address user) public view returns (uint256) {
        // Auction not over yet and no sellout, means you can't claim yet
        // as we don't know the final price.
        if (!_hasAuctionFinished() && finalSalePrice == 0) {
            return 0;
        }

        uint256[] memory amountsPaid = mintPrices[user];
        // We reuse this storage slot to indicate that the rebate has been claimed.
        if (amountsPaid.length == 0) {
            return 0;
        }

        uint256 restingPrice = finalSalePrice > 0 ? finalSalePrice : saleConfig.finalPrice;
        uint256 totalRebate = 0;
        for (uint256 i = 0; i < amountsPaid.length; i++) {
            if (amountsPaid[i] > restingPrice) {
                totalRebate += amountsPaid[i] - restingPrice;
            }
        }
        return totalRebate;
    }

    // ERC721

    /// @notice Returns the URI for token metadata.
    function tokenURI(uint256 tokenId) public view override tokenExists(tokenId) returns (string memory) {
        return albaDelegate.tokenURI(tokenId, collectionConfig.slug);
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ERC165

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721AUpgradeable, AccessControlEnumerable) returns (bool) {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    // ERC2981 + Payments

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        royaltyAmount = (salePrice / 10000) * royaltyConfig.royaltyBasisPoints;
        receiver = paymentSplitterRoyalties;
    }

    /**
     * @notice Returns the amount of payments that can be claimed by the user.
     * @dev The uses msg.sender so can be called by the artist or by Alba.
     */
    function availablePayments() public view returns (uint256) {
        return
            IPaymentSplitter(paymentSplitter).releasable(msg.sender) +
            IPaymentSplitter(paymentSplitterRoyalties).releasable(msg.sender);
    }

    /**
     * Setup the primary sales splitter.
     * @dev We create a splitter for a single user if there's no fee. This is less efficient than just using
     * the artist's address, but it provides consistent UX, and we'll be using this for charity splits even
     * if there's no Alba fee in the future.
     */
    function _setupPrimarySplitter(address artist, address alba, RoyaltyConfig memory conf) internal {
        if (conf.albaPrimaryFeeBasisPoints == 0) {
            address[] memory payeesSingle = new address[](1);
            payeesSingle[0] = payable(artist);
            uint256[] memory sharesSingle = new uint256[](1);
            sharesSingle[0] = 10000;
            paymentSplitter = payable(albaDelegate.paymentSplitterFactory().deploy(payeesSingle, sharesSingle));
            return;
        }

        address[] memory payees = new address[](2);
        payees[0] = payable(artist);
        payees[1] = payable(alba);

        uint256[] memory shares = new uint256[](2);
        shares[0] = 10000 - conf.albaPrimaryFeeBasisPoints;
        shares[1] = conf.albaPrimaryFeeBasisPoints;
        paymentSplitter = payable(albaDelegate.paymentSplitterFactory().deploy(payees, shares));
    }

    /**
     * Setup the secondary sales splitter.
     * @dev Note that it is possible that the artist chooses to not _enforce_ royalties, but we still setup
     * a split contract in case they change that directly in the filter registry later on.
     */
    function _setupSecondarySplitter(address artist, address alba, RoyaltyConfig memory conf) internal {
        if (conf.albaSecondaryFeeBasisPoints == 0) {
            // Otherwise, we need to create a single user splitter.
            address[] memory payeesSingle = new address[](1);
            payeesSingle[0] = payable(artist);
            uint256[] memory sharesSingle = new uint256[](1);
            sharesSingle[0] = 10000;
            paymentSplitterRoyalties = payable(
                albaDelegate.paymentSplitterFactory().deploy(payeesSingle, sharesSingle)
            );
            return;
        }

        // Otherwise, we need to create a splitter for the artist and Alba.
        address[] memory payees = new address[](2);
        payees[0] = payable(artist);
        payees[1] = payable(alba);

        uint256[] memory shares = new uint256[](2);
        shares[0] = 10000 - conf.albaSecondaryFeeBasisPoints;
        shares[1] = conf.albaSecondaryFeeBasisPoints;
        paymentSplitterRoyalties = payable(albaDelegate.paymentSplitterFactory().deploy(payees, shares));
    }

    // 721 On-chain Extensions

    /**
     * @notice Returns the seed of a token.
     * @dev The seed is computed from the seed of the batch in which the given
     * token was minted.
     */
    function tokenSeed(uint256 tokenId) public view tokenExists(tokenId) returns (bytes32) {
        uint24 batchSeed = _ownershipOf(tokenId).extraData;
        return keccak256(abi.encodePacked(address(this), batchSeed, tokenId));
    }

    /**
     * @notice Computes a pseudorandom seed for a mint batch.
     * @dev Even though this process can be gamed in principle, it is extremly
     * difficult to do so in practise. Therefore we can still rely on this to
     * derive fair seeds.
     */
    function _computeBatchSeed(address to) private view returns (uint24) {
        return
            uint24(
                bytes3(keccak256(abi.encodePacked(block.timestamp, block.difficulty, blockhash(block.number - 1), to)))
            );
    }

    /**
     * @dev sets the batch seed on mint.
     */
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

    /**
     * @notice Returns the HTML to render a token.
     * @dev This includes all dependencies and the collection script to allow for rendering of the piece
     * directly in the browser, with no external dependencies.
     */
    function tokenHTML(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
        return
            string(
                albaDelegate.tokenHTML(
                    collectionConfig.uuid,
                    tokenId,
                    tokenSeed(tokenId),
                    collectionConfig.dependencies
                )
            );
    }

    // Admin functions

    /**
     * @notice Sets the delegate for this collection.
     */
    function setDelegate(IAlbaDelegate newDelegate) external onlyManager {
        albaDelegate = newDelegate;
    }

    /**
     * @notice Sets the royalty percentage, in basis points
     */
    function setRoyalyPercentage(uint16 newRoyaltyBasisPoints) external managerOrArtist {
        if (newRoyaltyBasisPoints > 10000) {
            revert InvalidRoyaltyPercentage();
        }
        royaltyConfig.royaltyBasisPoints = newRoyaltyBasisPoints;
    }

    /**
     * @notice Validate a given sale config.
     * @dev Note that the validation here is minimal, and only checks for invariants which
     * would break the contract rather than things which are likely not desired. E.g. (1 second auctions).
     * We do this to allow for maximum flexibility with use cases in the future.
     * The Alba backend will do validation before deployment for those other cases.
     */
    function _validateSaleConfig(SaleConfig memory sc) internal view {
        if (sc.numReserved > sc.maxSalePieces) revert InvalidConfiguration();

        // Ensure the start time is not in the past.
        if (sc.startTime <= block.timestamp) {
            revert InvalidConfiguration();
        }

        // Validation for fixed price
        if (sc.saleType == SaleType.FixedPrice) {
            if (sc.hasRebate || sc.auctionEndTime != 0) {
                revert InvalidConfiguration();
            }
        }

        // Validation for auction config
        if (sc.saleType != SaleType.FixedPrice) {
            if (sc.auctionEndTime == 0 || sc.auctionEndTime <= sc.startTime) {
                revert InvalidConfiguration();
            }

            if (sc.initialPrice <= sc.finalPrice) {
                revert InvalidConfiguration();
            }

            if (sc.saleType == SaleType.TieredDutchAuction) {
                if (sc.decayRateBasisPoints == 0 || sc.decayRateBasisPoints > 10000) {
                    revert InvalidConfiguration();
                }
            }

            // Can't have only reserved pieces in an auction because reserves are not used
            // to set the final price. Must use fixed price sale for this.
            if (sc.numReserved >= sc.maxSalePieces) {
                revert InvalidConfiguration();
            }
        }
    }

    /**
     * @notice Change the auction times for the sale. This can only be called before the
     * sale has started. This can be used to postpone the sale, or to change the auction
     * end time.
     * @param newStartTime The new start time for the sale.
     * @param newEndTime The new end time for the sale. This should be 0 for fixed price sales.
     */
    function changeAuctionTimes(uint40 newStartTime, uint40 newEndTime) external managerOrArtist {
        // Ensure auction has not already started.
        if (block.timestamp >= saleConfig.startTime) {
            revert InvalidConfiguration();
        }
        saleConfig.startTime = newStartTime;
        saleConfig.auctionEndTime = newEndTime;
        _validateSaleConfig(saleConfig);
    }

    /**
     * @notice Close the sale.
     * The auctionEndTime parameter of the config only describes when the price in
     * the auction will stop changing, but does not stop the sale from continuing.
     * This function can be called by the manager or the artist to stop the sale entirely.
     * Warning: this is permanent, and cannot be undone.
     * @dev We don't need to set the finalSalePrice here, because price will have always
     * settled at the auction end price.
     */
    function closeSale() external managerOrArtist {
        if (block.timestamp < saleConfig.startTime) {
            revert SaleNotActive();
        }

        // If the auction has an end time, then don't allow closing the sale until
        // that end time has been reached.
        if (block.timestamp < saleConfig.auctionEndTime) {
            revert AuctionStillActive();
        }

        // Set the sale as closed.
        isSaleClosed = true;
        emit SaleFinished();
    }

    /**
     * @notice Returns the amount of payments that can be flushed to the splitter.
     * Note that this is only applicable for rebate auctions which have finished.
     */
    function flushablePayments() public view returns (uint256) {
        if (!saleConfig.hasRebate || !_hasAuctionFinished() || numRebateMints == 0) {
            return 0;
        }

        uint256 finalValue = finalSalePrice != 0 ? finalSalePrice : saleConfig.finalPrice;
        return numRebateMints * finalValue;
    }

    /**
     * @notice Allow the artist to flush the funds to the payment splitter.
     * @dev For FixedPrice sales, the payment is sent directly to the splitter on each mint.
     * For auctions, the payment is initially buffered in the contract so that rebates can be
     * claimed. We don't know the final price until a sell-out or the auction ends.
     * For simplicity we wait until the end of the auction to allow the artist to flush the funds.
     * At the end of the auction, any subsequent mints will be sent directly to the splitter as
     * we know the final price already.
     * Note that by the time the flush is called, the users may not have claimed their rebates.
     * So to ensure we don't flush too much, we need to store the number of 'rebateMints' i.e.
     * mints which have a *potential* to collect a rebate. We can't use the total number of mints
     * because some of these may have been sold at the final price, and therefore don't have a rebate,
     * and some may be free retained mints.
     */
    function flushPaymentToSplitter() public managerOrArtist {
        // Fixed price sales push to splitter on each mint.
        if (saleConfig.saleType == SaleType.FixedPrice) {
            revert InvalidConfiguration();
        }

        // For simplicity, we require that the auction has finished.
        // This ensures that either 'finalSalePrice' is set due to a sellout, OR
        // any remaining sales will be at the resting price. We therefore know that
        // futher mints are sent to the splitter directly, and we can flush based
        // on the number of (poential) 'rebate mints'.
        if (!_hasAuctionFinished()) {
            revert AuctionStillActive();
        }

        if (numRebateMints == 0) {
            revert InvalidConfiguration(); // Close enough
        }

        uint256 finalValue = finalSalePrice != 0 ? finalSalePrice : saleConfig.finalPrice;
        uint256 totalValue = numRebateMints * finalValue;

        // Set the pending rebates to 0, so that we can't flush twice.
        numRebateMints = 0;

        (bool success, ) = paymentSplitter.call{value: totalValue}("");
        if (!success) revert PaymentFailed();
        emit PaymentFlushed(totalValue);
    }

    /**
     * @notice Convenience function to claim all payments.
     * @dev This can be used by both the artist and Alba to claim their payments.
     * When upgraded to 4.8.X, we can use the `releasable` function to check payments
     * for the specific caller rather than just checking the balance.
     */
    function claimPayments() public artistOrAlbaReceiver {
        IPaymentSplitter splitter = IPaymentSplitter(paymentSplitter);
        IPaymentSplitter splitterRoyalties = IPaymentSplitter(paymentSplitterRoyalties);

        bool claimed = false;
        if (splitter.releasable(msg.sender) > 0) {
            IPaymentSplitter(paymentSplitter).release(payable(msg.sender));
            claimed = true;
        }
        if (splitterRoyalties.releasable(msg.sender) > 0) {
            IPaymentSplitter(paymentSplitterRoyalties).release(payable(msg.sender));
            claimed = true;
        }
        if (claimed) {
            emit PaymentsClaimed(msg.sender);
        }
    }

    /**
     * @notice Allow the artist to assume complete control of the contract.
     * The artist owns the contract at deployment time by default, but Alba
     * is retained as a manager to allow
     */
    function assumeTotalOwnership() external onlyOwner {
        address currentManager = getRoleMember(ROLE_MANAGER, 0);

        // Make the artist the admin of all roles.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Make the artist a manager.
        _grantRole(ROLE_MANAGER, msg.sender);

        // Revoke the existing manager from roles.
        _revokeRole(ROLE_MANAGER, currentManager);
        _revokeRole(DEFAULT_ADMIN_ROLE, currentManager);
        emit AlbaEjected();
    }
}