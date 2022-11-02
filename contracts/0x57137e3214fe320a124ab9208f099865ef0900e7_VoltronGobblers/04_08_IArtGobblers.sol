// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IArtGobblers {
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event ArtGobbled(address indexed user, uint256 indexed gobblerId, address indexed nft, uint256 id);
    event GobblerClaimed(address indexed user, uint256 indexed gobblerId);
    event GobblerPurchased(address indexed user, uint256 indexed gobblerId, uint256 price);
    event GobblersRevealed(address indexed user, uint256 numGobblers, uint256 lastRevealedId);
    event GooBalanceUpdated(address indexed user, uint256 newGooBalance);
    event LegendaryGobblerMinted(address indexed user, uint256 indexed gobblerId, uint256[] burnedGobblerIds);
    event OwnerUpdated(address indexed user, address indexed newOwner);
    event RandProviderUpgraded(address indexed user, address indexed newRandProvider);
    event RandomnessFulfilled(uint256 randomness);
    event RandomnessRequested(address indexed user, uint256 toBeRevealed);
    event ReservedGobblersMinted(address indexed user, uint256 lastMintedGobblerId, uint256 numGobblersEach);
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    function BASE_URI() external view returns (string memory);
    function FIRST_LEGENDARY_GOBBLER_ID() external view returns (uint256);
    function LEGENDARY_AUCTION_INTERVAL() external view returns (uint256);
    function LEGENDARY_GOBBLER_INITIAL_START_PRICE() external view returns (uint256);
    function LEGENDARY_SUPPLY() external view returns (uint256);
    function MAX_MINTABLE() external view returns (uint256);
    function MAX_SUPPLY() external view returns (uint256);
    function MINTLIST_SUPPLY() external view returns (uint256);
    function RESERVED_SUPPLY() external view returns (uint256);
    function UNREVEALED_URI() external view returns (string memory);
    function acceptRandomSeed(bytes32, uint256 randomness) external;
    function addGoo(uint256 gooAmount) external;
    function approve(address spender, uint256 id) external;
    function balanceOf(address owner) external view returns (uint256);
    function burnGooForPages(address user, uint256 gooAmount) external;
    function claimGobbler(bytes32[] memory proof) external returns (uint256 gobblerId);
    function community() external view returns (address);
    function currentNonLegendaryId() external view returns (uint128);
    function getApproved(uint256) external view returns (address);
    function getCopiesOfArtGobbledByGobbler(uint256, address, uint256) external view returns (uint256);
    function getGobblerData(uint256) external view returns (address owner, uint64 idx, uint32 emissionMultiple);
    function getGobblerEmissionMultiple(uint256 gobblerId) external view returns (uint256);
    function getTargetSaleTime(int256 sold) external view returns (int256);
    function getUserData(address)
        external
        view
        returns (uint32 gobblersOwned, uint32 emissionMultiple, uint128 lastBalance, uint64 lastTimestamp);
    function getUserEmissionMultiple(address user) external view returns (uint256);
    function getVRGDAPrice(int256 timeSinceStart, uint256 sold) external view returns (uint256);
    function gobble(uint256 gobblerId, address nft, uint256 id, bool isERC1155) external;
    function gobblerPrice() external view returns (uint256);
    function gobblerRevealsData()
        external
        view
        returns (uint64 randomSeed, uint64 nextRevealTimestamp, uint56 lastRevealedId, uint56 toBeRevealed, bool waitingForSeed);
    function goo() external view returns (address);
    function gooBalance(address user) external view returns (uint256);
    function hasClaimedMintlistGobbler(address) external view returns (bool);
    function isApprovedForAll(address, address) external view returns (bool);
    function legendaryGobblerAuctionData() external view returns (uint128 startPrice, uint128 numSold);
    function legendaryGobblerPrice() external view returns (uint256);
    function logisticLimit() external view returns (int256);
    function logisticLimitDoubled() external view returns (int256);
    function merkleRoot() external view returns (bytes32);
    function mintFromGoo(uint256 maxPrice, bool useVirtualBalance) external returns (uint256 gobblerId);
    function mintLegendaryGobbler(uint256[] memory gobblerIds) external returns (uint256 gobblerId);
    function mintReservedGobblers(uint256 numGobblersEach) external returns (uint256 lastMintedGobblerId);
    function mintStart() external view returns (uint256);
    function name() external view returns (string memory);
    function numMintedForReserves() external view returns (uint256);
    function numMintedFromGoo() external view returns (uint128);
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) external returns (bytes4);
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external returns (bytes4);
    function owner() external view returns (address);
    function ownerOf(uint256 id) external view returns (address owner);
    function pages() external view returns (address);
    function randProvider() external view returns (address);
    function removeGoo(uint256 gooAmount) external;
    function requestRandomSeed() external returns (bytes32);
    function revealGobblers(uint256 numGobblers) external;
    function safeTransferFrom(address from, address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function setOwner(address newOwner) external;
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
    function symbol() external view returns (string memory);
    function targetPrice() external view returns (int256);
    function team() external view returns (address);
    function tokenURI(uint256 gobblerId) external view returns (string memory);
    function transferFrom(address from, address to, uint256 id) external;
    function upgradeRandProvider(address newRandProvider) external;
}