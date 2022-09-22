// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
import "./Guardian/Erc721LockRegistry.sol";

contract KeungzGenesis is ERC721x {
    uint256 public MAX_SUPPLY;

    string public baseTokenURI;
    string public tokenURISuffix;
    string public tokenURIOverride;

    mapping(address => bool) public whitelistedMarketplaces;
    mapping(address => bool) public blacklistedMarketplaces;
    uint8 public marketplaceRestriction;

    mapping(uint256 => mapping(address => uint256)) tokenOwnershipsLengths; // tokenId => address => [token] holded how long by [address] in seconds
    mapping(address => address[]) addressAssociations;
    mapping(address => mapping(address => bool)) addressAssociationsMap; // address => association

    event MarketplaceWhitelisted(address indexed market, bool whitelisted);
    event MarketplaceBlacklisted(address indexed market, bool blacklisted);

    function initialize(string memory baseURI) public initializer {
        ERC721x.__ERC721x_init("Keungz Genesis", "KZG");
        baseTokenURI = baseURI;
        MAX_SUPPLY = 432;
    }

    // =============== TOKEN TRANSFER RECORD ===============
    function getAssociations(address addr) public view returns (address[] memory) {
        return addressAssociations[addr];
    }
    
    function addAssociations(address[] calldata associations) external {
        require(associations.length >= 1, "at least 1 association");
        address[] storage assoArray = addressAssociations[msg.sender];

        for (uint256 i = 0; i < associations.length; i++) {
            address association = associations[i];
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
        if (withAssociation) {
            address[] storage assoArray = addressAssociations[owner];

            for (uint256 i = 0; i < assoArray.length; i++) {
                address asso = assoArray[i];
                // check for mutuals
                if (addressAssociationsMap[asso][owner]) {
                    holdingLength += tokenOwnershipsLengths[tokenId][asso];
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
    ) public virtual override(ERC721x) {
        recordTransfer(_tokenId);
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override(ERC721x) {
        recordTransfer(_tokenId);
        super.safeTransferFrom(_from, _to, _tokenId, _data);
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

    function checkGuardianOrMarketplace(address operator) internal view {
        // Always allow guardian contract
        if (approvedContract[operator]) return;
        require(
            !(marketplaceRestriction == 1 && blacklistedMarketplaces[operator]),
            "Marketplace blacklisted"
        );
        require(
            !(marketplaceRestriction == 2 &&
                !whitelistedMarketplaces[operator]),
            "Marketplace not whitelisted"
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

    function whitelistMarketplaces(address[] calldata markets, bool whitelisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            whitelistedMarketplaces[market] = whitelisted;
            emit MarketplaceWhitelisted(market, whitelisted);
        }
    }

    function blacklistMarketplaces(address[] calldata markets, bool blacklisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            blacklistedMarketplaces[market] = blacklisted;
            emit MarketplaceBlacklisted(market, blacklisted);
        }
    }

    // 0 = no restriction, 1 = blacklist, 2 = whitelist
    function setMarketplaceRestriction(uint8 rule) external onlyOwner {
        marketplaceRestriction = rule;
    }
}