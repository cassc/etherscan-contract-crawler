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
import "./interfaces/IStakable.sol";

// import "hardhat/console.sol";

contract KeungzGenesis is
    ERC721x,
    DefaultOperatorFiltererUpgradeable,
    IBreedingInfoV2,
    IERC721xHelper,
    IStakable
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
    // event Stake(uint256 tokenId, address by, uint256 stakedAt);
    event Stake(uint256 indexed tokenId);

    // event Unstake(
    //     uint256 tokenId,
    //     address by,
    //     uint256 stakedAt,
    //     uint256 unstakedAt
    // );
    event Unstake(
        uint256 indexed tokenId,
        uint256 stakedAtTimestamp,
        uint256 removedFromStakeAtTimestamp
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

    function oldGetTokenOwnershipLengths(
        uint256[] calldata tokenIds
    ) public view returns (uint256[] memory) {
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

    function getHoldingSinceExternal(
        uint256 tokenId
    ) external view returns (uint256) {
        if (holdingSinceOverride[tokenId] > 0) {
            return holdingSinceOverride[tokenId];
        }
        return explicitOwnershipOf(tokenId).startTimestamp;
    }

    function getHoldingLength(uint256 tokenId) internal view returns (uint256) {
        return block.timestamp - getHoldingSince(tokenId);
    }

    function getTokenOwnershipLength(
        uint256 tokenId
    ) public view returns (uint256) {
        return getHoldingLength(tokenId);
    }

    function getTokenOwnershipLengths(
        uint256[] calldata tokenIds
    ) public view returns (uint256[] memory) {
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
        if (approvedContract[msg.sender]) {
            // always allow staked emergency transfer
        } else if (whitelistedMarketplaces[msg.sender]) {
            // also allow but force unstake if wled marketplace tx
            if (tokensLastStakedAt[_tokenId] > 0) {
                uint256 lsa = tokensLastStakedAt[_tokenId];
                tokensLastStakedAt[_tokenId] = 0;
                // emit Unstake(_tokenId, msg.sender, lsa, block.timestamp);
                emit Unstake(_tokenId, lsa, block.timestamp);
            }
        } else {
            // disallow transfer
            require(
                tokensLastStakedAt[_tokenId] == 0,
                "Cannot transfer staked token"
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

    function approve(
        address to,
        uint256 tokenId
    ) public override(ERC721AUpgradeable, IERC721AUpgradeable) {
        checkGuardianOrMarketplace(to);
        super.approve(to, tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721AUpgradeable, IERC721AUpgradeable) {
        checkGuardianOrMarketplace(operator);
        super.setApprovalForAll(operator, approved);
    }

    function blacklistMarketplaces(
        address[] calldata markets,
        bool blacklisted
    ) external onlyOwner {
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            blacklistedMarketplaces[market] = blacklisted;
            // emit MarketplaceBlacklisted(market, blacklisted);
        }
    }

    function whitelistMarketplaces(
        address[] calldata markets,
        bool whitelisted
    ) external onlyOwner {
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            whitelistedMarketplaces[market] = whitelisted;
        }
    }

    // 0 = no restriction, 1 = blacklist
    function setMarketplaceRestriction(uint8 rule) external onlyOwner {
        marketplaceRestriction = rule;
    }

    function _mayTransfer(
        address operator,
        uint256 tokenId
    ) private view returns (bool) {
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

    function compareStrings(
        string memory a,
        string memory b
    ) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(
        uint256 _tokenId
    )
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

    function setTokenURISuffix(
        string calldata _tokenURISuffix
    ) external onlyOwner {
        if (compareStrings(_tokenURISuffix, "!empty!")) {
            tokenURISuffix = "";
        } else {
            tokenURISuffix = _tokenURISuffix;
        }
    }

    function setTokenURIOverride(
        string calldata _tokenURIOverride
    ) external onlyOwner {
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

    // =============== Stake ===============
    function stake(uint256 tokenId) public {
        require(canStake, "staking not open");
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] == 0, "already staking");
        tokensLastStakedAt[tokenId] = block.timestamp;
        // emit Stake(tokenId, msg.sender, tokensLastStakedAt[tokenId]);
        emit Stake(tokenId);
    }

    function unstake(uint256 tokenId) public {
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] > 0, "not staking");
        uint256 lsa = tokensLastStakedAt[tokenId];
        tokensLastStakedAt[tokenId] = 0;
        // emit Unstake(tokenId, msg.sender, lsa, block.timestamp);
        emit Unstake(tokenId, lsa, block.timestamp);
        _emitTokenStatus(tokenId);
    }

    function emitStakeEvents(
        uint256[] calldata packedTokenIds
    ) external onlyOwner {
        uint256 packedLength = packedTokenIds.length * 16;
        for (uint256 i = 0; i < packedLength; ) {
            emit Stake((packedTokenIds[i >> 4] >> ((i & 0xF) << 4)) & 0xFFFF);
            unchecked {
                i++;
            }
        }
    }

    function emitUnstakeEvents(
        uint256[] calldata packedTokenIds
    ) external onlyOwner {
        unchecked {
            uint256 packedLength = packedTokenIds.length * 16;
            for (uint256 i = 0; i < packedLength; ) {
                emit Unstake(
                    (packedTokenIds[i >> 4] >> ((i & 0xF) << 4)) & 0xFFFF,
                    block.timestamp,
                    block.timestamp
                );

                i++;
            }
        }
    }

    function setTokensStakeStatus(
        uint256[] memory tokenIds,
        bool setStake
    ) external {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (setStake) {
                stake(tokenId);
            } else {
                unstake(tokenId);
            }
        }
    }

    function setCanStake(bool b) external onlyOwner {
        canStake = b;
    }

    // =============== IERC721xHelper ===============
    function tokensLastStakedAtMultiple(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory) {
        uint256[] memory part = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = tokensLastStakedAt[tokenIds[i]];
        }
        return part;
    }

    function isUnlockedMultiple(
        uint256[] calldata tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory part = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = isUnlocked(tokenIds[i]);
        }
        return part;
    }

    function ownerOfMultiple(
        uint256[] calldata tokenIds
    ) external view returns (address[] memory) {
        address[] memory part = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = ownerOf(tokenIds[i]);
        }
        return part;
    }

    function tokenNameByIndexMultiple(
        uint256[] calldata tokenIds
    ) external view returns (string[] memory) {
        string[] memory part = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = tokenNameByIndex(tokenIds[i]);
        }
        return part;
    }

    function _emitTokenStatus(uint256 tokenId) internal {
        if (lockCount[tokenId] > 0) {
            emit TokenLocked(tokenId, msg.sender);
        }
        if (tokensLastStakedAt[tokenId] > 0) {
            emit Stake(tokenId);
        }
    }

    function unlockId(uint256 _id) external virtual override {
        require(_exists(_id), "Token !exist");
        _unlockId(_id);
        _emitTokenStatus(_id);
    }

    function freeId(uint256 _id, address _contract) external virtual override {
        require(_exists(_id), "Token !exist");
        _freeId(_id, _contract);
        _emitTokenStatus(_id);
    }
}