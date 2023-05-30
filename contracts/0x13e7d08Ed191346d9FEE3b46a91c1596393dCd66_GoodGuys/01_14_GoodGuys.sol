// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

    /**

       ____                 _    ____                 
      / ___| ___   ___   __| |  / ___|_   _ _   _ ___ 
     | |  _ / _ \ / _ \ / _` | | |  _| | | | | | / __|
     | |_| | (_) | (_) | (_| | | |_| | |_| | |_| \__ \
      \____|\___/ \___/ \__,_|  \____|\__,_|\__, |___/
                                            |___/    
    
                                        goodguysnft.com
    */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IMillionDollarRat.sol";

contract GoodGuys is ERC721Enumerable, Ownable {
    using Strings for uint256;

    /// @dev Emitted when {startSale} is executed and the sale isn't on.
    event SaleStarted();
    /// @dev Emitted when {pauseSale} is executed and the sale is on.
    event SalePaused();
    /// @dev Emitted when {startSale} is executed for the first time.
    event ClaimsReserveUpdated(uint256 indexed reserve);
    /// @dev Emitted when a GG token is claimed based on a Rat held
    event GoodGuyClaimed(uint256 indexed ratId, uint256 indexed goodGuyId);
    /// @dev Emitted when {reveal} is executed (once-only).
    event Reveal(uint256 indexed startingIndex);
    /// @dev Emitted when {setTokenURI} is executed.
    event TokenURISet(string indexed tokenUri);
    /// @dev Emitted when {lockTokenURI} is executed (once-only).
    event TokenURILocked(string indexed tokenUri);

    string public constant GG_PROVENANCE = "79d0a3bd67ca56a46d31ab9ec9cf73be4ea11f259caf82fe301c2aa847a1cb87";
    uint256 public constant MAX_RAT_SUPPLY = 3311;
    uint256 public constant MAX_GG_SUPPLY = 10000;
    uint256 public constant GG_PACK_LIMIT = 10;
    uint256 public constant GG_PRICE = 6 ether / 100;
    uint256 private constant CLAIM_PERIOD_DURATION = 1 weeks;
    uint256 private constant RECLAIM_RESERVE = 150;
    string private constant PLACEHOLDER_SUFFIX = "placeholder.json";
    string private constant METADATA_INFIX = "/metadata/";
    IMillionDollarRat private MDR =
        IMillionDollarRat(0x99B9791D1580BF504a1709d310923A46237c8f2C);

    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public ratClaimsReserve;
    uint256 public ratClaimsCounter;
    mapping(uint256 => bool) public ratClaims;
    bool public saleStarted;
    uint256 public saleStartedAt;
    bool public tokenURILocked;

    // current metadata base prefix
    string private _baseTokenUri;

    // prevent callers from sending ETH directly
    receive() external payable {
        revert();
    }

    // prevent callers from sending ETH directly
    fallback() external payable {
        revert();
    }

    constructor() ERC721("Good Guys", "GG") {
    }

    // ----- PUBLIC -----
    // ------------------
    /*
     * @dev Start or restart distribution. Only callable by the owner.
     * On the first call,
     * - set claim reserve value (once-only)
     * - set sale start timestamp and emit {ClaimsReserveUpdated} (once-only)
     * - emit {SaleStarted}
     *
     * On subsequent calls,
     * - restart sale and emit {SaleStarted} if paused;
     *   otherwise, do nothing
     */
    function startSale() public onlyOwner {
        // will also restart when on pause
        if (!saleStarted) {
            saleStarted = true;
            emit SaleStarted();
        }
        // once-only: set timestamp and update reserve
        if (saleStartedAt == 0) {
            _setRatClaimsReserve();
            saleStartedAt = block.timestamp;
        }
    }

    /*
     * @dev If sale is on, pause it and emit {SalePaused}; otherwise, do nothing.
     *   Only callable by the owner.
     */
    function pauseSale() public onlyOwner {
        if (saleStarted) {
            saleStarted = false;
            emit SalePaused();
        }
    }

    /**
     * @dev Claim GGs based on Rats owned. Implements 6 ways to claim; which one is used
     * depends on the values of the arguments `claimedRatIds`, `from`, and `count`.
     *
     * I. Claim All. Claims as many GGs as there are unclaimed Rats held by the caller.
     * Set `claimedRatIds` to [] (empty array), `from` to 0, and `count` to 0 as well.
     *
     * II. Claim Based On A Specific Rat. Claims a single GG.
     * Set `claimedRatIds` to [`ratId`] (where `ratId` is the identity of a Rat you hold,
     * which hasn't been used to claim a GG), `from` to 0, and `count` to 0 as well.
     *
     * III. Claim Multiple GGs Based On Specific Rats. Same as II, for multiple GGs.
     * Set `claimedRatIds` to [`ratId1`, `ratId2`, ...] (only using identities of the Rats
     * you hold, which haven't been used to claim GGs), `from` to 0, and `count` to 0 as well.
     *
     * IV. Claim Based On The Next Unclaimed. Claims a single GG using the first available
     * Rat held by the caller, which hasn't been used in a claim before.
     * Set `claimedRatIds` to [0] (a single element, 0), `from` to 0, and `count` to 0 as well.
     *
     * V. Claim N. Same as IV, but will claim multiple GGs. Set `claimedRatIds` to [] (empty array),
     * `from` to 0, and `count` to the number of GGs to claim. Make sure you have enough unused Rats.
     *
     * VI. Claim Sequentially. Starting with a specific Rat identity, claim multiple GGs based on
     * the assumption that the Rats are allocated sequentially in the specified range and are all
     * held by the caller. I.e. `claim([], 362, 5)` will attemp to claim GGs based on held Rats
     * #362, #363, #364, #365, #366.
     */
    function claim(
        uint256[] memory claimedRatIds,
        uint256 from,
        uint256 count
    ) public {
        _enforceSaleStarted();
        _enforceClaimPeriod(true);
        if (claimedRatIds.length == 0) {
            if (from == 0 && count == 0) {
                // I. Claim All
                uint256[] memory unclaimed = _listUnclaimed();
                _enforceClaimConditions(unclaimed.length);
                for (uint256 i = 0; i < unclaimed.length; i++) {
                    _straightMintGG(msg.sender, unclaimed[i]);
                }
            } else {
                if (from == 0) {
                    // claim count GGs
                    _enforceClaimConditions(count);
                    for (uint256 i = 0; i < count; i++) {
                        _straightMintGG(msg.sender, _nextUnclaimedRatId());
                    }
                } else {
                    // claim count GGs starting with from
                    _enforceClaimConditions(count);
                    uint256[] memory tokenIds = _enforceSequentialAvailability(
                        from,
                        count
                    );
                    for (uint256 i = 0; i < tokenIds.length; i++) {
                        _straightMintGG(msg.sender, tokenIds[i]);
                    }
                }
            }
        } else {
            if (claimedRatIds.length == 1) {
                if (claimedRatIds[0] == 0) {
                    // claim single GG based on the next unclaimed Rat
                    _enforceClaimConditions(1);
                    _straightMintGG(msg.sender, _nextUnclaimedRatId());
                } else {
                    // claim single GG based on a specific unclaimed Rat
                    _enforceClaimConditions(1);
                    _straightMintGG(msg.sender, claimedRatIds[0]);
                }
            } else {
                // claim multiple GGs based on specific unclaimed Rats
                _enforceClaimConditions(claimedRatIds.length);
                for (uint256 i = 0; i < claimedRatIds.length; i++) {
                    _straightMintGG(msg.sender, claimedRatIds[i]);
                }
            }
        }
        _contemplateStartingIndex();
    }

    /**
     * @dev After the claim period has elapsed, mint unclaimed GGs to the owner.
     */
    function reclaim(uint256 count) public onlyOwner {
        _enforceClaimPeriod(false);
        _enforceClaimConditions(count);
        for (uint256 i = 0; i < count; i++) {
            _straightMintGG(msg.sender, MAX_RAT_SUPPLY);
        }
        _contemplateStartingIndex();
    }

    /**
     * @dev Count Rats owned by the caller, for which GoodGuys NFTs
     * have not yet been claimed.
     */
    function countUnclaimed() public view returns (uint256 result) {
        return _countUnclaimed();
    }

    /**
     * @dev List identities of the Rats owned by the caller, for which
     * GoodGuys NFTs have not yet been claimed.
     */
    function listUnclaimed() public view returns (uint256[] memory result) {
        return _listUnclaimed();
    }

    /**
     * @dev Mint `numberOfGGs` GoodGuys.
     * - Will only mint up to (`MAX_GG_SUPPLY` - `ratClaimsReserve`) GoodGuys.
     * - Will mint up to `GG_PACK_LIMIT` items at once.
     * - Will only mint after the sale is started.
     * - ETH sent must equal (`numberOfGGs` * `GG_PRICE`)
     *
     * @param numberOfGGs The number of GoodGuys NFTs to mint.
     */
    function mintGGs(uint256 numberOfGGs) public payable {
        _enforceSaleStarted();
        require(totalSupply() < MAX_GG_SUPPLY, "SoldOut");
        require(numberOfGGs > 0, "ZeroNFTsRequested");
        require(numberOfGGs <= GG_PACK_LIMIT, "BuyLimitExceeded");
        require(GG_PRICE * numberOfGGs == msg.value, "InvalidETHAmount");
        require((MAX_GG_SUPPLY - ratClaimsReserve) -
                (totalSupply() - ratClaimsCounter) >= numberOfGGs, "MintableSupplyExceeded");

        for (uint256 i = 0; i < numberOfGGs; i++) {
            // TODO: test
            _safeMint(msg.sender, totalSupply() + 1);
        }
        _contemplateStartingIndex();
    }

    /**
     * @dev Set `startingIndex` and allow {tokenURI} to return actual
     * token URIs instead of the placeholder. Emit {Reveal} with
     * `startingIndex` as the argument. Only callable by the owner, and
     * only once.
     */
    function reveal() public onlyOwner {
        require(startingIndex == 0, "StartingIndexAlreadySet");

        // account for pre-sellout reveal
        if (startingIndexBlock == 0) {
            startingIndexBlock = block.number;
        }

        uint256 _start = uint256(blockhash(startingIndexBlock)) % MAX_GG_SUPPLY;

        if (
            (_start > block.number)
                ? ((_start - block.number) > 255)
                : ((block.number - _start) > 255)
        ) {
            _start = uint256(blockhash(block.number - 1)) % MAX_GG_SUPPLY;
        }

        if (_start == 0) {
            _start = _start + 1;
        }

        startingIndex = _start;

        emit Reveal(startingIndex);
    }

    /**
     * @dev Set base token URI. Only callable by the owner and only
     * if token URI hasn't been locked through {lockTokenURI}. Emit
     * TokenURISet with the new value on every successful execution.
     *
     * @param newUri The new base URI to use from this point on.
     */
    function setTokenURI(string memory newUri)
        public
        onlyOwner
        whenUriNotLocked
    {
        _baseTokenUri = newUri;
        emit TokenURISet(_baseTokenUri);
    }

    /**
     * @dev Prevent further modification of the currently set base token URI.
     *  Do nothing if already locked. Emit {TokenURILocked} with the current
     *  base token URI on initial execution. Only callable by the owner.
     */
    function lockTokenURI() public onlyOwner {
        if (!tokenURILocked) {
            tokenURILocked = true;
            emit TokenURILocked(_baseTokenUri);
        }
    }

    /**
     * @dev Withdraw `amount` WEI out of the current balance. Only callable
     * by the owner.
     *
     * @param amount The amount to withdraw, in WEI. Must be greater than 0 and
     * must not exceed the contract balance.
     */
    function withdraw(uint256 amount) public onlyOwner {
        require(amount > 0, "ZeroWEIRequested");
        require(amount <= address(this).balance, "AmountExceedsBalance");
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");

        require(success, "ETHTransferFailed");
    }

    /**
     * @dev Prior to execution of {reveal}, return the placeholder URI for
     * any token minted or claimed; after the execution of {reveal}, return
     * adjusted URIs based on `startingIndex` cyclic shift.
     *
     * @param tokenId Identity of an existing (minted) GG NFT.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "UnknownTokenId");

        string memory result;

        if (startingIndex > 0) {
            result = indexedTokenURI((tokenId + startingIndex) % MAX_GG_SUPPLY);
        } else {
            result = placeholderURI();
        }

        return result;
    }

    // ---- INTERNAL ----
    // ------------------
    function _setRatClaimsReserve() internal {
        ratClaimsReserve = 3310 + RECLAIM_RESERVE;
        emit ClaimsReserveUpdated(ratClaimsReserve);
    }

    function claimPeriodInProgress() internal view returns (bool) {
        return (block.timestamp <= (saleStartedAt + CLAIM_PERIOD_DURATION));
    }

    function _enforceSaleStarted() internal view {
        require(saleStarted, "SaleNotOn");
    }

    function _enforceClaimPeriod(bool on) internal view {
        if (on) {
            require(claimPeriodInProgress(), "ClaimPeriodHasEnded");
        } else {
            require(!claimPeriodInProgress(), "ClaimPeriodHasntEnded");
        }
    }

    function _straightMintGG(address to, uint256 claimedRatId) internal {
        // TODO: test
        _safeMint(to, totalSupply() + 1);
        if (claimedRatId < MAX_RAT_SUPPLY) {
            // enforce rat not claimed
            require(!ratClaims[claimedRatId], "DuplicateClaim");
            // enforce ownership
            require(to == MDR.ownerOf(claimedRatId), "RatNotOwned");

            ratClaims[claimedRatId] = true;
        } // else is being reclaimed by the owner
        ratClaimsCounter++;

        uint256 emitRatId = (claimedRatId < MAX_RAT_SUPPLY) ? 0 : claimedRatId;
        uint256 emitGGId = totalSupply();

        emit GoodGuyClaimed(emitRatId, emitGGId);
    }

    function _contemplateStartingIndex() internal {
        /*
         * If not all GGs have been minted and no one is minting past that point, the
         * code below is not executed, and thus startingIndexBlock is not set. We fix
         * that in {reveal}.
         */
        if (startingIndexBlock == 0 && (totalSupply() == MAX_GG_SUPPLY)) {
            startingIndexBlock = block.number;
        }
    }

    function _countUnclaimed() internal view returns (uint256 result) {
        uint256 count = MDR.balanceOf(msg.sender);

        for (uint256 t = 0; t < count; t++) {
            if (!ratClaims[MDR.tokenOfOwnerByIndex(msg.sender, t)]) {
                result++;
            }
        }
    }

    function _listUnclaimed() internal view returns (uint256[] memory) {
        uint256 tokens = MDR.balanceOf(msg.sender);
        uint256 count = _countUnclaimed();
        uint256[] memory tokensToClaim = new uint256[](count);
        uint256 unclaimedIndex;

        for (uint256 t = 0; t < tokens; t++) {
            uint256 ratId = MDR.tokenOfOwnerByIndex(msg.sender, t);
            if (!ratClaims[ratId]) {
                tokensToClaim[unclaimedIndex] = ratId;
                unclaimedIndex++;
            }
        }

        return tokensToClaim;
    }

    function _nextUnclaimedRatId() internal view returns (uint256 result) {
        uint256 count = MDR.balanceOf(msg.sender);

        for (uint256 t = 0; t < count; t++) {
            uint256 tokenId = MDR.tokenOfOwnerByIndex(msg.sender, t);
            if (!ratClaims[tokenId]) {
                result = tokenId;
                break;
            }
        }

        require(result > 0, "OutOfClaims");
    }

    function _enforceClaimConditions(uint256 count) internal view {
        require(count > 0, "ZeroClaimCount");
        require(ratClaimsReserve >= (ratClaimsCounter + count), "ClaimReserveExceeded");
    }

    function _enforceSequentialAvailability(uint256 from, uint256 count)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 tokens = MDR.balanceOf(msg.sender);
        uint256[] memory tokensToClaim = new uint256[](count);

        for (uint256 t = 0; t < tokens; t++) {
            if (MDR.tokenOfOwnerByIndex(msg.sender, t) == from) {
                for (uint256 f = t; f < (t + count); f++) {
                    uint256 tokenId = MDR.tokenOfOwnerByIndex(msg.sender, f);
                    require(!ratClaims[tokenId], "ImpossibleClaim");
                    tokensToClaim[f - t] = tokenId;
                }
            }
        }

        return tokensToClaim;
    }

    modifier whenUriNotLocked() {
        require(!tokenURILocked, "TokenURILockedErr");
        _;
    }

    function placeholderURI() internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _baseTokenUri,
                    METADATA_INFIX,
                    PLACEHOLDER_SUFFIX
                )
            );
    }

    function indexedTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseTokenUri,
                    METADATA_INFIX,
                    tokenId.toString(),
                    ".json"
                )
            );
    }
}