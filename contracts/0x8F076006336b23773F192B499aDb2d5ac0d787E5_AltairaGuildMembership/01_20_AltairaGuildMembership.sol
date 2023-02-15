//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AltairaGuildMembership is ERC721Enumerable, ERC2981, AccessControl, ReentrancyGuard, Ownable {
    using Address for address payable;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ROYALTY_ADJUSTER_ROLE = keccak256("ROYALTY_ADJUSTER_ROLE");
    bytes32 public constant PRICE_ADJUSTER_ROLE = keccak256("PRICE_ADJUSTER_ROLE");
    bytes32 public constant BASEURI_ROLE = keccak256("BASEURI_ROLE");
    bytes32 public constant MINT_ENABLE_ROLE = keccak256("MINT_ENABLE_ROLE");
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");
    bytes32 public constant WHITELIST_ADMIN_ROLE = keccak256("WHITELIST_ADMIN_ROLE");

    enum Kingdom {
        Thearan,
        Sindarian,
        Elven,
        Kindred
    }

    enum Gender {
        Male,
        Female
    }

    uint public constant START_TOKEN_ID = 1;
    uint public constant MIN_TIER = 1; //can only be 1, assumptions in array iterations
    uint public constant MAX_TIER = 6;
    uint public constant NUM_GENDERS = 2;
    uint public constant NUM_KINGDOMS = 4;
    uint public immutable mint_per_gender;
    uint[MAX_TIER] public tierQuantities;
    uint[MAX_TIER] public tierOffsets;

    mapping(uint => uint) private _minted;
    mapping(Kingdom => bool) public mintingEnabled;
    mapping(Kingdom => bool) public whitelistMintingEnabled;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public whitelistSigner;

    string public baseUri;

    uint[MAX_TIER] public pricePerTokenPerTier;

    event PricesUpdated(uint[MAX_TIER] prevPrices, uint[MAX_TIER] newPrices);
    event BaseUriUpdated(string prevUri, string newUri);
    event KingdomMintingUpdated(Kingdom kingdom, bool enabled, bool whitelistEnabled);

    constructor(string memory _baseUri, address _minter, address _admin, uint[MAX_TIER] memory _tierQuantities)
    ERC721("Altaira Guild Membership", "ALTAIRA")
    {
        _transferOwnership(_minter); //for easy OpenSea admin.
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MINTER_ROLE, _minter);
        _grantRole(ROYALTY_ADJUSTER_ROLE, _admin);
        _grantRole(PRICE_ADJUSTER_ROLE, _admin);
        _grantRole(BASEURI_ROLE, _admin);
        _grantRole(MINT_ENABLE_ROLE, _admin);
        _grantRole(WHITELIST_ADMIN_ROLE, _admin);
        _grantRole(BENEFICIARY_ROLE, _minter);
        baseUri = _baseUri;
        uint count = 0;
        for (uint i = 0; i < MAX_TIER; i++) {
            tierOffsets[i] = count;
            count += _tierQuantities[i];
            tierQuantities[i] = _tierQuantities[i];
        }
        mint_per_gender = count;
        whitelistSigner[_admin] = true;
    }

    function _tokenOffset(Kingdom _kingdom, Gender _gender, uint _tier)
    internal view
    returns (uint)
    {
        return (uint(_kingdom) * NUM_GENDERS + uint(_gender)) * mint_per_gender + tierOffsets[_tier - 1] + START_TOKEN_ID;
    }

    function getKingdom(uint _tokenId)
    public view
    returns (Kingdom)
    {
        require(_tokenId >= START_TOKEN_ID, "Token ID too low");
        require(_tokenId <= mint_per_gender * NUM_KINGDOMS * NUM_GENDERS, "Token ID too high");
        return Kingdom((_tokenId - START_TOKEN_ID) / (mint_per_gender * NUM_GENDERS));
    }

    function getGender(uint _tokenId)
    public view
    returns (Gender)
    {
        require(_tokenId >= START_TOKEN_ID, "Token ID too low");
        require(_tokenId <= mint_per_gender * NUM_KINGDOMS * NUM_GENDERS, "Token ID too high");
        return Gender((_tokenId - START_TOKEN_ID) / mint_per_gender % NUM_GENDERS);
    }

    function getTier(uint _tokenId)
    public view
    returns (uint)
    {
        require(_tokenId >= START_TOKEN_ID, "Token ID too low");
        require(_tokenId <= mint_per_gender * NUM_KINGDOMS * NUM_GENDERS, "Token ID too high");
        uint tierOffset = (_tokenId - START_TOKEN_ID) % mint_per_gender;
        for (uint tier = MIN_TIER; tier < MAX_TIER; tier++) {
            if (tierOffset < tierOffsets[tier]) {// Offset smaller than that of NEXT tier!
                return tier;
            }
        }
        return MAX_TIER;
    }

    function minted(Kingdom _kingdom, Gender _gender, uint _tier)
    public view
    returns (uint)
    {
        return _minted[_tokenOffset(_kingdom, _gender, _tier)];
    }

    function getMintingEnabled()
    public view
    returns (bool[NUM_KINGDOMS] memory)
    {
        bool[NUM_KINGDOMS] memory allEnabled;
        for (uint k = 0; k < NUM_KINGDOMS; k++) {
            allEnabled[k] = mintingEnabled[Kingdom(k)];
        }
        return allEnabled;
    }

    function getWhitelistMintingEnabled()
    public view
    returns (bool[NUM_KINGDOMS] memory)
    {
        bool[NUM_KINGDOMS] memory allEnabled;
        for (uint k = 0; k < NUM_KINGDOMS; k++) {
            allEnabled[k] = whitelistMintingEnabled[Kingdom(k)];
        }
        return allEnabled;
    }

    function pricesPerTokenPerTier()
    public view
    returns (uint[MAX_TIER] memory)
    {
        return pricePerTokenPerTier;
    }

    function remainingTokens()
    public view
    returns (uint[MAX_TIER][NUM_KINGDOMS] memory)
    {
        uint[MAX_TIER][NUM_KINGDOMS] memory remaining;
        for (uint k = 0; k < NUM_KINGDOMS; k++) {
            for (uint tier = MIN_TIER; tier <= MAX_TIER; tier++) {
                remaining[k][tier - 1] = tierQuantities[tier - 1] * NUM_GENDERS
                - minted(Kingdom(k), Gender.Male, tier)
                - minted(Kingdom(k), Gender.Female, tier);
            }
        }
        return remaining;
    }

    function mintFor(address destination, uint256 quantity, Kingdom kingdom, Gender gender, uint tier)
    external
    onlyRole(MINTER_ROLE)
    {
        uint tokenBucket = _tokenOffset(kingdom, gender, tier);
        require(_minted[tokenBucket] + quantity <= tierQuantities[tier - 1], "Kingdom/Gender/Tier combination is sold out");
        require(tier >= MIN_TIER, "Tier too low");
        require(tier <= MAX_TIER, "Tier too high");
        uint startId = _minted[tokenBucket] + tokenBucket;
        uint maxId = quantity + startId;
        _minted[tokenBucket] += quantity;
        for (uint i = startId; i < maxId; i++) {
            _safeMint(destination, i);
        }
    }

    function withdraw(address payable destination)
    external
    onlyRole(BENEFICIARY_ROLE)
    {
        destination.sendValue(address(this).balance);
    }

    function purchase(address destination, uint256 quantity, Kingdom kingdom, uint tier)
    external payable
    nonReentrant
    {
        bool kingdomEnabled = mintingEnabled[kingdom];
        if (!kingdomEnabled) {
            bool whitelistEnabled = whitelistMintingEnabled[kingdom];
            require(whitelistEnabled, "Minting disabled for Kingdom");
            bool userIsWhitelisted = whitelist[msg.sender];
            require(userIsWhitelisted, "Your account is not whitelisted");
        }
        _purchase(destination, quantity, kingdom, tier);
    }

    function purchaseSignedWhitelist(address destination, uint256 quantity, Kingdom kingdom, uint tier, bytes calldata signature)
    external payable
    nonReentrant
    {
        bool whitelistEnabled = whitelistMintingEnabled[kingdom];
        require(whitelistEnabled, "Minting disabled for Kingdom");
        bytes32 data = keccak256(abi.encodePacked(address(this), this.purchaseSignedWhitelist.selector, destination));
        bytes32 hash = ECDSA.toEthSignedMessageHash(data);
        address signer = ECDSA.recover(hash, signature);
        bool userIsWhitelisted = whitelistSigner[signer];
        require(userIsWhitelisted, "Your account is not whitelisted");
        _purchase(destination, quantity, kingdom, tier);
    }

    function _purchase(address destination, uint256 quantity, Kingdom kingdom, uint tier) internal {
        require(quantity < 21, "You can purchase a maximum of 20 NFTs");
        require(msg.value >= pricePerTokenPerTier[tier - 1] * quantity, "Ether sent is not correct");
        // NOTE: Overpaying makes us just keep all payment!
        require(tier >= MIN_TIER, "Tier too low");
        require(tier <= MAX_TIER, "Tier too high");

        uint tokenBucketMale = _tokenOffset(kingdom, Gender.Male, tier);
        uint tokenBucketFemale = _tokenOffset(kingdom, Gender.Female, tier);

        uint remainingAtStart = tierQuantities[tier - 1] * NUM_GENDERS - _minted[tokenBucketMale] - _minted[tokenBucketFemale];
        require(remainingAtStart >= quantity, "Not enough Tokens of selected Kingdom/Tier");

        for (uint i = 0; i < quantity; i++) {
            Gender genderToMint = _randomGender(remainingAtStart, i, tier, tokenBucketMale);
            uint tokenBucket = _tokenOffset(kingdom, genderToMint, tier);
            uint idToMint = _minted[tokenBucket] + tokenBucket;
            _minted[tokenBucket] += 1;
            _safeMint(destination, idToMint);
        }
    }

    function _randomGender(uint remainingAtStart, uint i, uint tier, uint tokenBucketMale)
    internal view
    returns (Gender)
    {
        uint randomvalue = uint(keccak256(abi.encodePacked(i, blockhash(block.number - 1), block.prevrandao)));
        uint stillRemaining = remainingAtStart - i;
        uint randomIndex = randomvalue % stillRemaining;
        if (randomIndex < tierQuantities[tier - 1] - _minted[tokenBucketMale]) {
            return Gender.Male;
        } else {
            return Gender.Female;
        }
    }

    function _baseURI()
    internal view virtual override
    returns (string memory)
    {
        return baseUri;
    }

    function supportsInterface(bytes4 interfaceId)
    public view virtual override(ERC721Enumerable, ERC2981, AccessControl)
    returns (bool)
    {
        return
        ERC721Enumerable.supportsInterface(interfaceId)
        || ERC2981.supportsInterface(interfaceId)
        || AccessControl.supportsInterface(interfaceId);
    }

    function adjustRoyalty(RoyaltyInfo calldata royalty)
    external
    onlyRole(ROYALTY_ADJUSTER_ROLE)
    {
        if (royalty.receiver == address(0)) {
            _deleteDefaultRoyalty();
        }
        else {
            _setDefaultRoyalty(royalty.receiver, royalty.royaltyFraction);
        }
    }

    function adjustPrices(uint[MAX_TIER] memory tierPrices)
    external
    onlyRole(PRICE_ADJUSTER_ROLE)
    {
        emit PricesUpdated(pricePerTokenPerTier, tierPrices);
        pricePerTokenPerTier = tierPrices;
    }

    function adjustBaseUri(string calldata newBaseUri)
    external
    onlyRole(BASEURI_ROLE)
    {
        emit BaseUriUpdated(baseUri, newBaseUri);
        baseUri = newBaseUri;
    }

    function setMinting(Kingdom kingdom, bool enabled, bool whitelistEnabled)
    external
    onlyRole(MINT_ENABLE_ROLE)
    {
        emit KingdomMintingUpdated(kingdom, enabled, whitelistEnabled);
        mintingEnabled[kingdom] = enabled;
        whitelistMintingEnabled[kingdom] = whitelistEnabled;
    }

    function addToWhitelist(address[] calldata accounts)
    public
    onlyRole(WHITELIST_ADMIN_ROLE)
    {
        uint len = accounts.length;
        for (uint i = 0; i < len; i++) {
            whitelist[accounts[i]] = true;
        }
    }

    function setWhitelistSigner(address[] calldata accounts, bool enable)
    public
    onlyRole(WHITELIST_ADMIN_ROLE)
    {
        uint len = accounts.length;
        for (uint i = 0; i < len; i++) {
            whitelistSigner[accounts[i]] = enable;
        }
    }

    function removeFromWhitelist(address[] memory accounts)
    public
    onlyRole(WHITELIST_ADMIN_ROLE)
    {
        for (uint i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = false;
        }
    }
}