// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
import "./Guardian/Erc721LockRegistry.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IBreedingInfoV2.sol";
import "./interfaces/IERC721xHelper.sol";
import "./interfaces/IStaminaInfo.sol";
import "./interfaces/ITOLTransfer.sol";
import "./interfaces/IStakable.sol";
import "./interfaces/IKubzWardrobe.sol";

// import "hardhat/console.sol";

contract Kubz is
    ERC721x,
    IStakable,
    DefaultOperatorFiltererUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721xHelper
{
    IBreedingInfoV2 public genesisContract;

    uint256 public MAX_SUPPLY;
    uint256 public BREED_PER_SECONDS;
    // uint256 public claimStartAfter;
    // mapping(address => bool) public hasClaimed;
    // address public signer;

    string public baseTokenURI;
    string public tokenURISuffix;
    string public tokenURIOverride;

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

    bool public canBreed;
    // genesis tokenId => (genesis) getHoldingSinceExternal(tokenId) => breed count
    mapping(uint256 => mapping(uint256 => uint256)) public breedMap;
    event Breed(
        uint256 indexed genesisTokenId,
        address indexed genesisTokenOwner,
        uint256 babyCount
    );

    // V2
    uint256 public tolStart;
    /* V3: unused */
    mapping(uint256 => mapping(address => uint256)) tokenOwnershipsLengths; // tokenId => address => [token] holded how long by [address] in seconds
    mapping(uint256 => uint256) public holdingSinceOverride; // tokenId => holdingSince

    // V4+
    IStaminaInfo public kubzRelicContract;
    ITOLTransfer public guardianContract;

    // V5
    mapping(address => bool) public whitelistedMarketplaces;
    mapping(address => bool) public blacklistedMarketplaces;
    uint8 public marketplaceRestriction;

    IKubzWardrobe public kwrContract;

    // V?

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory baseURI,
        address genesisContractAddress /*, address signerAddress*/
    ) public initializer {
        ERC721x.__ERC721x_init("Kubz", "Kubz");
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        baseTokenURI = baseURI;
        genesisContract = IBreedingInfoV2(genesisContractAddress);
        MAX_SUPPLY = 10000;
        BREED_PER_SECONDS = 30 days;
        // signer = signerAddress;
    }

    function initializeV2() public onlyOwner reinitializer(2) {
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
    }

    function setKubzWardrobeContract(address _addr) external onlyOwner {
        kwrContract = IKubzWardrobe(_addr);
    }

    function setKubzRelicContract(address _addr) external onlyOwner {
        kubzRelicContract = IStaminaInfo(_addr);
    }

    function setGuardianContract(address _addr) external onlyOwner {
        guardianContract = ITOLTransfer(_addr);
    }

    // =============== AIR DROP ===============

    function airdrop(address receiver, uint256 tokenAmount) external onlyOwner {
        safeMint(receiver, tokenAmount);
    }

    // function airdropList(address[] calldata receivers) external onlyOwner {
    //     require(receivers.length >= 1, "at least 1 receiver");
    //     for (uint256 i = 0; i < receivers.length; i++) {
    //         safeMint(receivers[i], 1);
    //     }
    // }

    function airdropListWithAmounts(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            safeMint(receivers[i], amounts[i]);
        }
    }

    function safeMint(address receiver, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "exceed MAX_SUPPLY");
        _mint(receiver, quantity);
    }

    // =============== Breed ===============

    function setCanBreed(bool b) external onlyOwner {
        canBreed = b;
    }

    function setBreedPerDays(uint256 d) external onlyOwner {
        require(d >= 1);
        BREED_PER_SECONDS = d * 1 days;
    }

    function getCanBreedCount(
        uint256 genesisTokenId
    ) public view returns (uint256) {
        require(canBreed, "breeding not open");
        require(
            address(genesisContract) != address(0),
            "genesisContract not set"
        );
        uint256 hse = genesisContract.getHoldingSinceExternal(genesisTokenId);
        require(hse > 0, "incorrect HoldingSince");
        uint256 holdingForSeconds = block.timestamp - hse;
        uint256 canBreedCount = holdingForSeconds / BREED_PER_SECONDS;
        uint256 alreadyBreedCount = breedMap[genesisTokenId][hse];
        return canBreedCount - alreadyBreedCount;
    }

    function getNextBreed(
        uint256 genesisTokenId
    ) public view returns (uint256) {
        require(canBreed, "breeding not open");
        require(
            address(genesisContract) != address(0),
            "genesisContract not set"
        );
        uint256 hse = genesisContract.getHoldingSinceExternal(genesisTokenId);
        require(hse > 0, "incorrect HoldingSince");
        uint256 holdingForSeconds = block.timestamp - hse; // 65days
        uint256 canBreedCount = holdingForSeconds / BREED_PER_SECONDS; // 65days / 30days = 0
        uint256 alreadyBreedCount = breedMap[genesisTokenId][hse]; // cnt=2
        uint256 availToBreed = canBreedCount - alreadyBreedCount; // cnt=0
        if (availToBreed > 0) return 0;
        // 25 days later
        // uint256 nb = BREED_PER_SECONDS - (holdingForSeconds - (BREED_PER_SECONDS * alreadyBreedCount)) // 30 - (65 - 60) = 25;
        uint256 waitSeconds = (BREED_PER_SECONDS * (alreadyBreedCount + 1)) -
            holdingForSeconds;
        return block.timestamp + waitSeconds;
    }

    // Breed
    function breed(
        uint256 genesisTokenId,
        uint256 count
    ) external nonReentrant {
        require(canBreed, "breeding not open");
        require(
            address(genesisContract) != address(0),
            "genesisContract not set"
        );
        require(
            msg.sender == genesisContract.ownerOfGenesis(genesisTokenId),
            "Not owner of genesis tokenId"
        );
        require(count >= 1, "should breed at least 1");
        uint256 hse = genesisContract.getHoldingSinceExternal(genesisTokenId);
        require(hse > 0, "incorrect HoldingSince");
        uint256 holdingForSeconds = block.timestamp - hse;
        uint256 canBreedCount = holdingForSeconds / BREED_PER_SECONDS;
        uint256 alreadyBreedCount = breedMap[genesisTokenId][hse];
        require(
            alreadyBreedCount + count <= canBreedCount,
            "Not ready to breed that many babies"
        );
        breedMap[genesisTokenId][hse] += count;
        safeMint(msg.sender, count);
        emit Breed(genesisTokenId, msg.sender, count);
    }

    function getCanBreedCountMultiple(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory) {
        uint256[] memory part = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = getCanBreedCount(tokenIds[i]);
        }
        return part;
    }

    function getNextBreedMultiple(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory) {
        uint256[] memory part = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = getNextBreed(tokenIds[i]);
        }
        return part;
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    // =============== BASE URI ===============

    // function compareStrings(
    //     string memory a,
    //     string memory b
    // ) public pure returns (bool) {
    //     return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    // }

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

    // function setTokenURISuffix(
    //     string calldata _tokenURISuffix
    // ) external onlyOwner {
    //     if (compareStrings(_tokenURISuffix, "!empty!")) {
    //         tokenURISuffix = "";
    //     } else {
    //         tokenURISuffix = _tokenURISuffix;
    //     }
    // }

    // function setTokenURIOverride(
    //     string calldata _tokenURIOverride
    // ) external onlyOwner {
    //     if (compareStrings(_tokenURIOverride, "!empty!")) {
    //         tokenURIOverride = "";
    //     } else {
    //         tokenURIOverride = _tokenURIOverride;
    //     }
    // }

    // =============== MARKETPLACE CONTROL ===============
    function transferCheck(uint256 _tokenId) internal {
        // prevents owner from accepting offer at marketplaces if a trait is unequipped recently
        if (address(kwrContract) != address(0)) {
            if (tx.origin == ownerOf(_tokenId)) {
                // TODO: guardian?
                require(
                    block.timestamp >
                        kwrContract.getKWRLockStatusSimple(
                            address(this),
                            _tokenId
                        ),
                    "Token locked because a trait is unequipped recently"
                );
            }
            kwrContract.resetKWRLockStatus(address(this), _tokenId);
        }

        if (address(kubzRelicContract) != address(0)) {
            require(
                kubzRelicContract.kubzCanTransfer(_tokenId),
                "Insufficient Kubz stamina"
            );
        }
        if (approvedContract[msg.sender]) {
            // always allow staked emergency transfer
        } else if (whitelistedMarketplaces[msg.sender]) {
            // also allow but force unstake if wled marketplace tx
            if (tokensLastStakedAt[_tokenId] > 0) {
                uint256 lsa = tokensLastStakedAt[_tokenId];
                tokensLastStakedAt[_tokenId] = 0;
                emit Unstake(_tokenId, lsa, block.timestamp);
            }
        } else {
            // disallow transfer
            require(
                tokensLastStakedAt[_tokenId] == 0,
                "Cannot transfer staked token"
            );
        }
        holdingSinceOverride[_tokenId] = 0;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721x) onlyAllowedOperator(_from) {
        transferCheck(_tokenId);
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public virtual override(ERC721x) onlyAllowedOperator(_from) {
        transferCheck(_tokenId);
        super.safeTransferFrom(_from, _to, _tokenId, data);
    }

    // =============== MARKETPLACE CONTROL ===============
    // function checkGuardianOrMarketplace(address operator) internal view {
    //     // Always allow guardian contract
    //     if (approvedContract[operator]) return;
    //     require(
    //         !(marketplaceRestriction == 1 && blacklistedMarketplaces[operator]),
    //         "Please contact Keungz for approval."
    //     );
    //     return;
    // }

    // function approve(
    //     address to,
    //     uint256 tokenId
    // ) public override(ERC721AUpgradeable, IERC721AUpgradeable) {
    //     checkGuardianOrMarketplace(to);
    //     super.approve(to, tokenId);
    // }

    // function setApprovalForAll(
    //     address operator,
    //     bool approved
    // ) public override(ERC721AUpgradeable, IERC721AUpgradeable) {
    //     checkGuardianOrMarketplace(operator);
    //     super.setApprovalForAll(operator, approved);
    // }

    // function blacklistMarketplaces(
    //     address[] calldata markets,
    //     bool blacklisted
    // ) external onlyOwner {
    //     for (uint256 i = 0; i < markets.length; i++) {
    //         address market = markets[i];
    //         blacklistedMarketplaces[market] = blacklisted;
    //         // emit MarketplaceBlacklisted(market, blacklisted);
    //     }
    // }

    function whitelistMarketplaces(
        address[] calldata markets,
        bool whitelisted
    ) external onlyOwner {
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            whitelistedMarketplaces[market] = whitelisted;
        }
    }

    // // 0 = no restriction, 1 = blacklist
    // function setMarketplaceRestriction(uint8 rule) external onlyOwner {
    //     marketplaceRestriction = rule;
    // }

    // function _mayTransfer(
    //     address operator,
    //     uint256 tokenId
    // ) private view returns (bool) {
    //     if (operator == ownerOf(tokenId)) return true;
    //     checkGuardianOrMarketplace(operator);
    //     return true;
    // }

    // function _beforeTokenTransfers(
    //     address from,
    //     address to,
    //     uint256 startTokenId,
    //     uint256 quantity
    // ) internal virtual override(ERC721AUpgradeable) {
    //     for (
    //         uint256 tokenId = startTokenId;
    //         tokenId < startTokenId + quantity;
    //         tokenId += 1
    //     ) {
    //         if (
    //             from != address(0) &&
    //             to != address(0) &&
    //             !_mayTransfer(msg.sender, tokenId)
    //         ) {
    //             revert("Kubz: illegal operator");
    //         }
    //     }
    //     super._beforeTokenTransfers(from, to, startTokenId, quantity);
    // }

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

    function emitLockUnlockEvents(
        uint256[] calldata tokenIds,
        bool isTokenLocked,
        address approvedContract
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            if (isTokenLocked) {
                emit TokenLocked(tokenId, approvedContract);
            } else {
                emit TokenUnlocked(tokenId, approvedContract);
            }
            unchecked {
                i++;
            }
        }
    }

    // function emitStakeEvents(
    //     uint256[] calldata packedTokenIds
    // ) external onlyOwner {
    //     uint256 packedLength = packedTokenIds.length * 16;
    //     for (uint256 i = 0; i < packedLength; ) {
    //         emit Stake((packedTokenIds[i >> 4] >> ((i & 0xF) << 4)) & 0xFFFF);
    //         unchecked {
    //             i++;
    //         }
    //     }
    // }

    // function emitUnstakeEvents(
    //     uint256[] calldata packedTokenIds
    // ) external onlyOwner {
    //     unchecked {
    //         uint256 packedLength = packedTokenIds.length * 16;
    //         for (uint256 i = 0; i < packedLength; ) {
    //             emit Unstake(
    //                 (packedTokenIds[i >> 4] >> ((i & 0xF) << 4)) & 0xFFFF,
    //                 block.timestamp,
    //                 block.timestamp
    //             );
    //             i++;
    //         }
    //     }
    // }

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

    // =============== TOKEN TRANSFER RECORD ===============
    function keepTOLTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        require(
            ownerOf(tokenId) == from,
            "Only token owner can do keep TOL transfer"
        );
        require(
            msg.sender == from || approvedContract[msg.sender],
            "Sender must be from token owner or approved contract"
        );
        require(from != to, "From and To must be different");

        guardianContract.beforeKeepTOLTransfer(from, to);

        if (holdingSinceOverride[tokenId] == 0) {
            uint256 holdingSince = explicitOwnershipOf(tokenId).startTimestamp;
            holdingSinceOverride[tokenId] = holdingSince;
        }

        super.transferFrom(from, to, tokenId);
    }

    function setTOLStart(uint256 ts) external onlyOwner {
        tolStart = ts;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function getHoldingLength(uint256 tokenId) internal view returns (uint256) {
        uint256 holdingLength;
        if (holdingSinceOverride[tokenId] > 0) {
            holdingLength =
                block.timestamp -
                max(holdingSinceOverride[tokenId], tolStart);
        } else {
            holdingLength =
                block.timestamp -
                max(explicitOwnershipOf(tokenId).startTimestamp, tolStart);
        }
        return holdingLength;
    }

    function getTokenOwnershipLength(
        uint256 tokenId
    ) public view returns (uint256) {
        uint256 holdingLength = getHoldingLength(tokenId);
        // holdingLength += tokenOwnershipsLengths[tokenId][owner];
        holdingLength /= 5;
        return holdingLength;
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