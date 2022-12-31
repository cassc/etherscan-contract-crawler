// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
import "./Guardian/Erc721LockRegistry.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IBreedingInfo.sol";

// import "hardhat/console.sol";

contract Kubz is
    ERC721x,
    DefaultOperatorFiltererUpgradeable,
    ReentrancyGuardUpgradeable
{
    IBreedingInfo public genesisContract;

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
    event Stake(uint256 indexed tokenId, address indexed by, uint256 stakedAt);
    event Unstake(
        uint256 indexed tokenId,
        address indexed by,
        uint256 stakedAt,
        uint256 unstakedAt
    );

    bool public canBreed;
    // genesis tokenId => (genesis) tokensLastStakedAt[tokenId] => breed count
    mapping(uint256 => mapping(uint256 => uint256)) public breedMap;
    event Breed(
        uint256 indexed genesisTokenId,
        address indexed genesisTokenOwner,
        uint256 babyCount
    );

    // V2
    uint256 public tolStart;
    mapping(uint256 => mapping(address => uint256)) tokenOwnershipsLengths; // tokenId => address => [token] holded how long by [address] in seconds
    mapping(uint256 => uint256) holdingSinceOverride; // tokenId => holdingSince

    function initialize(
        string memory baseURI,
        address genesisContractAddress /*, address signerAddress*/
    ) public initializer {
        ERC721x.__ERC721x_init("Kubz", "Kubz");
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        baseTokenURI = baseURI;
        genesisContract = IBreedingInfo(genesisContractAddress);
        MAX_SUPPLY = 10000;
        BREED_PER_SECONDS = 30 days;
        // signer = signerAddress;
    }

    function initializeV2() public onlyOwner reinitializer(2) {
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
    }

    // =============== AIR DROP ===============

    function airdrop(address receiver, uint256 tokenAmount) external onlyOwner {
        safeMint(receiver, tokenAmount);
    }

    function airdropList(address[] calldata receivers) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        for (uint256 i = 0; i < receivers.length; i++) {
            safeMint(receivers[i], 1);
        }
    }

    function airdropListWithAmounts(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(receivers.length >= 1, "at least 1 receiver");
        for (uint256 i = 0; i < receivers.length; i++) {
            safeMint(receivers[i], amounts[i]);
        }
    }

    function safeMint(address receiver, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "exceed MAX_SUPPLY");
        _mint(receiver, quantity);
    }

    // =============== SUPPLY CONTROL ===============

    function burnSupply(uint256 maxSupplyNew) external onlyOwner {
        require(maxSupplyNew > 0, "new max supply should > 0");
        require(maxSupplyNew < MAX_SUPPLY, "can only reduce max supply");
        require(
            maxSupplyNew >= _totalMinted(),
            "cannot burn more than current supply"
        );
        MAX_SUPPLY = maxSupplyNew;
    }

    // =============== Breed ===============

    function setCanBreed(bool b) external onlyOwner {
        canBreed = b;
    }

    function setBreedPerDays(uint256 d) external onlyOwner {
        require(d >= 1);
        BREED_PER_SECONDS = d * 1 days;
    }

    function getCanBreedCount(uint256 genesisTokenId)
        external
        view
        returns (uint256)
    {
        require(canBreed, "breeding not open");
        require(
            address(genesisContract) != address(0),
            "genesisContract not set"
        );
        uint256 tlsa = genesisContract.getTokenLastStakedAt(genesisTokenId);
        if (tlsa == 0) return 0;
        uint256 stakedForSeconds = block.timestamp - tlsa;
        uint256 canBreedCount = stakedForSeconds / BREED_PER_SECONDS;
        uint256 alreadyBreedCount = breedMap[genesisTokenId][tlsa];
        return canBreedCount - alreadyBreedCount;
    }

    // Breed
    function breed(uint256 genesisTokenId, uint256 count)
        external
        nonReentrant
    {
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
        uint256 tlsa = genesisContract.getTokenLastStakedAt(genesisTokenId);
        require(tlsa > 0, "Genesis tokenId not staking");
        uint256 stakedForSeconds = block.timestamp - tlsa;
        uint256 canBreedCount = stakedForSeconds / BREED_PER_SECONDS;
        uint256 alreadyBreedCount = breedMap[genesisTokenId][tlsa];
        require(
            alreadyBreedCount + count <= canBreedCount,
            "Not ready to breed that many babies"
        );
        breedMap[genesisTokenId][tlsa] += count;
        safeMint(msg.sender, count);
        emit Breed(genesisTokenId, msg.sender, count);
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

    // =============== MARKETPLACE CONTROL ===============
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721x) onlyAllowedOperator(_from) {
        require(
            tokensLastStakedAt[_tokenId] == 0,
            "Cannot transfer staked token"
        );
        recordTransfer(_tokenId);
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721x) onlyAllowedOperator(from) {
        require(
            tokensLastStakedAt[tokenId] == 0,
            "Cannot transfer staked token"
        );
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =============== Stake ===============
    function stake(uint256 tokenId) public nonReentrant {
        require(canStake, "staking not open");
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] == 0, "already staking");
        tokensLastStakedAt[tokenId] = block.timestamp;
        emit Stake(tokenId, msg.sender, tokensLastStakedAt[tokenId]);
    }

    function unstake(uint256 tokenId) public nonReentrant {
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] > 0, "not staking");
        uint256 lsa = tokensLastStakedAt[tokenId];
        tokensLastStakedAt[tokenId] = 0;
        emit Unstake(tokenId, msg.sender, block.timestamp, lsa);
    }

    function setTokensStakeStatus(uint256[] memory tokenIds, bool setStake)
        external
        nonReentrant
    {
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
        require(msg.sender == from, "Sender must be from token owner");
        require(from != to, "From and To must be different");

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

    function getTokenOwnershipLengthOfOwner(uint256 tokenId, address owner)
        public
        view
        returns (uint256)
    {
        uint256 holdingLength = getHoldingLength(tokenId);
        holdingLength += tokenOwnershipsLengths[tokenId][owner];
        return holdingLength;
    }

    function getTokenOwnershipLength(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return getTokenOwnershipLengthOfOwner(tokenId, ownerOf(tokenId));
    }

    function recordTransfer(uint256 tokenId) internal {
        address prevOwner = ownerOf(tokenId);
        // console.log("recordTransfer", explicitOwnershipOf(tokenId).startTimestamp, tolStart);
        uint256 holdingLength = getHoldingLength(tokenId);
        tokenOwnershipsLengths[tokenId][prevOwner] += holdingLength;
        holdingSinceOverride[tokenId] = 0;
    }

    function getTokenOwnershipLengths(uint256[] calldata tokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory ret = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            ret[i] = getTokenOwnershipLengthOfOwner(tokenId, ownerOf(tokenId));
        }
        return ret;
    }
}