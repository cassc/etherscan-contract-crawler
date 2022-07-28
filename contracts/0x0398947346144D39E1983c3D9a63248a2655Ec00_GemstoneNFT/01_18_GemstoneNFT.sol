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
        GemstoneTypes tier;
    }

    Counters.Counter private _tokenIdCounter;

    mapping(GemstoneTypes => uint16) private _maxTokensByTier;
    mapping(GemstoneTypes => uint16) private _tokenCountByTier;
    mapping(GemstoneTypes => string) private _tokenUriByTier;

    mapping(address => GemstoneTypes) public tierByAddress;
    mapping(uint256 => GemstoneTypes) public tierByToken;
    mapping(address => bool) public hasClaimed;

    constructor(
        uint16 maxAurum,
        uint16 maxDiamond,
        uint16 maxRuby
    ) {
        _maxTokensByTier[GemstoneTypes.AurumGemstoneOfTruth] = maxAurum;
        _maxTokensByTier[GemstoneTypes.DiamondMindGemstone] = maxDiamond;
        _maxTokensByTier[GemstoneTypes.RubyHeartGemstone] = maxRuby;
    }

    function claim() external {
        require(!hasClaimed[msg.sender], "Already claimed!");
        GemstoneTypes tier = tierByAddress[msg.sender];
        require(tier != GemstoneTypes.None, "Not eligible to claim!");
        uint256 total = _tokenCountByTier[tier] + 1;
        require(total <= _maxTokensByTier[tier], "Max supply reached!");
        _mint(GemstoneTypes(tier));
        if (GemstoneTypes(tier) == GemstoneTypes.RubyHeartGemstone) {
            _attemptClaim(GemstoneTypes.DiamondMindGemstone);
            _attemptClaim(GemstoneTypes.AurumGemstoneOfTruth);
        } else if (GemstoneTypes(tier) == GemstoneTypes.DiamondMindGemstone) {
            _attemptClaim(GemstoneTypes.AurumGemstoneOfTruth);
        }
        hasClaimed[msg.sender] = true;
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

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return string(
            abi.encodePacked(
                _tokenUriByTier[tierByToken[tokenId]],
                Strings.toString(tokenId)
            )
        );
    }

    function addEligibleWallets(WalletTier[] memory eligibleWallets) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < eligibleWallets.length; i++) {
            WalletTier memory allowed = eligibleWallets[i];

            // In case a wallet was already eligible, they stay eligible. Note
            // that an important distinction here is to not update the mapping
            // `hasClaimed`, because in that case the user will be able to mint
            // multiple times without it being intended.
            tierByAddress[allowed.wallet] = allowed.tier;
        }
    }

    function revokeEligibleWallets(address[] memory wallets) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < wallets.length; i++) {
            tierByAddress[wallets[i]] = GemstoneTypes.None;
        }
    }

    function updateTokenUris(
        string memory aurumUri,
        string memory diamondUri,
        string memory rubyUri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenUriByTier[GemstoneTypes.AurumGemstoneOfTruth] = aurumUri;
        _tokenUriByTier[GemstoneTypes.DiamondMindGemstone] = diamondUri;
        _tokenUriByTier[GemstoneTypes.RubyHeartGemstone] = rubyUri;
    }

    function _attemptClaim(GemstoneTypes tier) private {
        uint256 total = _tokenCountByTier[tier] + 1;
        if (total > _maxTokensByTier[tier]) return;
        _mint(tier);
    }

    function _mint(GemstoneTypes tier) private {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _tokenCountByTier[tier]++;
        tierByToken[tokenId] = tier;
    }
}