// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { ERC721, ERC721Enumerable, Strings } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IStencils is IERC721Enumerable {

    enum BuyerType { Regular, Free, MinimumPrice }

    /// @notice Emitted when the hash of the asset generator is set.
    event AssetGeneratorHashSet(bytes32 indexed assetGeneratorHash);

    /// @notice Emitted when the base URI is set (or re-set).
    event BaseURISet(string baseURI);

    /// @notice Emitted when an account is set as a type of buyer.
    event BuyerSet(address indexed account, BuyerType indexed buyerType, uint128 promotionalQuantity);

    /// @notice Emitted when an account has accepted ownership.
    event OwnershipAccepted(address indexed previousOwner, address indexed owner);

    /// @notice Emitted when owner proposed an account that can accept ownership.
    event OwnershipProposed(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when a token holder purchased a physical copy.
    event PhysicalCopyClaimed(uint256 indexed tokenId, address indexed recipient);

    /// @notice Emitted when the minting parameters have be set.
    event ParametersSet(uint256 startingPrice, uint256 auctionStages, uint256 physicalPrice, uint256 specialsTarget);

    /// @notice Emitted when proceeds have been withdrawn to proceeds destination.
    event ProceedsWithdrawn(address indexed destination, uint256 amount);

    /// @notice Emitted when an account is set as the destination where proceeds will be withdrawn to.
    event ProceedsDestinationSet(address indexed account);

    /*************/
    /*** State ***/
    /*************/

    function LAUNCH_TIMESTAMP() external view returns (uint256 launchTimestamp_);

    function AUCTION_END_TIMESTAMP() external view returns (uint256 auctionEndTimestamp_);

    function MAX_SUPPLY() external view returns (uint128 maxSupply_);

    function assetGeneratorHash() external view returns (bytes32 assetGeneratorHash_);

    function baseURI() external view returns (string memory baseURI_);

    function owner() external view returns (address owner_);

    function pendingOwner() external view returns (address pendingOwner_);

    function physicalPrice() external view returns (uint256 physicalPrice_);

    function auctionStages() external view returns (uint256 auctionStages_);

    function proceedsDestination() external view returns (address proceedsDestination_);

    function startingPricePerTokenMint() external view returns (uint256 startingPricePerTokenMint_);

    function specialCount() external view returns (uint128 specialCount_);

    function specialsTarget() external view returns (uint128 specialsTarget_);

    /***********************/
    /*** Admin Functions ***/
    /***********************/

    function acceptOwnership() external;

    function proposeOwnership(address newOwner_) external;

    function setAssetGeneratorHash(bytes32 assetGeneratorHash_) external;

    function setBaseURI(string calldata baseURI_) external;

    function setBuyerInfos(address[] calldata accounts_, BuyerType[] calldata buyerTypes_, uint128[] calldata quantities_) external;

    function setReseeds(address[] calldata accounts_, uint8[] calldata counts_, uint32[7][] calldata seeds_) external;

    function setParameters(uint256 startingPricePerTokenMint_, uint256 priceStages_, uint256 physicalPrice_, uint128 specialsTarget_) external;

    function setProceedsDestination(address proceedsDestination_) external;

    function withdrawProceeds() external;

    /**************************/
    /*** External Functions ***/
    /**************************/

    function claim(address destination_, uint128 quantity_, uint128 minQuantity_) external payable returns (uint256[] memory tokenIds_);

    function give(address[] calldata destinations_, uint256[] calldata amounts_, bool[] calldata physicals_) external;

    function purchase(address destination_, uint128 quantity_, uint128 minQuantity_) external payable returns (uint256[] memory tokenIds_);

    function purchasePhysical(uint256 tokenId_) external payable;

    /***************/
    /*** Getters ***/
    /***************/

    function availableSupply() external view returns (uint256 availableSupply_);

    function buyerInfoFor(address account_) external view returns (BuyerType buyerType_, uint128 promotionalQuantity_);

    function reseedInfoFor(address account_) external view returns (uint8 count_, uint32[7] memory seeds_);

    function contractURI() external view returns (string memory contractURI_);

    function currentAuctionStage() external view returns (uint256 auctionStage_);

    function getPurchaseInformationFor(address buyer_) external view returns (
        bool canClaim_,
        uint256 claimableQuantity_,
        uint256 price_,
        bool physicalCopyIncluded_,
        bool specialIncluded_,
        uint256 auctionStage_,
        uint256 timeRemaining_
    );

    function isLive() external view returns (bool isLive_);

    function isPriceStatic() external view returns (bool priceIsStatic_);

    function physicalCopyRecipient(uint256 tokenId_) external view returns (address physicalCopyRecipient_);

    function pricePerTokenMint() external view returns (uint256 pricePerTokenMint_);

    function timeToLaunch() external view returns (uint256 timeToLaunch_);

    function tokensOfOwner(address owner_) external view returns (uint256[] memory tokenIds_);

}

contract Stencils is IStencils, ERC721Enumerable {

    struct BuyerInfo {
        BuyerType buyerType;
        uint128 quantity;
    }

    struct ReseedInfo {
        uint8 count;
        uint32[7] seeds;
    }

    using Strings for uint256;

    uint128 public immutable MAX_SUPPLY;
    uint256 public immutable LAUNCH_TIMESTAMP;
    uint256 public immutable AUCTION_END_TIMESTAMP;

    address public owner;
    address public pendingOwner;
    address public proceedsDestination;

    bytes32 public assetGeneratorHash;

    string public baseURI;

    uint256 public startingPricePerTokenMint;
    uint256 public auctionStages;
    uint256 public physicalPrice;

    uint128 public specialsTarget;
    uint128 public specialCount;

    mapping(uint256 => address) public physicalCopyRecipient;

    mapping(address => BuyerInfo) public buyerInfoFor;

    mapping(address => ReseedInfo) internal _reseedInfoFor;

    constructor (
        string memory baseURI_,
        uint128 maxSupply_,
        uint256 launchTimestamp_,
        uint256 auctionEndTimestamp_,
        uint256 startingPricePerTokenMint_,
        uint256 auctionStages_,
        uint256 physicalPrice_,
        uint128 specialsTarget_
    ) ERC721("Stencils", "STEN") {
        baseURI = baseURI_;
        MAX_SUPPLY = maxSupply_;
        LAUNCH_TIMESTAMP = launchTimestamp_;
        AUCTION_END_TIMESTAMP = auctionEndTimestamp_;
        startingPricePerTokenMint = startingPricePerTokenMint_;
        require((auctionStages = auctionStages_) > 0, "INVALID_STAGES");
        physicalPrice = physicalPrice_;
        specialsTarget = specialsTarget_;

        owner = msg.sender;
    }

    modifier onlyAfterLaunch() {
        require(block.timestamp >= LAUNCH_TIMESTAMP, "NOT_LAUNCHED_YET");
        _;
    }

    modifier onlyBeforeLaunch() {
        require(block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "UNAUTHORIZED");
        _;
    }

    /***********************/
    /*** Admin Functions ***/
    /***********************/

    function acceptOwnership() external {
        require(pendingOwner == msg.sender, "UNAUTHORIZED");

        emit OwnershipAccepted(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }

    function proposeOwnership(address newOwner_) external onlyOwner {
        emit OwnershipProposed(owner, pendingOwner = newOwner_);
    }

    function setAssetGeneratorHash(bytes32 assetGeneratorHash_) external onlyOwner {
        require(assetGeneratorHash == bytes32(0) || block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");
        emit AssetGeneratorHashSet(assetGeneratorHash = assetGeneratorHash_);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        emit BaseURISet(baseURI = baseURI_);
    }

    function setBuyerInfos(address[] calldata accounts_, BuyerType[] calldata buyerTypes_, uint128[] calldata quantities_) external onlyOwner onlyBeforeLaunch {
        for (uint256 i; i < accounts_.length;) {
            address account = accounts_[i];
            BuyerType buyerType = buyerTypes_[i];
            uint128 quantity = quantities_[i];

            buyerInfoFor[account] = BuyerInfo(buyerType, quantity);

            emit BuyerSet(account, buyerType, quantity);

            unchecked {
                ++i;
            }
        }
    }

    function setReseeds(address[] calldata accounts_, uint8[] calldata counts_, uint32[7][] calldata seeds_) external onlyOwner onlyBeforeLaunch {
        for (uint256 i; i < accounts_.length;) {
            uint8 count = counts_[i];
            uint32[7] calldata seeds = seeds_[i];

            for (uint256 j; j < 7;) {
                // The seed at a position should be zero if its position is the count or greater.
                // The seed at a position should be non-zero if its position is lower than the count.
                require((seeds[j] == uint32(0)) == (j >= count), "INVALID_COUNT");

                unchecked {
                    ++j;
                }
            }

            _reseedInfoFor[accounts_[i]] = ReseedInfo(count, seeds);

            unchecked {
                ++i;
            }
        }
    }

    function setParameters(
        uint256 startingPricePerTokenMint_,
        uint256 auctionStages_,
        uint256 physicalPrice_,
        uint128 specialsTarget_
    ) external onlyOwner onlyBeforeLaunch {
        require(auctionStages_ > 0, "INVALID_STAGES");

        emit ParametersSet(
            startingPricePerTokenMint = startingPricePerTokenMint_,
            auctionStages = auctionStages_,
            physicalPrice = physicalPrice_,
            specialsTarget = specialsTarget_
        );
    }

    function setProceedsDestination(address proceedsDestination_) external onlyOwner {
        require(proceedsDestination == address(0) || block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");
        emit ProceedsDestinationSet(proceedsDestination = proceedsDestination_);
    }

    function withdrawProceeds() external {
        uint256 amount = address(this).balance;
        address destination = proceedsDestination;
        destination = destination == address(0) ? owner : destination;

        require(_transferEther(destination, amount), "ETHER_TRANSFER_FAILED");
        emit ProceedsWithdrawn(destination, amount);
    }

    /**************************/
    /*** External Functions ***/
    /**************************/

    function claim(address destination_, uint128 quantity_, uint128 minQuantity_) external payable onlyAfterLaunch returns (uint256[] memory tokenIds_) {
        require(destination_ != address(0), "INVALID_DESTINATION");

        uint128 count = _getMintCount(quantity_, minQuantity_);

        // Compute the price this purchase will cost.
        BuyerInfo storage buyerInfo = buyerInfoFor[msg.sender];

        // Prevent a non-preferred buyer from claiming.
        require(buyerInfo.buyerType != BuyerType.Regular, "NOT_GRANTED");

        // Prevent a preferred buyer from claiming more than was alloted with this function.
        require(buyerInfo.quantity >= count, "NOT_GRANTED");

        // If the buyer type is MinimumPrice, then compute the total cost, else it is free. Regular buyers would have buyerInfo.quantity = 0;
        uint256 totalCost;
        unchecked {
            totalCost = buyerInfo.buyerType == BuyerType.MinimumPrice
                ? count * _pricePerTokenMint(auctionStages)
                : 0;
        }

        if (buyerInfo.quantity == count) {
            // Delete the buyer info if quantity exactly used.
            delete buyerInfoFor[msg.sender];
        } else {
            // Else, try to decrement, which will error if trying to claim more than alloted.
            buyerInfo.quantity -= count;
        }

        _checkAndRefundEther(totalCost);

        // Initialize the array of token IDs to a length of the nfts to be purchased.
        tokenIds_ = new uint256[](count);

        while (count > 0) {
            unchecked {
                // Get a pseudo random number and generate a token id to mint the molecule NFT.
                _givePhysical(
                    tokenIds_[--count] = _giveToken(destination_, false)
                );
            }
        }
    }

    function give(address[] calldata destinations_, uint256[] calldata amounts_, bool[] calldata physicals_) external onlyOwner onlyBeforeLaunch {
        for (uint256 i; i < destinations_.length;) {
            for (uint256 j; j < amounts_[i];) {
                uint256 tokenId = _giveToken(destinations_[i], false);

                if (physicals_[i]) {
                    _givePhysical(tokenId);
                }

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function purchase(address destination_, uint128 quantity_, uint128 minQuantity_) external payable onlyAfterLaunch returns (uint256[] memory tokenIds_) {
        require(destination_ != address(0), "INVALID_DESTINATION");

        uint128 count = _getMintCount(quantity_, minQuantity_);

        // Compute the price this purchase will cost.
        uint256 totalCost;
        unchecked {
            totalCost = pricePerTokenMint() * count;
        }

        _checkAndRefundEther(totalCost);

        uint256 auctionStage = currentAuctionStage();

        // Initialize the array of token IDs to a length of the nfts to be purchased.
        tokenIds_ = new uint256[](count);

        while (count > 0) {
            unchecked {
                // Get a pseudo random number and generate a token id to mint the molecule NFT.
                tokenIds_[--count] = _giveToken(destination_, auctionStage == 1);
            }

            if (auctionStage > 2) continue;

            _givePhysical(tokenIds_[count]);
        }
    }

    function purchasePhysical(uint256 tokenId_) external payable {
        require(ownerOf(tokenId_) == msg.sender, "NOT_OWNER");
        _checkAndRefundEther(physicalPrice);
        _givePhysical(tokenId_);
    }

    /***************/
    /*** Getters ***/
    /***************/

    function availableSupply() external view returns (uint256 availableSupply_) {
        availableSupply_ = MAX_SUPPLY - totalSupply();
    }

    function contractURI() external view returns (string memory contractURI_) {
        return baseURI;
    }

    function currentAuctionStage() public view returns (uint256 auctionStage_) {
        if (block.timestamp >= AUCTION_END_TIMESTAMP) return auctionStages;

        if (block.timestamp < LAUNCH_TIMESTAMP) return 0;

        auctionStage_ = 1 + (auctionStages * (block.timestamp - LAUNCH_TIMESTAMP)) / (AUCTION_END_TIMESTAMP - LAUNCH_TIMESTAMP);
    }

    function getPurchaseInformationFor(address buyer_) external view returns (
        bool canClaim_,
        uint256 claimableQuantity_,
        uint256 price_,
        bool physicalCopyIncluded_,
        bool specialIncluded_,
        uint256 auctionStage_,
        uint256 timeRemaining_
    ) {
        BuyerInfo memory buyerInfo = buyerInfoFor[buyer_];

        canClaim_ = buyerInfo.buyerType != BuyerType.Regular;
        claimableQuantity_ = buyerInfo.quantity;

        price_ = buyerInfo.buyerType == BuyerType.Free
            ? 0
            : buyerInfo.buyerType == BuyerType.MinimumPrice
                ? _pricePerTokenMint(auctionStages)
                : pricePerTokenMint();

        auctionStage_ = currentAuctionStage();

        physicalCopyIncluded_ = canClaim_ || auctionStage_ == 1 || auctionStage_ == 2;

        specialIncluded_ = auctionStage_ == 1;

        timeRemaining_ = auctionStage_ == 0
            ? LAUNCH_TIMESTAMP - block.timestamp
            : auctionStage_ == 4
                ? 0
                : LAUNCH_TIMESTAMP + auctionStage_ * (AUCTION_END_TIMESTAMP - LAUNCH_TIMESTAMP) / auctionStages - block.timestamp;
    }

    function isLive() external view returns (bool isLive_) {
        isLive_ = block.timestamp >= LAUNCH_TIMESTAMP;
    }

    function isPriceStatic() external view returns (bool priceIsStatic_) {
        priceIsStatic_ = block.timestamp >= AUCTION_END_TIMESTAMP;
    }

    function pricePerTokenMint() public view returns (uint256 pricePerTokenMint_) {
        pricePerTokenMint_ = _pricePerTokenMint(currentAuctionStage());
    }

    function reseedInfoFor(address account_) external view returns (uint8 count_, uint32[7] memory seeds_) {
        ReseedInfo memory reseedInfo = _reseedInfoFor[account_];
        count_ = reseedInfo.count;
        seeds_ = reseedInfo.seeds;
    }

    function timeToLaunch() external view returns (uint256 timeToLaunch_) {
        timeToLaunch_ = LAUNCH_TIMESTAMP > block.timestamp ? LAUNCH_TIMESTAMP - block.timestamp : 0;
    }

    function tokensOfOwner(address owner_) public view returns (uint256[] memory tokenIds_) {
        uint256 balance = balanceOf(owner_);

        tokenIds_ = new uint256[](balance);

        for (uint256 i; i < balance;) {
            tokenIds_[i] = tokenOfOwnerByIndex(owner_, i);

            unchecked {
                ++i;
            }
        }
    }

    function tokenURI(uint256 tokenId_) public override view returns (string memory tokenURI_) {
        require(_exists(tokenId_), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURICache = baseURI;

        tokenURI_ = bytes(baseURICache).length > 0 ? string(abi.encodePacked(baseURICache, "/", tokenId_.toString())) : "";
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _beforeTokenTransfer(address from_, address to_, uint256 tokenId_) internal override {
        // Can mint before launch, but transfers and burns can only happen after launch.
        require(from_ == address(0) || block.timestamp >= LAUNCH_TIMESTAMP, "NOT_LAUNCHED_YET");
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }

    function _checkAndRefundEther(uint256 totalCost_) internal {
        // Require that enough ether was provided.
        require(msg.value >= totalCost_, "INSUFFICIENT_VALUE");

        if (msg.value > totalCost_) {
            // If extra, require that it is successfully returned to the caller.
            unchecked {
                require(_transferEther(msg.sender, msg.value - totalCost_), "REFUND_FAILED");
            }
        }
    }

    function _generatePseudoRandomNumber() internal view returns (uint256 pseudoRandomNumber_) {
        unchecked {
            pseudoRandomNumber_ = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, totalSupply(), gasleft())));
        }
    }

    function _generateSeed(uint256 pseudoRandomNumber_, bool special_) internal pure returns (uint32 seed_) {
        // Keep only 32 bits of pseudoRandomNumber.
        seed_ = uint32(pseudoRandomNumber_ >> 224);

        // Set/unset the special marker.
        if (special_) {
            // If special, ensure 11th bit from right is set.
            seed_ |= 1 << 10;
        } else {
            // If not special, ensure 11th bit from right is not set.
            seed_ &= ~(uint32(1) << 10);
        }
    }

    function _generateTokenId(uint32 seed_, uint32 sequence_) internal pure returns (uint256 tokenId_) {
        // Prepend (add to the left) seed with sequence.
        tokenId_ = uint256(seed_) + (uint256(sequence_) << 32);
    }

    function _getMintCount(uint128 quantity_, uint128 minQuantity_) internal view returns (uint128 mintCount_) {
        // Get the number of stencils available and determine how many stencils will be purchased in this call.
        uint128 available = uint128(MAX_SUPPLY - totalSupply());
        mintCount_ = available >= quantity_ ? quantity_ : available;

        // Prevent a purchase of 0 stencils, as well as a purchase of less stencils than the user expected.
        require(mintCount_ != 0, "NO_STENCILS_AVAILABLE");
        require(mintCount_ >= minQuantity_, "CANNOT_FULLFIL_REQUEST");
    }

    function _givePhysical(uint256 tokenId_) internal {
        require(physicalCopyRecipient[tokenId_] == address(0), "ALREADY_CLAIMED");

        emit PhysicalCopyClaimed(
            tokenId_,
            physicalCopyRecipient[tokenId_] = ownerOf(tokenId_)
        );
    }

    function _giveToken(address destination_, bool special_) internal returns (uint256 tokenId_) {
        require(MAX_SUPPLY > totalSupply(), "NO_STENCILS_AVAILABLE");

        // Can safely cast because MAX_SUPPLY < 4_294_967_295.
        uint32 sequence = uint32(totalSupply() + 1);

        ReseedInfo storage reseedInfo = _reseedInfoFor[msg.sender];

        uint8 seedCount = reseedInfo.count;

        if (seedCount > 0) {
            // Reduce the seed count so that it is a valid index and a valid new seed count.
            --seedCount;

            _mint(
                destination_,
                tokenId_ = _generateTokenId(
                    reseedInfo.seeds[seedCount],
                    sequence
                )
            );

            // Clear the seed at that index and set the new seed count.
            reseedInfo.seeds[seedCount] = 0;
            reseedInfo.count = seedCount;
        } else {
            // If not explicitly giving a special, then if there is still special supply, there is a 5% chance of getting one anyway.
            if (!special_ && (specialCount < specialsTarget)) {
                special_ = (_generatePseudoRandomNumber() % 20) == 0;
            }

            if (special_) {
                ++specialCount;
            }

            // Get a pseudo random number and generate a token id from the moleculeType and randomNumber (saving it in the array of token IDs) and mint the molecule NFT.
            _mint(destination_, tokenId_ = _generateTokenId(_generateSeed(_generatePseudoRandomNumber(), special_), sequence));
        }
    }

    function _pricePerTokenMint(uint256 auctionStage_) internal view returns (uint256 pricePerTokenMint_) {
        pricePerTokenMint_ = startingPricePerTokenMint;

        while (auctionStage_ > 1) {
            pricePerTokenMint_ /= 2;
            --auctionStage_;
        }
    }

    function _transferEther(address destination_, uint256 amount_) internal returns (bool success_) {
        ( success_, ) = destination_.call{ value: amount_ }("");
    }

}