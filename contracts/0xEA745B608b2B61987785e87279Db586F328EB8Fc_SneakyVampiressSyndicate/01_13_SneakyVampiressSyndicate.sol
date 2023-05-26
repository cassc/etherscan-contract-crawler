// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721SVS.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SneakyVampiressSyndicate is ERC721SVS, Ownable {
    enum SaleState { CLOSED, PRESALE, OPEN }
    
    uint256 constant public SVS_MAX = 12345; // 8888 Gen1 + 1900 WL + 200 Team + 1357 Public
    uint256 constant public SVS_HOLDERS_MAX = 8888;
    uint256 constant public SVS_WHITELIST_MAX = 1900;
    uint256 constant public SVS_TEAM_MAX = 200;
    uint256 constant public SVS_PUBLIC_MAX_PER_TX = 3;

    uint256 constant public SVS_PRICE = 0.16 ether;
    uint256 constant public SVS_PRICE_TIER1 = 0.12 ether;
    uint256 constant public SVS_PRICE_TIER2 = 0.08 ether;

    string public baseURI = "https://svs.gg/api/v2/metadata/";

    address public signer = 0x6d821F67BBD6961f42a5dde6fd99360e1Ab12345;
    uint16 public holdersCounter;
    uint16 public whitelistCounter;
    uint16 public teamCounter;
    SaleState public saleState;
    bool public locked;

    mapping(bytes32 => bool) usedNonces;
    uint256[35] claimedGen1Tokens; // 8888 / 256 = 35 bitmaps.

    constructor() ERC721SVS("Sneaky Vampiress Syndicate", "SVS2") {}

    function mintTeamTokens(address[] calldata to, uint256[] calldata amounts) external onlyOwner {
        uint256 combinedAmount;
        for (uint256 i; i < amounts.length; i++) {
            combinedAmount += amounts[i];
        }

        teamCounter += uint16(combinedAmount);

        require(teamCounter <= SVS_TEAM_MAX, "Team tokens sold out.");

        for (uint256 i; i < to.length; i++) {
            _mint(to[i], amounts[i]);
        }
    }

    function purchasePresale(uint256[] calldata tokens, bytes calldata signature) external payable {
        require(saleState == SaleState.PRESALE, "Sale is not live.");
        require(_totalSupply + tokens.length - teamCounter <= SVS_MAX - SVS_TEAM_MAX, "Sold out.");
        require(ECDSA.recover(keccak256(abi.encodePacked(msg.sender, tokens)), signature) == signer, "Invalid signature.");
        require(tokens.length * SVS_PRICE <= msg.value, "Insufficient funds.");

        OwnerData storage ownerData = _ownerData[msg.sender];

        if (tokens[0] == 0) { // Whitelisted
            require(!ownerData.usedWhitelist, "Whitelist already claimed");
            ownerData.usedWhitelist = true;
            require(whitelistCounter++ < SVS_WHITELIST_MAX, "Sold out.");
            if (tokens.length > 1) {
                holdersCounter += uint16(tokens.length - 1);
                require(holdersCounter <= SVS_HOLDERS_MAX, "Sold out.");
            }
        } else {
            holdersCounter += uint16(tokens.length);
            require(holdersCounter <= SVS_HOLDERS_MAX, "Sold out.");
        }

        _setUsedTokens(tokens);

        _mint(msg.sender, tokens.length);
    }

    function purchasePresaleWithDiscount(uint256 amount, uint16 tier1, uint16 tier2, uint16 tier1Max, uint16 tier2Max, uint256[] calldata tokens, bytes calldata signature) external payable {
        require(saleState == SaleState.PRESALE, "Sale is not live.");
        require(_totalSupply + tokens.length - teamCounter <= SVS_MAX - SVS_TEAM_MAX, "Sold out.");
        require(ECDSA.recover(keccak256(abi.encodePacked(msg.sender, amount, tier1, tier2, tier1Max, tier2Max, tokens)), signature) == signer, "Invalid signature.");
        require((amount * SVS_PRICE + tier1 * SVS_PRICE_TIER1 + tier2 * SVS_PRICE_TIER2) <= msg.value, "Insufficient funds.");

        OwnerData storage ownerData = _ownerData[msg.sender];

        if (tokens[0] == 0) { // Whitelisted
            require(!ownerData.usedWhitelist, "Whitelist already claimed");
            ownerData.usedWhitelist = true;
            require(whitelistCounter++ < SVS_WHITELIST_MAX, "Sold out.");
            if (tokens.length > 1) {
                holdersCounter += uint16(tokens.length - 1);
                require(holdersCounter <= SVS_HOLDERS_MAX, "Sold out.");
            }
        } else {
            holdersCounter += uint16(tokens.length);
            require(holdersCounter <= SVS_HOLDERS_MAX, "Sold out.");
        }

        _setUsedTokens(tokens);

        uint16 newUsedTier1 = ownerData.usedTier1 + tier1;
        uint16 newUsedTier2 = ownerData.usedTier2 + tier2;
        require(newUsedTier1 <= tier1Max && newUsedTier2 <= tier2Max, "Discounts exceeded.");
        ownerData.usedTier1 = newUsedTier1;
        ownerData.usedTier2 = newUsedTier2;
        _mint(msg.sender, tokens.length);
    }

    function purchasePublic(uint256 amount, bytes32 nonce, bytes calldata signature) external payable {
        require(saleState == SaleState.OPEN, "Sale is not live.");
        require(_totalSupply + amount - holdersCounter - whitelistCounter - teamCounter <= SVS_MAX - SVS_HOLDERS_MAX - SVS_WHITELIST_MAX - SVS_TEAM_MAX, "Sold out.");
        require(amount <= SVS_PUBLIC_MAX_PER_TX, "Too many tokens.");
        require(!usedNonces[nonce], "Nonce already used.");
        usedNonces[nonce] = true;
        
        require(ECDSA.recover(keccak256(abi.encodePacked(msg.sender, amount, nonce)), signature) == signer, "Invalid signature.");
        require(amount * SVS_PRICE <= msg.value, "Insufficient funds.");

        _mint(msg.sender, amount);
    }

    function purchasePublicWithDiscount(uint256 amount, uint16 tier1, uint16 tier2, uint16 tier1Max, uint16 tier2Max, bytes32 nonce, bytes calldata signature) external payable {
        require(saleState == SaleState.OPEN, "Sale is not live.");
        uint256 totalAmount = amount + tier1 + tier2;
        require(totalSupply() + totalAmount - holdersCounter - whitelistCounter - teamCounter <= SVS_MAX - SVS_HOLDERS_MAX - SVS_WHITELIST_MAX - SVS_TEAM_MAX, "Sold out.");
        require(totalAmount <= SVS_PUBLIC_MAX_PER_TX, "Too many tokens.");
        require(!usedNonces[nonce], "Nonce already used.");
        usedNonces[nonce] = true;
        require(ECDSA.recover(keccak256(abi.encodePacked(msg.sender, amount, tier1, tier2, tier1Max, tier2Max, nonce)), signature) == signer, "Invalid signature.");
        require((amount * SVS_PRICE + tier1 * SVS_PRICE_TIER1 + tier2 * SVS_PRICE_TIER2) <= msg.value, "Insufficient funds.");

        OwnerData storage ownerData = _ownerData[msg.sender];
        uint16 newUsedTier1 = ownerData.usedTier1 + tier1;
        uint16 newUsedTier2 = ownerData.usedTier2 + tier2;
        require(newUsedTier1 <= tier1Max && newUsedTier2 <= tier2Max, "Discounts exceeded.");

        ownerData.usedTier1 = newUsedTier1;
        ownerData.usedTier2 = newUsedTier2;
        _mint(msg.sender, totalAmount);
    }

    // Admin functions
    function setSaleState(SaleState newState) external onlyOwner {
        saleState = newState;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        require(!locked, "Contract is locked.");
        baseURI = uri;
    }

    function setSignerAddress(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    function lock() external onlyOwner {
        locked = true;
    }

    function withdraw() external onlyOwner {
        payable(0x2c65908D37bF90EaA95506b42758613F6C1b9299).transfer((address(this).balance * 15) / 100);

        uint256 split = address(this).balance / 6;
        payable(0xea68212b0450A929B14726b90550933bC12fF813).transfer(split);
        payable(0x2772A2B7B37108FC80AFB864084b7897E8f232ef).transfer(split);
        payable(0x5BB440e7948d80Dec00A88Fd80e374546BB2D42C).transfer(split);
        payable(0x6ff547F546Bd8f4c8C4E7Fb30E32B10af818Ac82).transfer(split);
        payable(0xC43CB0EBb90f41f0E640ee18A0E2C6A4BB497a2A).transfer(split);
        payable(0x94D58bcA73953f1CEC41327a24D3DD0fc388d2f7).transfer(address(this).balance);
    }

    // Internals
    function addressState(address account) view external returns (OwnerData memory ownerData) {
        ownerData = _ownerData[account];
    }
    
    function unclaimedTokens(uint256[] calldata tokens) view external returns (uint256[] memory) {
        uint256[] memory unclaimed = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            uint256 token = tokens[i];
            if (claimedGen1Tokens[token >> 8] >> (token & 0xff) & 1 == 0) {
                unclaimed[i] = token;
            }
        }
        return unclaimed;
    }

    function _setUsedTokens(uint256[] calldata tokens) internal {
        uint256 currentBitMap;
        uint256 currentBitMapIndex = type(uint256).max;

        unchecked {            
            for (uint256 i; i < tokens.length; i++) {
                uint256 token = tokens[i];
                if (token == 0) continue; // This is indication of whitelist.

                uint256 index = token >> 8;
                if (currentBitMapIndex != index) {
                    if (currentBitMapIndex < type(uint256).max) {
                        claimedGen1Tokens[currentBitMapIndex] = currentBitMap;
                    }
                    currentBitMapIndex = index;                
                    currentBitMap = claimedGen1Tokens[index];
                }

                uint256 newBitmap = currentBitMap | (1 << (token & 0xff));
                require(newBitmap != currentBitMap, "Some tokens were already claimed.");
                currentBitMap = newBitmap;
            }
        }

        if (currentBitMapIndex < type(uint256).max) {
            claimedGen1Tokens[currentBitMapIndex] = currentBitMap;
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}