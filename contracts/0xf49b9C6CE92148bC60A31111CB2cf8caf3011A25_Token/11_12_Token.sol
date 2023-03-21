// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC1155Hybrid.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

struct TokenConfig {
    bool added;
    bool canMint;
    bool canBurn;
    uint256 supplyLimit;
}

contract Token is ERC1155Hybrid, Pausable, Ownable {
    uint8 public constant ROLE_MINT_FT = 1 << 0;
    uint8 public constant ROLE_MINT_NFT = 1 << 1;
    uint8 public constant ROLE_BATCH_MINT_NFT = 1 << 2;
    uint8 public constant ROLE_BURN_FT = 1 << 3;

    uint256 private constant TIER_0_START = 0;
    uint256 private constant TIER_1_START = 2 ** 16;
    uint256 private constant TIER_2_START = 2 ** 48;
    uint256 private constant TIER_3_START = 2 ** 80;
    uint256 private constant TIER_UPPER_BOUND = 2 ** 112;

    mapping(address => uint8) _roles;

    error NotAuthorized(uint8 req, address sender);

    address _mintContract;
    address _burnContract;

    mapping(uint256 => uint256) private _minted;
    mapping(uint256 => TokenConfig) private _added;
    mapping(uint8 => uint256) private _nextID;

    modifier requireRole(uint8 req) {
        if (!hasRole(_msgSender(), req)) {
            revert NotAuthorized(req, _msgSender());
        }
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory uri_
    ) ERC1155Hybrid(name_, symbol_, contractURI_, uri_) {
        _nextID[0] = 0;
        _nextID[1] = TIER_1_START;
        _nextID[2] = TIER_2_START;
        _nextID[3] = TIER_3_START;

        // console.log(ROLE_MINT_FT);
        // console.log(ROLE_MINT_NFT);
        // console.log(ROLE_BATCH_MINT_NFT);
        // console.log(ROLE_BURN_FT);
    }

    function setMetadata(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        string memory uri_
    ) public onlyOwner {
        _setMetadata(name_, symbol_, contractURI_, uri_);
    }

    function setPaused(bool b) public onlyOwner {
        if (b) {
            require(b && !paused(), "Contract is already paused");
            _pause();
            return;
        }

        require(!b && paused(), "Contract is not paused");
        _unpause();
    }

    function setRole(address operator, uint8 mask) public onlyOwner {
        _roles[operator] = mask;
    }

    function hasRole(address operator, uint8 role) public view returns (bool) {
        return _roles[operator] & role == role;
    }

    function _tierOf(uint256 id) internal pure override returns (uint8) {
        if (id < TIER_1_START) return 0;
        if (id < TIER_2_START) return 1;
        if (id < TIER_3_START) return 2;
        if (id < TIER_UPPER_BOUND) return 3;

        revert("Token ID exceeds upper bound");
    }

    function _tierBounds(
        uint8 tier
    ) internal pure override returns (uint256, uint256) {
        if (tier == 0) return (TIER_0_START, TIER_1_START - 1);
        if (tier == 1) return (TIER_1_START, TIER_2_START - 1);
        if (tier == 2) return (TIER_2_START, TIER_3_START - 1);
        if (tier == 3) return (TIER_3_START, TIER_UPPER_BOUND - 1);

        revert("Tier not configured");
    }

    function _getNextID(uint8 tier) internal view override returns (uint256) {
        require(tier < 4, "Tier not configured");

        return _nextID[tier];
    }

    function _incrementNextID(
        uint8 tier,
        uint256 amount
    ) internal override returns (uint256) {
        require(tier < 4, "Tier not configured");

        (, uint256 end) = _tierBounds(tier);

        require(
            _nextID[tier] + amount < end,
            "Requested IDs exceed bounds of tier"
        );

        uint256 start = _nextID[tier];
        _nextID[tier] += amount;
        return start;
    }

    function _isFungible(uint256 id) internal pure override returns (bool) {
        return id < TIER_1_START;
    }

    function _isFungibleTier(uint8 tier) internal pure override returns (bool) {
        return tier == 0;
    }

    function _supplyLimit(uint256 id) internal view override returns (uint256) {
        if (!_isFungible(id)) {
            return 1;
        }

        return _added[id].supplyLimit;
    }

    function totalMinted(uint256 id) public view returns (uint256) {
        if (!_isFungible(id)) {
            if (ownerOf(id) != address(0)) {
                return 1;
            } else {
                return 0;
            }
        }

        return _minted[id];
    }

    function supplyLimit(uint256 id) public view returns (uint256) {
        return _supplyLimit(id);
    }

    function addFT(
        uint8 tier,
        uint256 supplyLimit_,
        bool canMint_,
        bool canBurn_
    ) public onlyOwner returns (uint256) {
        require(tier == 0, "Provided tier is not fungible.");

        uint256 id = _incrementNextID(0, 1);
        _added[id] = TokenConfig(true, canMint_, canBurn_, supplyLimit_);
        return id;
    }

    function modifyFT(
        uint256 id,
        uint256 supplyLimit_,
        bool canMint_,
        bool canBurn_
    ) public onlyOwner {
        _added[id] = TokenConfig(true, canMint_, canBurn_, supplyLimit_);
    }

    function mintFT(
        address to,
        uint256 tokenID,
        uint256 quantity
    ) public requireRole(ROLE_MINT_FT) {
        require(_isFungible(tokenID), "Token is not fungible.");
        require(_added[tokenID].added, "Token type not added.");
        require(_added[tokenID].canMint, "Token cannot be minted.");
        require(
            supplyLimit(tokenID) == 0 ||
                (totalMinted(tokenID) + quantity <= supplyLimit(tokenID)),
            "Mint would exceed supply limit."
        );

        _minted[tokenID] += quantity;
        _mintFungible(to, tokenID, quantity);
    }

    function adminMintFT(
        address to,
        uint256 tokenID,
        uint256 quantity
    ) public onlyOwner {
        require(_isFungible(tokenID), "Token is not fungible.");
        require(_added[tokenID].added, "Token type not added.");
        require(
            supplyLimit(tokenID) == 0 ||
                (totalMinted(tokenID) + quantity <= supplyLimit(tokenID)),
            "Mint would exceed supply limit."
        );

        _minted[tokenID] += quantity;
        _mintFungible(to, tokenID, quantity);
    }

    function mintNFT(
        address to,
        uint8 tier,
        uint256 quantity
    ) public requireRole(ROLE_MINT_NFT) {
        require(!_isFungibleTier(tier), "Tier is fungible.");
        _mintNFT(to, tier, quantity);
    }

    function adminMintNFT(
        address to,
        uint8 tier,
        uint256 quantity
    ) public onlyOwner {
        require(!_isFungibleTier(tier), "Tier is fungible.");
        _mintNFT(to, tier, quantity);
    }

    function batchMintNFT(
        address to,
        uint8[] calldata tiers,
        uint256[] calldata quantities
    ) public requireRole(ROLE_BATCH_MINT_NFT) {
        require(tiers.length == quantities.length, "Array mismatch");

        for (uint256 i = 0; i < tiers.length; i++) {
            mintNFT(to, tiers[i], quantities[i]);
        }
    }

    function burnFT(
        address owner,
        uint256 tokenID,
        uint256 quantity
    ) public requireRole(ROLE_BURN_FT) {
        require(_isFungible(tokenID), "Token is not fungible.");
        require(_added[tokenID].added, "Token type not added.");
        require(_added[tokenID].canBurn, "Token cannot be burned.");

        _burnFungible(owner, tokenID, quantity);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override(ERC1155Hybrid) {
        if (paused()) revert("Token is paused");

        return _safeTransferFrom(from, to, id, amount, data);
    }

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function updateMetadata(uint256 id) public onlyOwner {
        emit MetadataUpdate(id);
    }

    function updateAllMetadata() public onlyOwner {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }
}