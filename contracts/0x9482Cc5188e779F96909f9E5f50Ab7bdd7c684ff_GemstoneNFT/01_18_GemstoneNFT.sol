// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./GemstoneCore.sol";

contract GemstoneNFT is GemstoneCore {
    using Counters for Counters.Counter;

    enum GemstoneTypes {
        None,
        AurumGemstoneOfTruth,
        DiamondMindGemstone,
        RubyHeartGemstone
    }

    struct WalletTier {
        address wallet;
        uint8 tier;
    }

    Counters.Counter private _tokenIdCounter;

    mapping(uint8 => uint16) private _eligibleByTier;
    mapping(uint16 => address) private _eligibleWallets;
    mapping(address => bool) private _hasClaimed;
    mapping(uint8 => uint16) private _maxTokensByTier;
    mapping(address => uint8) private _tierByAddress;
    mapping(uint8 => uint16) private _tokenCountByTier;
    mapping(uint8 => string) private _tokenUriByTier;
    uint16 private _totalEligibleWallets;

    mapping(uint256 => uint8) public tierByToken;

    bool private _isBuyingEnabled;

    constructor(
        uint16 maxAurum,
        uint16 maxDiamond,
        uint16 maxRuby
    ) {
        _maxTokensByTier[uint8(GemstoneTypes.AurumGemstoneOfTruth)] = maxAurum;
        _maxTokensByTier[uint8(GemstoneTypes.DiamondMindGemstone)] = maxDiamond;
        _maxTokensByTier[uint8(GemstoneTypes.RubyHeartGemstone)] = maxRuby;
    }

    function claim() external {
        require(_hasClaimed[msg.sender] == false, "Already claimed!");
        uint8 tier = _tierByAddress[msg.sender];
        require(tier > 0, "Not eligible to claim!");
        uint256 total = _tokenCountByTier[tier] + 1;
        require(total <= _maxTokensByTier[tier], "Max supply reached!");
        _mint(GemstoneTypes(tier));
        if (GemstoneTypes(tier) == GemstoneTypes.RubyHeartGemstone) {
            _attemptClaim(GemstoneTypes.DiamondMindGemstone);
            _attemptClaim(GemstoneTypes.AurumGemstoneOfTruth);
        } else if (GemstoneTypes(tier) == GemstoneTypes.DiamondMindGemstone) {
            _attemptClaim(GemstoneTypes.AurumGemstoneOfTruth);
        }
        _hasClaimed[msg.sender] = true;
    }

    function getTiers()
        public
        pure
        returns (
            uint8,
            uint8,
            uint8
        )
    {
        return (uint8(GemstoneTypes.AurumGemstoneOfTruth), uint8(GemstoneTypes.DiamondMindGemstone), uint8(GemstoneTypes.RubyHeartGemstone));
    }

    function _attemptClaim(GemstoneTypes tier) private {
        uint256 total = _tokenCountByTier[uint8(tier)] + 1;
        if (total > _maxTokensByTier[uint8(tier)]) return;
        _mint(tier);
    }

    function _mint(GemstoneTypes tier) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _tokenCountByTier[uint8(tier)]++;
        tierByToken[tokenId] = uint8(tier);
    }

    function pauseBuying() external onlyRole(PAUSER_ROLE) {
        _isBuyingEnabled = false;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        uint8 tier = tierByToken[tokenId];
        return string(abi.encodePacked(_tokenUriByTier[tier], Strings.toString(tokenId)));
    }

    function unpauseBuying() external onlyRole(PAUSER_ROLE) {
        _isBuyingEnabled = true;
    }

    function updateEligibleWallets(WalletTier[] memory eligibleWallets) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // revoke current wallets
        if (_totalEligibleWallets > 0) {
            _eligibleByTier[1] = 0;
            _eligibleByTier[2] = 0;
            _eligibleByTier[3] = 0;
            for (uint16 i = 0; i < _totalEligibleWallets; i++) {
                _tierByAddress[_eligibleWallets[i]] = 0;
            }
        }
        _totalEligibleWallets = uint16(eligibleWallets.length);
        // allow new wallets
        for (uint16 i = 0; i < eligibleWallets.length; i++) {
            WalletTier memory allowed = eligibleWallets[i];
            _tierByAddress[allowed.wallet] = allowed.tier;
            _eligibleByTier[allowed.tier]++;
            _eligibleWallets[i] = allowed.wallet;
        }
    }

    function updateTokenUris(
        string memory aurumUri,
        string memory diamondUri,
        string memory rubyUri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenUriByTier[uint8(GemstoneTypes.AurumGemstoneOfTruth)] = aurumUri;
        _tokenUriByTier[uint8(GemstoneTypes.DiamondMindGemstone)] = diamondUri;
        _tokenUriByTier[uint8(GemstoneTypes.RubyHeartGemstone)] = rubyUri;
    }
}