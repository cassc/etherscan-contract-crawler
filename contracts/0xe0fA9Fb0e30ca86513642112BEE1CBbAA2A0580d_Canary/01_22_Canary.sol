// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721.sol";
import "./utils/Ownable.sol";
import "./utils/NameUtils.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/Base64.sol";
import "./chainlink/VRFConsumerBase.sol";

/**
 * @title The Greats Contract (Codenamed: Canary)
 * @dev Extends OpenZeppelin's ERC721 implementation
 */
contract Canary is ERC721, Ownable, ReentrancyGuard, VRFConsumerBase {
    using Strings for uint256;
    using Address for address;

    // Global variables

    // Constants
    /// @dev Invariant: MAX_SUPPLY to be an even number
    uint256 public constant MAX_SUPPLY = 4608;
    uint256 public constant RESERVE_PRICE = 3 * (10 ** 18);
    uint256 public constant STEEP_CURVE_PERIOD = 86400;
    uint256 public constant GENERAL_CURVE_PERIOD = 7 * 86400;
    uint256 public constant NAME_CHANGE_PRICE = 100000 * (10 ** 18);
    uint16[18] public DEVMINT_METADATA_INDICES = 
        [5, 618, 814, 2291, 2342, 2410, 3140, 4035, 4372, 4499, 1818, 111, 1274, 2331, 2885, 3369, 4268, 4589];
    
    // Artist Attestation Metadata
    string public constant ARTIST_ATTESTATION_METADATA = "ipfs://QmVeJyaLh44i2VsePHbwHaQT89SetXGKstZrjx38sjKGhL";

    // Metadata Variables
    /**
     * @dev There is a predetermined sequence of metadata that 1-1 corresponds to the index on IPFS and Arweave directories
     * Our randomization mechanism works by assigning the token ID with a certain metadata index in a randomized fashion
    */
    string public imageIPFSURIPrefix = "ipfs://QmWWMp4Srk6CC9nuGw7fJz6BfxNw7xT7QBHTtxFVRjQTzU/";
    string public imageArweaveURIPrefix = "ar://placeholder/";
    string public galleryIPFSURIPrefix = "ipfs://QmRv3YCXRYx3v36btcKGnuAXKFqjiWQPW7bGUHWKb9GWGv/";
    string public physicalSpecificationsIPFSURIPrefix = "ipfs://QmNSsUw8Z3H5z2FroCwVVZ32vye9RF3QJKejiFLEnn4pik/";
    mapping(uint256 => bool) public metadataAssigned;
    mapping(uint256 => uint256) public tokenIdToMetadataIndex;

    // Sale variables
    uint256 public immutable STEEP_CURVE_STARTING_PRICE;
    uint256 public immutable GENERAL_CURVE_STARTING_PRICE;
    uint256 public immutable HASHMASKS_DISCOUNT;
    address public immutable HASHMASKS_ADDRESS;
    uint256 public SALE_START;
    bool public salePaused = false;
    uint256 public FINAL_SETTLEMENT_PRICE = 0;
    uint256 public SETTLEMENT_PRICE_SET_TIMESTAMP = 0;
    mapping(address => uint256) public addressToBidExcludingDiscount;

    // Chainlink and Randomization
    mapping(bytes32 => uint256) public requestIdToFirstMintIdInBatch;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256[MAX_SUPPLY] internal indices;
    uint256 internal indicesAssigned = 0;

    // Naming
    address public immutable NCT_ADDRESS;
    mapping(uint256 => string) public tokenName;
    mapping(string => bool) private nameReserved;

    /// @dev The era and subera traits are determined based on the index number of the original metadata sequence
    uint256[7] public eraStartIndices = [0, 6, 814, 1847, 2540, 3518, 4372];

    /// @notice Name of the Eras in the same order as eraStartIndices
    string[7] public eraNames = ["High Renaissance", "Post-Impressionism", "Surrealism", "Cubism", "Pop Art", "Factory Art", "Beltracchi"];

    uint256[33] public subEraStartIndices = [
        0, 1,
        6, 270, 440, 610,
        814,
        1847, 2291, 2321, 2342, 2362, 2410, 2539,
        2540, 2790, 3040, 3140, 3240,
        3518, 3668, 3828, 3956, 4212,
        4372, 4410, 4481, 4510, 4537, 4574, 4581, 4594, 4605
    ];

    /// @notice Name of the Eras in the same order as eraStartIndices
    string[33] public subEraNames = [
        "Rebirth", "Umbra",
        "Starry", "Wheatfield", "Olive Trees", "The Room",
        "The Gambit of Salvator Mundi in the Desert Ocean",
        "Synthetic Vantage", "Synthetic Limited", "Mephisto Voodoo", "Mephisto Plague", "Mephisto Nimbus", "Analytical", "Foundation",
        "Nubian", "Light", "Moon", "Vietnam", "Far East",
        "The Guru", "Unicolor", "Duality", "Solitude", "Angelic",
        "Storming of Jerusalem", "The Witches", "Sieben Schalen der Apokalypse", "Feathers", "Comet", "Gold", "Angel's Hymn", "Fallen Angels", "Crimson Angel"
    ];

    /// Events

    event NameChange(uint256 indexed tokenId, string newName);
    event MetadataAssigned(uint256 indexed tokenId, uint256 indexed metadataIndex);
    event Mint(uint256 indexed tokenId, uint256 price);
    event RequestedRandomness(bytes32 requestId);

    constructor(
        string memory name,
        string memory symbol,
        uint256 steepCurveStartingPrice,
        uint256 generalCurveStartingPrice,
        address nctAddress,
        address hashmasksAddress,
        uint256 hashmasksDiscount,
        address vrfCoordinator,
        address linkToken,
        uint256 chainlinkFee,
        bytes32 chainlinkKeyHash
    )
        VRFConsumerBase(
            vrfCoordinator, // VRF Coordinator
            linkToken // LINK Token
        )
        ERC721(name, symbol)
    {
        require(RESERVE_PRICE > hashmasksDiscount, "Reserve price must be higher than the discount");
        require(steepCurveStartingPrice > generalCurveStartingPrice, "steepCurveStartingPrice is invalid");
        require(generalCurveStartingPrice > RESERVE_PRICE, "generalCurveStartingPrice is invalid");

        STEEP_CURVE_STARTING_PRICE = steepCurveStartingPrice;
        GENERAL_CURVE_STARTING_PRICE = generalCurveStartingPrice;
        NCT_ADDRESS = nctAddress;
        HASHMASKS_ADDRESS = hashmasksAddress;
        HASHMASKS_DISCOUNT = hashmasksDiscount;

        // Chainlink
        keyHash = chainlinkKeyHash;
        fee = chainlinkFee;
    }

    // Public Functions

    /**
     * @notice Calculates the current bid price
     * @dev There are basically two price curves. The steep price curve drops from STEEP_CURVE_STARTING_PRICE TO 
     * GENERAL_CURVE_STARTING_PRICE in STEEP_CURVE_PERIOD time. After that period, the other curve immediately starts
     * and drops from GENERAL_CURVE_STARTING_PRICE to RESERVE_PRICE in GENERAL_CURVE_PERIOD time
     * @return Current bid price including any discount
     * @return Current bid price which doesn't include any discount (Ordinary bid price) 
    */
    function getCurrentBidPriceDetails() public view returns (uint256, uint256) {
        uint256 elapsed = block.timestamp - SALE_START;

        uint256 ordinaryPrice = 0;
        if (elapsed >= STEEP_CURVE_PERIOD + GENERAL_CURVE_PERIOD) {
            ordinaryPrice = RESERVE_PRICE;
        } else {
            if (elapsed < STEEP_CURVE_PERIOD) {
                uint256 priceDrop = ((STEEP_CURVE_STARTING_PRICE - GENERAL_CURVE_STARTING_PRICE) * elapsed) / STEEP_CURVE_PERIOD;
                ordinaryPrice = max(GENERAL_CURVE_STARTING_PRICE, STEEP_CURVE_STARTING_PRICE - priceDrop);
            } else {
                // STEEP_CURVE_PERIOD is subtracted from elapsed to account for the former curve period
                uint256 priceDrop = ((GENERAL_CURVE_STARTING_PRICE - RESERVE_PRICE) * (elapsed - STEEP_CURVE_PERIOD)) / GENERAL_CURVE_PERIOD;
                ordinaryPrice = max(RESERVE_PRICE, GENERAL_CURVE_STARTING_PRICE - priceDrop);
            }
        }

        uint256 discount = 0;
        if (ERC721(HASHMASKS_ADDRESS).balanceOf(msg.sender) > 0) {
            discount = HASHMASKS_DISCOUNT;
        }

        // If the discount is greater than or equal to the ordinary price
        if (discount >= ordinaryPrice) {
            return (0, ordinaryPrice);
        } else {
            return (ordinaryPrice - discount, ordinaryPrice);
        }
    }

    /// @notice Returns integer that represents the era corresponding to the tokenId
    function getTokenEra(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token ID does not exist");
        require(metadataAssigned[tokenId], "Metadata is not assigned to the token yet");

        uint256 metadataIndex = tokenIdToMetadataIndex[tokenId];

        for (uint256 i = eraStartIndices.length - 1; i >= 0; i--) {
            if (metadataIndex >= eraStartIndices[i]) {
                return i;
            }
        }
    }

    /// @notice Returns the era name corresponding to the tokenId
    function getTokenEraName(uint256 tokenId) public view returns (string memory) {
        uint256 tokenEra = getTokenEra(tokenId);
        return eraNames[tokenEra];
    }

    /// @notice Returns integer that represents the sub era corresponding to the tokenId
    function getTokenSubEra(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token ID does not exist");
        require(metadataAssigned[tokenId], "Metadata is not assigned to the token yet");

        uint256 metadataIndex = tokenIdToMetadataIndex[tokenId];

        for (uint256 i = subEraStartIndices.length - 1; i >= 0; i--) {
            if (metadataIndex >= subEraStartIndices[i]) {
                return i;
            }
        }
    }

    /// @notice Returns the sub era name corresponding to the tokenId
    function getTokenSubEraName(uint256 tokenId) public view returns (string memory) {
        uint256 tokenSubEra = getTokenSubEra(tokenId);
        return subEraNames[tokenSubEra];
    }

    /// @inheritdoc ERC721
    /// @notice Returns Base64 encoded JSON metadata for the given tokenId
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(metadataAssigned[tokenId], "Metadata is not assigned to the token yet");

        string memory namePostfix = '"';
        if (bytes(tokenName[tokenId]).length != 0) {
            namePostfix = string(abi.encodePacked(': ', tokenName[tokenId], '"'));
        }

        // Block scoping to avoid stack too deep error
        bytes memory uriPartsOfMetadata;
        {
            uriPartsOfMetadata = abi.encodePacked(
                ', "image": "',
                string(abi.encodePacked(baseURI(), tokenIdToMetadataIndex[tokenId].toString(), '.jpeg')),
                '", "image_arweave_uri": "',
                string(
                    abi.encodePacked(
                        imageArweaveURIPrefix,
                        tokenIdToMetadataIndex[tokenId].toString(),
                        '.jpeg'
                    )
                ),
                '", "gallery_glb_uri": "',
                string(abi.encodePacked(galleryIPFSURIPrefix, getTokenEra(tokenId).toString(), '.glb'))
            );
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name": "Mundi #',
                            tokenId.toString(),
                            namePostfix,
                            ', "description": "The Greats Collection", "attributes": [{ "trait_type": "Era", "value": "',
                            getTokenEraName(tokenId),
                            '"}, { "trait_type": "Sub Era", "value": "',
                            getTokenSubEraName(tokenId),
                            '"}], "physical_specifications_uri": "',
                            string(abi.encodePacked(physicalSpecificationsIPFSURIPrefix, getTokenSubEra(tokenId).toString(), '.json"')),
                            uriPartsOfMetadata,
                            '" }'
                        )
                    )
                )
            );
    }

    /// @inheritdoc ERC721
    function baseURI() public view virtual override returns (string memory) {
        return imageIPFSURIPrefix;
    }

    /// @notice Returns if the name has been reserved already (Case insensitive)
    function isNameReserved(string memory name) public view returns (bool) {
        return nameReserved[NameUtils.toLower(name)];
    }

    // External Functions

    /// @notice Mints initial tokens for the purpose of auctioning off
    function devMint() external onlyOwner {
        require(totalSupply() < DEVMINT_METADATA_INDICES.length, "Dev minting already done");
        require(SALE_START == 0, "Sale has already started");

        for (uint256 i = 0; i < DEVMINT_METADATA_INDICES.length; i++) {
            uint256 mintIndex = MAX_SUPPLY - i - 1;
            _safeMint(msg.sender, mintIndex);
            emit Mint(mintIndex, 0);
            assignMetadataIndexToTokenId(mintIndex, assignIndexWithSeed(DEVMINT_METADATA_INDICES[i]));
        }

        // Even number post condition (For Chainlink batching consistency)
        require(totalSupply() % 2 == 0, "Dev mint number must be even");
    }

    /*
     *  @notice Mints a token for a bid at the current price. 
     *  A portion of the bid may be refunded based on the final settlement price
     *  @dev Minted token is revealed (assigned metadata) after the chainlink callback (Done in batches of two)
     *  Known: There would be a reveal delay of next token mint + Chainlink callback time if the token id is even
     *  Smart contracts are prevented from minting
    */
    function mint() external payable nonReentrant {
        require(msg.sender == tx.origin, "Minter cannot be a contract");
        require(totalSupply() < MAX_SUPPLY, "Sale ended");
        require(addressToBidExcludingDiscount[msg.sender] == 0, "Only one token mintable per address if RESERVE_PRICE is not reached");
        require(SALE_START != 0 && block.timestamp >= SALE_START, "Sale has not started");
        require(!salePaused, "Sale is paused");

        // Transfer any remaining Ether back to the minter
        (uint256 currentBidPrice, uint256 nonDiscountedBidPrice) = getCurrentBidPriceDetails();
        require(msg.value >= currentBidPrice, "Insufficient funds");

        uint256 mintIndex = totalSupply() - DEVMINT_METADATA_INDICES.length; // Offset for dev mints
        _safeMint(msg.sender, mintIndex);

        if (totalSupply() % 2 == 0) {
            require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract");
            bytes32 requestId = requestRandomness(keyHash, fee);
            requestIdToFirstMintIdInBatch[requestId] = mintIndex - 1;
            emit RequestedRandomness(requestId);
        }
        emit Mint(mintIndex, currentBidPrice);

        if (FINAL_SETTLEMENT_PRICE == 0) {
            // Set final settlement price if it's last mint or if the price curve period has ended
            if (totalSupply() == MAX_SUPPLY || nonDiscountedBidPrice == RESERVE_PRICE) {
                FINAL_SETTLEMENT_PRICE = nonDiscountedBidPrice;
                SETTLEMENT_PRICE_SET_TIMESTAMP = block.timestamp;
            } else {
                // It's only considered a bid if the final settlement price is not reached
                addressToBidExcludingDiscount[msg.sender] = nonDiscountedBidPrice;
            }
        }

        // Return back the remaining Ether
        if (msg.value > currentBidPrice) {
            payable(msg.sender).transfer(msg.value - currentBidPrice);
        }
    }

    /// @notice Change name of the given token ID. Cannot be re-named
    /// @dev The caller needs to have given sufficient allowance on NCT to this contract
    function changeName(uint256 tokenId, string memory name) external nonReentrant {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(NameUtils.validateName(name) == true, "Not a valid new name");
        require(bytes(tokenName[tokenId]).length == 0, "Token ID is already named");
        require(isNameReserved(name) == false, "Name is already reserved");

        IERC20(NCT_ADDRESS).transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);
        tokenName[tokenId] = name;
        nameReserved[NameUtils.toLower(name)] = true;
        IERC20(NCT_ADDRESS).burn(NAME_CHANGE_PRICE);
        emit NameChange(tokenId, name);
    }

    /// @notice Refund the difference between the bid by the given address and the settlement price
    function refundDifferenceToBidders(address[] memory bidderAddresses) external nonReentrant {
        require(FINAL_SETTLEMENT_PRICE > 0, "Settlement price not set");

        for (uint256 i = 0; i < bidderAddresses.length; i++) {
            uint256 bidAmountExcludingDiscount = addressToBidExcludingDiscount[bidderAddresses[i]];

            if (bidAmountExcludingDiscount != 0) {
                addressToBidExcludingDiscount[bidderAddresses[i]] = 0;
                payable(bidderAddresses[i]).transfer(
                    bidAmountExcludingDiscount - FINAL_SETTLEMENT_PRICE
                );
            }
        }
    }

    /*
     *  @dev Withdraw ether from this contract (Callable by owner)
     *  3 days grace period for anyone to be able to refund difference to the bidders as a way to minimize trust in the contract owner.
     *  Callable 3 days after the settlement price is set or 3 days after the general curve period ends 
     */
    function withdraw() external onlyOwner {
        require(
            (SETTLEMENT_PRICE_SET_TIMESTAMP != 0 && block.timestamp > SETTLEMENT_PRICE_SET_TIMESTAMP + 3 days) ||
                (block.timestamp > SALE_START + STEEP_CURVE_PERIOD + GENERAL_CURVE_PERIOD + 3 days),
            "Atleast 3 days must pass after settlement price is set or after the general curve period ends"
        );

        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    /// @notice saleStartTimestamp param is ignored if sale start timestamp is already set
    /// @dev Starts / resumes / pauses the sale based on the state (Callable by owner)
    function toggleSale(uint256 saleStartTimestamp) external onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "Sale has ended");

        if (SALE_START == 0) {
            require(saleStartTimestamp >= block.timestamp, "saleStartTimestamp is in the past");
            SALE_START = saleStartTimestamp;
        } else {
            salePaused = !salePaused;
        }
    }

    /// @dev Metadata will be frozen once ownership of the contract is renounced
    function changeURIs(
        string memory imageURI,
        string memory imageArweaveURI,
        string memory galleryURI,
        string memory physicalSpecsURI
    ) external onlyOwner {
        imageIPFSURIPrefix = imageURI;
        imageArweaveURIPrefix = imageArweaveURI;
        galleryIPFSURIPrefix = galleryURI;
        physicalSpecificationsIPFSURIPrefix = physicalSpecsURI;
    }

    // Internal Functions

    /// @dev Callback function used by VRF Coordinator. Assigns metadata to the tokens in a batch of two
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 firstMintIdInBatch = requestIdToFirstMintIdInBatch[requestId];

        uint256[2] memory mintIdsToAssign = [firstMintIdInBatch, firstMintIdInBatch + 1];

        for (uint256 i = 0; i < mintIdsToAssign.length; i++) {
            require(metadataAssigned[mintIdsToAssign[i]] == false, "Metadata already assigned");
            uint256 metadataIndex = assignIndexWithSeed(
                uint256(keccak256(abi.encode(randomness, i)))
            );
            assignMetadataIndexToTokenId(mintIdsToAssign[i], metadataIndex);
        }
    }

    /// @dev Assigns metadata index to token id
    function assignMetadataIndexToTokenId(uint256 tokenId, uint256 metadataIndex) internal {
        tokenIdToMetadataIndex[tokenId] = metadataIndex;
        metadataAssigned[tokenId] = true;
        emit MetadataAssigned(tokenId, metadataIndex);
    }

    /// @dev Generates a random index using the seed and stores it in a mapping for 0(1) complexity in case of repetition
    function assignIndexWithSeed(uint256 seed) internal returns (uint256) {
        uint256 totalSize = MAX_SUPPLY - indicesAssigned;
        uint256 index = seed % totalSize;

        // Credits to Meebits for the following snippet
        uint256 value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // 2 -> indices[2] = 999. indices[1] = 999
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }

        indicesAssigned++;

        return value;
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}