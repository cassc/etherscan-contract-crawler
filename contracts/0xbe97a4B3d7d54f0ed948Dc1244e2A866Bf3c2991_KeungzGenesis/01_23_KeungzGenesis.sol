// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
import "./Guardian/Erc721LockRegistry.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IBreedingInfoV2.sol";
import "./interfaces/IERC721xHelper.sol";
import "./interfaces/IStaminaInfo.sol";
import "./interfaces/ITOLTransfer.sol";

contract KeungzGenesis is
    ERC721x,
    DefaultOperatorFiltererUpgradeable,
    IBreedingInfoV2,
    IERC721xHelper
{
    uint256 public MAX_SUPPLY;

    string public baseTokenURI;
    string public tokenURISuffix;
    string public tokenURIOverride;

    mapping(address => bool) public whitelistedMarketplaces;
    mapping(address => bool) public blacklistedMarketplaces;
    uint8 public marketplaceRestriction;

    // ============ vvv V7: UNUSED vvv ============
    mapping(uint256 => mapping(address => uint256))
        public tokenOwnershipsLengths; // tokenId => address => [token] holded how long by [address] in seconds
    mapping(address => address[]) public addressAssociations;
    mapping(address => mapping(address => bool)) public addressAssociationsMap; // address => association

    event MarketplaceWhitelisted(address indexed market, bool whitelisted);
    event MarketplaceBlacklisted(address indexed market, bool blacklisted);

    mapping(uint256 => mapping(address => uint256)) tolMinusOffset; // tokenId => address => tol offset in seconds
    bool tolOffsetSealed;

    // V5
    bool public canStake;
    mapping(uint256 => uint256) public tokensLastStakedAt; // tokenId => timestamp
    event Stake(uint256 tokenId, address by, uint256 stakedAt);
    event Unstake(
        uint256 tokenId,
        address by,
        uint256 stakedAt,
        uint256 unstakedAt
    );
    // ============ ^^^ V7: UNUSED ^^^ ============

    // V6
    /* V7: Unused */
    mapping(uint256 => bool) public lockedTokenIds; // tokenId => locked
    mapping(address => bool) public lockedTransferToAddresses; // address => locked
    /* V7: Unused */
    mapping(address => bool) public isRescuing;

    // V7
    mapping(uint256 => uint256) public holdingSinceOverride; // tokenId => holdingSince

    // V8+
    IStaminaInfo public kubzRelicContract;
    ITOLTransfer public guardianContract;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory baseURI) public initializer {
        ERC721x.__ERC721x_init("Keungz Genesis", "KZG");
        baseTokenURI = baseURI;
        MAX_SUPPLY = 432;
    }

    function initializeV2() public onlyOwner reinitializer(2) {
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
    }

    function setKubzRelicContract(address _addr) external onlyOwner {
        kubzRelicContract = IStaminaInfo(_addr);
    }

    function setGuardianContract(address _addr) external onlyOwner {
        guardianContract = ITOLTransfer(_addr);
    }

    function airdrop(address receiver, uint256 tokenAmount) external onlyOwner {
        safeMint(receiver, tokenAmount);
    }

    function safeMint(address receiver, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "exceed MAX_SUPPLY");
        _mint(receiver, quantity);
    }

    // =============== TOKEN TRANSFER RECORD ===============
    function oldGetTokenOwnershipLengthOfOwner(
        uint256 tokenId,
        bool withAssociation
    ) public view returns (uint256) {
        TokenOwnership memory ship = explicitOwnershipOf(tokenId);
        address owner = ship.addr;
        uint256 holdingLength = block.timestamp - ship.startTimestamp;
        holdingLength += tokenOwnershipsLengths[tokenId][owner];
        holdingLength -= tolMinusOffset[tokenId][owner];
        if (withAssociation) {
            address[] storage assoArray = addressAssociations[owner];

            for (uint256 i = 0; i < assoArray.length; i++) {
                address asso = assoArray[i];
                // check for mutuals
                if (addressAssociationsMap[asso][owner]) {
                    holdingLength += tokenOwnershipsLengths[tokenId][asso];
                    holdingLength -= tolMinusOffset[tokenId][asso];
                }
            }
        }
        return holdingLength;
    }

    function oldGetTokenOwnershipLengths(uint256[] calldata tokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory ret = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            ret[i] = oldGetTokenOwnershipLengthOfOwner(tokenId, true);
        }
        return ret;
    }

    function getHoldingSince(uint256 tokenId) internal view returns (uint256) {
        if (holdingSinceOverride[tokenId] > 0) {
            return holdingSinceOverride[tokenId];
        }
        return explicitOwnershipOf(tokenId).startTimestamp;
    }

    function getHoldingSinceExternal(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        if (holdingSinceOverride[tokenId] > 0) {
            return holdingSinceOverride[tokenId];
        }
        return explicitOwnershipOf(tokenId).startTimestamp;
    }

    function getHoldingLength(uint256 tokenId) internal view returns (uint256) {
        return block.timestamp - getHoldingSince(tokenId);
    }

    function getTokenOwnershipLength(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return getHoldingLength(tokenId);
    }

    function getTokenOwnershipLengths(uint256[] calldata tokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory ret = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            ret[i] = getTokenOwnershipLength(tokenId);
        }
        return ret;
    }

    function overrideHoldingSince(
        uint256[] calldata tokenIds,
        uint256[] calldata timestamps
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            holdingSinceOverride[tokenIds[i]] = timestamps[i];
        }
    }

    function transferCheck(address _to, uint256 _tokenId) internal {
        if (address(kubzRelicContract) != address(0)) {
            require(
                kubzRelicContract.kzgCanTransfer(_tokenId),
                "Insufficient KzG stamina"
            );
        }
        // require(!lockedTokenIds[_tokenId], "tokenId locked");
        require(!lockedTransferToAddresses[_to], "'to' locked");
        holdingSinceOverride[_tokenId] = 0;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721x) onlyAllowedOperator(_from) {
        transferCheck(_to, _tokenId);
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public virtual override(ERC721x) onlyAllowedOperator(_from) {
        transferCheck(_to, _tokenId);
        super.safeTransferFrom(_from, _to, _tokenId, data);
    }

    function keepTOLTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(
            ownerOf(tokenId) == from,
            "Only token owner can do keep TOL transfer"
        );
        require(msg.sender == from, "Sender must be from token owner");
        require(from != to, "From and To must be different");

        guardianContract.beforeKeepTOLTransfer(from, to);
        
        if (holdingSinceOverride[tokenId] == 0) {
            uint256 holdingSince = explicitOwnershipOf(tokenId).startTimestamp;
            holdingSinceOverride[tokenId] = holdingSince;
        }

        super.transferFrom(from, to, tokenId);
    }


    // =============== MARKETPLACE CONTROL ===============
    function checkGuardianOrMarketplace(address operator) internal view {
        // Always allow guardian contract
        if (approvedContract[operator]) return;
        require(
            !(marketplaceRestriction == 1 && blacklistedMarketplaces[operator]),
            "Please contact Keungz for approval."
        );
        return;
    }

    function approve(address to, uint256 tokenId)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
    {
        checkGuardianOrMarketplace(to);
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
    {
        checkGuardianOrMarketplace(operator);
        super.setApprovalForAll(operator, approved);
    }

    function blacklistMarketplaces(address[] calldata markets, bool blacklisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            blacklistedMarketplaces[market] = blacklisted;
            // emit MarketplaceBlacklisted(market, blacklisted);
        }
    }

    // 0 = no restriction, 1 = blacklist
    function setMarketplaceRestriction(uint8 rule) external onlyOwner {
        marketplaceRestriction = rule;
    }

    function _mayTransfer(address operator, uint256 tokenId)
        private
        view
        returns (bool)
    {
        if (operator == ownerOf(tokenId)) return true;
        checkGuardianOrMarketplace(operator);
        return true;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721AUpgradeable) {
        for (
            uint256 tokenId = startTokenId;
            tokenId < startTokenId + quantity;
            tokenId += 1
        ) {
            if (
                from != address(0) &&
                to != address(0) &&
                !_mayTransfer(msg.sender, tokenId)
            ) {
                revert("KeungzGenesis: illegal operator");
            }
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }


    // =============== BASE URI ===============

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (bytes(tokenURIOverride).length > 0) {
            return tokenURIOverride;
        }
        return string.concat(super.tokenURI(_tokenId), tokenURISuffix);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setTokenURISuffix(string calldata _tokenURISuffix)
        external
        onlyOwner
    {
        if (compareStrings(_tokenURISuffix, "!empty!")) {
            tokenURISuffix = "";
        } else {
            tokenURISuffix = _tokenURISuffix;
        }
    }

    function setTokenURIOverride(string calldata _tokenURIOverride)
        external
        onlyOwner
    {
        if (compareStrings(_tokenURIOverride, "!empty!")) {
            tokenURIOverride = "";
        } else {
            tokenURIOverride = _tokenURIOverride;
        }
    }

    // =============== IBreedingInfoV2 ===============

    function ownerOfGenesis(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    // =============== Transfer Lock ===============
    function setTransferToLocked(address addr, bool locked) external onlyOwner {
        lockedTransferToAddresses[addr] = locked;
    }

    // =============== IERC721xHelper ===============
    function isUnlockedMultiple(uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory part = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = isUnlocked(tokenIds[i]);
        }
        return part;
    }

    function ownerOfMultiple(uint256[] calldata tokenIds)
        external
        view
        returns (address[] memory)
    {
        address[] memory part = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = ownerOf(tokenIds[i]);
        }
        return part;
    }

    function tokenNameByIndexMultiple(uint256[] calldata tokenIds)
        external
        view
        returns (string[] memory)
    {
        string[] memory part = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = tokenNameByIndex(tokenIds[i]);
        }
        return part;
    }
}