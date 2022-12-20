// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
import "./Guardian/Erc721LockRegistry.sol";
import "./OPR/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "./interfaces/IBreedingInfo.sol";

contract KeungzGenesis is
    ERC721x,
    DefaultOperatorFiltererUpgradeable,
    IBreedingInfo
{
    uint256 public MAX_SUPPLY;

    string public baseTokenURI;
    string public tokenURISuffix;
    string public tokenURIOverride;

    // === vvv V5: UNUSED vvv ===
    mapping(address => bool) public whitelistedMarketplaces;
    mapping(address => bool) public blacklistedMarketplaces;
    uint8 public marketplaceRestriction;
    // === ^^^ V5: UNUSED ^^^ ===

    mapping(uint256 => mapping(address => uint256)) tokenOwnershipsLengths; // tokenId => address => [token] holded how long by [address] in seconds
    mapping(address => address[]) addressAssociations;
    mapping(address => mapping(address => bool)) addressAssociationsMap; // address => association

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

    // V6
    mapping(uint256 => bool) public lockedTokenIds; // tokenId => locked
    mapping(address => bool) public lockedTransferToAddresses; // address => locked
    mapping(address => bool) public isRescuing; 

    function initialize(string memory baseURI) public initializer {
        ERC721x.__ERC721x_init("Keungz Genesis", "KZG");
        baseTokenURI = baseURI;
        MAX_SUPPLY = 432;
    }

    function initializeV2() public onlyOwner reinitializer(2) {
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
    }

    // =============== TOKEN TRANSFER RECORD ===============
    function getAssociations(address addr)
        public
        view
        returns (address[] memory)
    {
        return addressAssociations[addr];
    }

    function addAssociations(address[] calldata associations) external {
        require(associations.length >= 1, "at least 1 association");
        address[] storage assoArray = addressAssociations[msg.sender];

        for (uint256 i = 0; i < associations.length; i++) {
            address association = associations[i];
            require(msg.sender != association, "Cannot self associate");
            require(
                !addressAssociationsMap[msg.sender][association],
                "Duplicate association"
            );
            assoArray.push(association);
            addressAssociationsMap[msg.sender][association] = true;
        }
    }

    function resetAssociation() external {
        address[] storage assoArray = addressAssociations[msg.sender];
        require(assoArray.length >= 1, "Nothing to reset");
        uint256 l = assoArray.length;
        for (uint256 i = 0; i < l; i++) {
            address association = assoArray[(l - i) - 1];
            assoArray.pop();
            addressAssociationsMap[msg.sender][association] = false;
        }
        require(assoArray.length == 0, "Failed to reset");
    }

    function getTokenOwnershipLengthOfOwner(
        uint256 tokenId,
        address owner,
        bool withAssociation
    ) public view returns (uint256) {
        uint256 holdingLength = block.timestamp -
            explicitOwnershipOf(tokenId).startTimestamp;
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

    function getTokenOwnershipLength(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return getTokenOwnershipLengthOfOwner(tokenId, ownerOf(tokenId), true);
    }

    function recordTransfer(uint256 tokenId) internal {
        address prevOwner = ownerOf(tokenId);
        uint256 holdingLength = block.timestamp -
            explicitOwnershipOf(tokenId).startTimestamp;
        tokenOwnershipsLengths[tokenId][prevOwner] += holdingLength;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721x) onlyAllowedOperator(_from) {
        // require(!lockedTokenIds[_tokenId], "tokenId locked");
        require(!lockedTransferToAddresses[_to], "'to' locked");

        require(
            tokensLastStakedAt[_tokenId] == 0,
            "Cannot transfer staked token"
        );
        recordTransfer(_tokenId);
        super.transferFrom(_from, _to, _tokenId);
    }

    // V5
    function getTokenOwnershipLengths(
        uint256[] calldata tokenIds,
        bool withAssociation
    ) public view returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            ret[i] = getTokenOwnershipLengthOfOwner(
                tokenId,
                ownerOf(tokenId),
                withAssociation
            );
        }
        return ret;
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

    // V5
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721x) onlyAllowedOperator(from) {
        // require(!lockedTokenIds[tokenId], "tokenId locked");
        require(!lockedTransferToAddresses[to], "'to' locked");

        require(
            tokensLastStakedAt[tokenId] == 0,
            "Cannot transfer staked token"
        );
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =============== TOL OFFSET ===============
    function minusOffsetTOL(
        uint256[] calldata _tokenIds,
        address[] calldata _owners,
        uint256[] calldata _seconds
    ) external onlyOwner {
        require(!tolOffsetSealed, "Already sealed");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tolMinusOffset[_tokenIds[i]][_owners[i]] = _seconds[i];
        }
    }

    function sealTOLOffset() external onlyOwner {
        tolOffsetSealed = true;
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
        emit Stake(tokenId, msg.sender, tokensLastStakedAt[tokenId]);
    }

    function unstake(uint256 tokenId) public {
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

    function getTokenLastStakedAt(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return tokensLastStakedAt[tokenId];
    }

    function ownerOfGenesis(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }

    // =============== Transfer Lock ===============
    // function setTokenIdLocked(uint256 tokenId, bool locked) external onlyOwner {
    //     lockedTokenIds[tokenId] = locked;
    // }

    function setTransferToLocked(address addr, bool locked) external onlyOwner {
        lockedTransferToAddresses[addr] = locked;
    }

    // =============== Rescue ===============
    // function isApprovedForAll(address tokenOwner, address operator)
    //     public
    //     view
    //     virtual
    //     override(ERC721AUpgradeable, IERC721AUpgradeable)
    //     returns (bool)
    // {
    //     if (isRescuing[tokenOwner] && operator == owner()) return true;
    //     return super.isApprovedForAll(tokenOwner, operator);
    // }

    // function rescue(uint256 tokenId) external onlyOwner {
    //     recordTransfer(tokenId);
    //     address tokenOwner = ownerOf(tokenId);
    //     isRescuing[tokenOwner] = true;
    //     super.transferFrom(tokenOwner, owner(), tokenId);
    //     isRescuing[tokenOwner] = false;
    // }
}