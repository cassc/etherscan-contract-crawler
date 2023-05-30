//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./SeedPhrasePricing.sol";
import "../interfaces/IN.sol";
import "../interfaces/IRarible.sol";
import "../interfaces/IKarmaScore.sol";
import "../interfaces/INOwnerResolver.sol";
import "../libraries/NilProtocolUtils.sol";
import "../libraries/SeedPhraseUtils.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
// ░██████╗███████╗███████╗██████╗░  ██████╗░██╗░░██╗██████╗░░█████╗░░██████╗███████╗ //
// ██╔════╝██╔════╝██╔════╝██╔══██╗  ██╔══██╗██║░░██║██╔══██╗██╔══██╗██╔════╝██╔════╝ //
// ╚█████╗░█████╗░░█████╗░░██║░░██║  ██████╔╝███████║██████╔╝███████║╚█████╗░█████╗░░ //
// ░╚═══██╗██╔══╝░░██╔══╝░░██║░░██║  ██╔═══╝░██╔══██║██╔══██╗██╔══██║░╚═══██╗██╔══╝░░ //
// ██████╔╝███████╗███████╗██████╔╝  ██║░░░░░██║░░██║██║░░██║██║░░██║██████╔╝███████╗ //
// ╚═════╝░╚══════╝╚══════╝╚═════╝░  ╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝ //
//                                                                                    //
//                                                                                    //
//  Title: Seed Phrase                                                                //
//  Devs: Harry Faulkner & maximonee (twitter.com/maximonee_)                         //
//  Description: This contract provides minting for the                               //
//               Seed Phrase NFT by Sean Elliott                                      //
//               (twitter.com/seanelliottoc)                                          //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

contract SeedPhrase is SeedPhrasePricing, VRFConsumerBase {
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;
    using Counters for Counters.Counter;
    using SeedPhraseUtils for SeedPhraseUtils.Random;

    Counters.Counter private _doublePanelTokens;
    Counters.Counter private _tokenIds;

    address private _owner;

    // Tracks whether an n has been used already to mint
    mapping(uint256 => bool) public override nUsed;

    mapping(PreSaleType => uint16) public presaleLimits;

    address[] private genesisSketchAddresses;
    uint16[] private bipWordIds = new uint16[](2048);

    IRarible public immutable rarible;
    INOwnerResolver public immutable nOwnerResolver;
    IKarmaScore public immutable karma;

    struct Maps {
        // Map double panel tokens to burned singles
        mapping(uint256 => uint256[2]) burnedTokensPairings;
        // Mapping of valid double panel pairings (BIP39 IDs)
        mapping(uint16 => uint16) doubleWordPairings;
        // Stores the guarenteed token rarity for a double panel
        mapping(uint256 => uint8) doubleTokenRarity;
        mapping(address => bool) ogAddresses;
        // Map token to their unique seed
        mapping(uint256 => bytes32) tokenSeed;
    }

    struct Config {
        bool preSaleActive;
        bool publicSaleActive;
        bool isSaleHalted;
        bool bipWordsShuffled;
        bool vrfNumberGenerated;
        bool isBurnActive;
        bool isOwnerSupplyMinted;
        bool isGsAirdropComplete;
        uint8 ownerSupply;
        uint16 maxPublicMint;
        uint16 karmaRequirement;
        uint32 preSaleLaunchTime;
        uint32 publicSaleLaunchTime;
        uint256 doubleBurnTokens;
        uint256 linkFee;
        uint256 raribleTokenId;
        uint256 vrfRandomValue;
        address vrfCoordinator;
        address linkToken;
        bytes32 vrfKeyHash;
    }

    struct ContractAddresses {
        address n;
        address masterMint;
        address dao;
        address nOwnersRegistry;
        address vrfCoordinator;
        address linkToken;
        address karmaAddress;
        address rarible;
    }

    Config private config;
    Maps private maps;

    event Burnt(address to, uint256 firstBurntToken, uint256 secondBurntToken, uint256 doublePaneledToken);

    DerivativeParameters params = DerivativeParameters(false, false, 0, 2048, 4);

    constructor(
        ContractAddresses memory contractAddresses,
        bytes32 _vrfKeyHash,
        uint256 _linkFee
    )
        SeedPhrasePricing(
            "Seed Phrase",
            "SEED",
            IN(contractAddresses.n),
            params,
            30000000000000000,
            60000000000000000,
            contractAddresses.masterMint,
            contractAddresses.dao
        )
        VRFConsumerBase(contractAddresses.vrfCoordinator, contractAddresses.linkToken)
    {
        // Start token IDs at 1
        _tokenIds.increment();

        presaleLimits[PreSaleType.N] = 400;
        presaleLimits[PreSaleType.Karma] = 800;
        presaleLimits[PreSaleType.GenesisSketch] = 40;
        presaleLimits[PreSaleType.OG] = 300;
        presaleLimits[PreSaleType.GM] = 300;

        nOwnerResolver = INOwnerResolver(contractAddresses.nOwnersRegistry);
        rarible = IRarible(contractAddresses.rarible);
        karma = IKarmaScore(contractAddresses.karmaAddress);

        // Initialize Config struct
        config.maxPublicMint = 8;
        config.ownerSupply = 20;
        config.preSaleLaunchTime = 1639591200;
        config.publicSaleLaunchTime = 1639598400;
        config.raribleTokenId = 706480;
        config.karmaRequirement = 1020;

        config.vrfCoordinator = contractAddresses.vrfCoordinator;
        config.linkToken = contractAddresses.linkToken;
        config.linkFee = _linkFee;
        config.vrfKeyHash = _vrfKeyHash;

        _owner = 0x7F05F27CC5D83C3e879C53882de13Cc1cbCe8a8c;
    }

    function owner() external view virtual returns (address) {
        return _owner;
    }

    function setOwner(address owner_) external onlyAdmin {
        _owner = owner_;
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.seedphrase.codes/metadata/seedphrase-metadata.json";
    }

    function getVrfSeed() external onlyAdmin returns (bytes32) {
        require(!config.vrfNumberGenerated, "SP:VRF_ALREADY_CALLED");
        require(LINK.balanceOf(address(this)) >= config.linkFee, "SP:NOT_ENOUGH_LINK");
        return requestRandomness(config.vrfKeyHash, config.linkFee);
    }

    function fulfillRandomness(bytes32, uint256 randomNumber) internal override {
        config.vrfRandomValue = randomNumber;
        config.vrfNumberGenerated = true;
    }

    function _getTokenSeed(uint256 tokenId) internal view returns (bytes32) {
        return maps.tokenSeed[tokenId];
    }

    function _getBipWordIdFromTokenId(uint256 tokenId) internal view returns (uint16) {
        return bipWordIds[tokenId - 1];
    }

    function tokenSVG(uint256 tokenId) public view virtual returns (string memory svg, bytes memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        SeedPhraseUtils.Random memory random = SeedPhraseUtils.Random({
            seed: uint256(_getTokenSeed(tokenId)),
            offsetBit: 0
        });

        uint16 bipWordId;
        uint16 secondBipWordId = 0;
        uint8 rarityValue = 0;
        if (tokenId >= 3000) {
            uint256[2] memory tokens = maps.burnedTokensPairings[tokenId];
            bipWordId = _getBipWordIdFromTokenId(tokens[0]);
            secondBipWordId = _getBipWordIdFromTokenId(tokens[1]);
            rarityValue = maps.doubleTokenRarity[tokenId];
        } else {
            bipWordId = _getBipWordIdFromTokenId(tokenId);
        }

        (bytes memory traits, SeedPhraseUtils.Attrs memory attributes) = SeedPhraseUtils.getTraitsAndAttributes(
            bipWordId,
            secondBipWordId,
            rarityValue,
            random
        );

        return (SeedPhraseUtils.render(random, attributes), traits);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        (string memory output, bytes memory traits) = tokenSVG(tokenId);

        return SeedPhraseUtils.getTokenURI(output, traits, tokenId);
    }

    /**
    Updates the presale state for n holders
     */
    function setPreSaleState(bool _preSaleActiveState) external onlyAdmin {
        config.preSaleActive = _preSaleActiveState;
    }

    /**
    Updates the public sale state for non-n holders
     */
    function setPublicSaleState(bool _publicSaleActiveState) external onlyAdmin {
        config.publicSaleActive = _publicSaleActiveState;
    }

    function setPreSaleTime(uint32 _time) external onlyAdmin {
        config.preSaleLaunchTime = _time;
    }

    function setPublicSaleTime(uint32 _time) external onlyAdmin {
        config.publicSaleLaunchTime = _time;
    }

    /**
    Give the ability to halt the sale if necessary due to automatic sale enablement based on time
     */
    function setSaleHaltedState(bool _saleHaltedState) external onlyAdmin {
        config.isSaleHalted = _saleHaltedState;
    }

    function setBurnActiveState(bool _burnActiveState) external onlyAdmin {
        config.isBurnActive = _burnActiveState;
    }

    function setGenesisSketchAllowList(address[] calldata addresses) external onlyAdmin {
        genesisSketchAddresses = addresses;
    }

    function setOgAllowList(address[] calldata addresses) external onlyAdmin {
        for (uint256 i = 0; i < addresses.length; i++) {
            maps.ogAddresses[addresses[i]] = true;
        }
    }

    function _isPreSaleActive() internal view returns (bool) {
        return ((block.timestamp >= config.preSaleLaunchTime || config.preSaleActive) && !config.isSaleHalted);
    }

    function _isPublicSaleActive() internal view override returns (bool) {
        return ((block.timestamp >= config.publicSaleLaunchTime || config.publicSaleActive) && !config.isSaleHalted);
    }

    function _canMintPresale(
        address addr,
        uint256 amount,
        bytes memory data
    ) internal view override returns (bool, PreSaleType) {
        if (maps.ogAddresses[addr] && presaleLimits[PreSaleType.OG] - amount >= 0) {
            return (true, PreSaleType.OG);
        }

        bool isGsHolder;
        for (uint256 i = 0; i < genesisSketchAddresses.length; i++) {
            if (genesisSketchAddresses[i] == addr) {
                isGsHolder = true;
            }
        }

        if (isGsHolder && presaleLimits[PreSaleType.GenesisSketch] - amount >= 0) {
            return (true, PreSaleType.GenesisSketch);
        }

        if (rarible.balanceOf(addr, config.raribleTokenId) > 0 && presaleLimits[PreSaleType.GM] - amount > 0) {
            return (true, PreSaleType.GM);
        }

        uint256 karmaScore = SeedPhraseUtils.getKarma(karma, data, addr);
        if (nOwnerResolver.balanceOf(addr) > 0) {
            if (karmaScore >= config.karmaRequirement && presaleLimits[PreSaleType.Karma] - amount >= 0) {
                return (true, PreSaleType.Karma);
            }

            if (presaleLimits[PreSaleType.N] - amount >= 0) {
                return (true, PreSaleType.N);
            }
        }

        return (false, PreSaleType.None);
    }

    function canMint(address account, bytes calldata data) public view virtual override returns (bool) {
        if (config.isBurnActive) {
            return false;
        }

        uint256 balance = balanceOf(account);

        if (_isPublicSaleActive() && (totalMintsAvailable() > 0) && balance < config.maxPublicMint) {
            return true;
        }

        if (_isPreSaleActive()) {
            (bool preSaleEligible, ) = _canMintPresale(account, 1, data);
            return preSaleEligible;
        }

        return false;
    }

    /**
     * @notice Allow a n token holder to bulk mint tokens with id of their n tokens' id
     * @param recipient Recipient of the mint
     * @param tokenIds Ids to be minted
     * @param paid Amount paid for the mint
     */
    function mintWithN(
        address recipient,
        uint256[] calldata tokenIds,
        uint256 paid,
        bytes calldata data
    ) public virtual override nonReentrant {
        uint256 maxTokensToMint = tokenIds.length;
        (bool preSaleEligible, PreSaleType presaleType) = _canMintPresale(recipient, maxTokensToMint, data);

        require(config.bipWordsShuffled && config.vrfNumberGenerated, "SP:ENV_NOT_INIT");
        require(_isPublicSaleActive() || (_isPreSaleActive() && preSaleEligible), "SP:SALE_NOT_ACTIVE");
        require(
            balanceOf(recipient) + maxTokensToMint <= _getMaxMintPerWallet(),
            "NilPass:MINT_ABOVE_MAX_MINT_ALLOWANCE"
        );
        require(!config.isBurnActive, "SP:SALE_OVER");

        require(totalSupply() + maxTokensToMint <= params.maxTotalSupply, "NilPass:MAX_ALLOCATION_REACHED");

        uint256 price = getNextPriceForNHoldersInWei(maxTokensToMint, recipient, data);
        require(paid == price, "NilPass:INVALID_PRICE");

        for (uint256 i = 0; i < maxTokensToMint; i++) {
            require(!nUsed[tokenIds[i]], "SP:N_ALREADY_USED");

            uint256 tokenId = _tokenIds.current();
            require(tokenId <= params.maxTotalSupply, "SP:TOKEN_TOO_HIGH");

            maps.tokenSeed[tokenId] = SeedPhraseUtils.generateSeed(tokenId, config.vrfRandomValue);

            _safeMint(recipient, tokenId);
            _tokenIds.increment();

            nUsed[tokenIds[i]] = true;
        }

        if (preSaleEligible) {
            presaleLimits[presaleType] -= uint16(maxTokensToMint);
        }
    }

    /**
     * @notice Allow anyone to mint a token with the supply id if this pass is unrestricted.
     *         n token holders can use this function without using the n token holders allowance,
     *         this is useful when the allowance is fully utilized.
     * @param recipient Recipient of the mint
     * @param amount Amount of tokens to mint
     * @param paid Amount paid for the mint
     */
    function mint(
        address recipient,
        uint8 amount,
        uint256 paid,
        bytes calldata data
    ) public virtual override nonReentrant {
        (bool preSaleEligible, PreSaleType presaleType) = _canMintPresale(recipient, amount, data);

        require(config.bipWordsShuffled && config.vrfNumberGenerated, "SP:ENV_NOT_INIT");
        require(
            _isPublicSaleActive() ||
                (_isPreSaleActive() &&
                    preSaleEligible &&
                    (presaleType != PreSaleType.N && presaleType != PreSaleType.Karma)),
            "SP:SALE_NOT_ACTIVE"
        );
        require(!config.isBurnActive, "SP:SALE_OVER");

        require(balanceOf(recipient) + amount <= _getMaxMintPerWallet(), "NilPass:MINT_ABOVE_MAX_MINT_ALLOWANCE");
        require(totalSupply() + amount <= params.maxTotalSupply, "NilPass:MAX_ALLOCATION_REACHED");

        uint256 price = getNextPriceForOpenMintInWei(amount, recipient, data);
        require(paid == price, "NilPass:INVALID_PRICE");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIds.current();
            require(tokenId <= params.maxTotalSupply, "SP:TOKEN_TOO_HIGH");
            maps.tokenSeed[tokenId] = SeedPhraseUtils.generateSeed(tokenId, config.vrfRandomValue);

            _safeMint(recipient, tokenId);
            _tokenIds.increment();
        }

        if (preSaleEligible) {
            presaleLimits[presaleType] -= amount;
        }
    }

    function mintOwnerSupply(address account) public nonReentrant onlyAdmin {
        require(!config.isOwnerSupplyMinted, "SP:ALREADY_MINTED");
        require(config.bipWordsShuffled && config.vrfNumberGenerated, "SP:ENV_NOT_INIT");
        require(
            totalSupply() + config.ownerSupply <= params.maxTotalSupply,
            "NilPass:MAX_ALLOCATION_REACHED"
        );

        for (uint256 i = 0; i < config.ownerSupply; i++) {
            uint256 tokenId = _tokenIds.current();
            maps.tokenSeed[tokenId] = SeedPhraseUtils.generateSeed(tokenId, config.vrfRandomValue);

            _mint(account, tokenId);
            _tokenIds.increment();
        }

        config.isOwnerSupplyMinted = true;
    }

    /**
     * @notice Allow anyone to burn two single panels they own in order to mint
     *         a double paneled token.
     * @param firstTokenId Token ID of the first token
     * @param secondTokenId Token ID of the second token
     */
    function burnForDoublePanel(uint256 firstTokenId, uint256 secondTokenId) public nonReentrant {
        require(config.isBurnActive, "SP:BURN_INACTIVE");
        require(ownerOf(firstTokenId) == msg.sender && ownerOf(secondTokenId) == msg.sender, "SP:INCORRECT_OWNER");
        require(firstTokenId != secondTokenId, "SP:EQUAL_TOKENS");
        // Ensure two owned tokens are in Burnable token pairings
        require(
            isValidPairing(_getBipWordIdFromTokenId(firstTokenId), _getBipWordIdFromTokenId(secondTokenId)),
            "SP:INVALID_TOKEN_PAIRING"
        );

        _burn(firstTokenId);
        _burn(secondTokenId);

        // Any Token ID of 3000 or greater indicates it is a double panel e.g. 3000, 3001, 3002...
        uint256 doublePanelTokenId = 3000 + _doublePanelTokens.current();
        maps.tokenSeed[doublePanelTokenId] = SeedPhraseUtils.generateSeed(doublePanelTokenId, config.vrfRandomValue);

        // Get the rarity rating from the burned tokens, store this against the new token
        // Burners are guaranteed their previous strongest trait (at least, could be rarer)
        uint8 rarity1 = SeedPhraseUtils.getRarityRating(_getTokenSeed(firstTokenId));
        uint8 rarity2 = SeedPhraseUtils.getRarityRating(_getTokenSeed(secondTokenId));
        maps.doubleTokenRarity[doublePanelTokenId] = (rarity1 > rarity2 ? rarity1 : rarity2);

        _mint(msg.sender, doublePanelTokenId);

        // Add burned tokens to maps.burnedTokensPairings mapping so we can use them to render the double panels later
        maps.burnedTokensPairings[doublePanelTokenId] = [firstTokenId, secondTokenId];
        _doublePanelTokens.increment();

        emit Burnt(msg.sender, firstTokenId, secondTokenId, doublePanelTokenId);
    }

    function airdropGenesisSketch() public nonReentrant onlyAdmin {
        require(!config.isGsAirdropComplete, "SP:ALREADY_AIRDROPPED");
        require(config.bipWordsShuffled && config.vrfNumberGenerated, "SP:ENV_NOT_INIT");

        uint256 airdropAmount = genesisSketchAddresses.length;
        require(totalSupply() + airdropAmount <= params.maxTotalSupply, "NilPass:MAX_ALLOCATION_REACHED");

        for (uint256 i = 0; i < airdropAmount; i++) {
            uint256 tokenId = _tokenIds.current();
            maps.tokenSeed[tokenId] = SeedPhraseUtils.generateSeed(tokenId, config.vrfRandomValue);

            _mint(genesisSketchAddresses[i], tokenId);
            _tokenIds.increment();
        }

        config.isGsAirdropComplete = true;
    }

    function mintOrphanedPieces(uint256 amount, address addr) public nonReentrant onlyAdmin {
        require(totalMintsAvailable() == 0, "SP:MINT_NOT_OVER");
        
        // _tokenIds - 1 to get the current number of minted tokens (token IDs start at 1)
        uint256 currentSupply = _tokenIds.current() - 1;

        config.doubleBurnTokens = derivativeParams.maxTotalSupply - currentSupply;

        require(config.doubleBurnTokens >= amount, "SP:NOT_ENOUGH_ORPHANS");
        require(currentSupply + amount <= params.maxTotalSupply, "NilPass:MAX_ALLOCATION_REACHED");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIds.current();
            require(tokenId <= params.maxTotalSupply, "SP:TOKEN_TOO_HIGH");

            maps.tokenSeed[tokenId] = SeedPhraseUtils.generateSeed(tokenId, config.vrfRandomValue);

            _mint(addr, tokenId);
            _tokenIds.increment();
        }

        config.doubleBurnTokens -= amount;
    }

    /**
     * @notice Calculate the total available number of mints
     * @return total mint available
     */
    function totalMintsAvailable() public view override returns (uint256) {
        uint256 totalAvailable = derivativeParams.maxTotalSupply - totalSupply();
        if (block.timestamp > config.publicSaleLaunchTime + 18 hours) {
            // Double candle burning starts and decreases max. mintable supply with 1 token per minute.
            uint256 doubleBurn = (block.timestamp - (config.publicSaleLaunchTime + 18 hours)) / 1 minutes;
            totalAvailable = totalAvailable > doubleBurn ? totalAvailable - doubleBurn : 0;
        }

        return totalAvailable;
    }

    function getDoubleBurnedTokens() external view returns (uint256) {
        return config.doubleBurnTokens;
    }

    function _getMaxMintPerWallet() internal view returns (uint128) {
        return _isPublicSaleActive() ? config.maxPublicMint : params.maxMintAllowance;
    }

    function isValidPairing(uint16 first, uint16 second) public view returns (bool) {
        return maps.doubleWordPairings[first] == second;
    }

    function amendPairings(uint16[][] calldata pairings) external onlyAdmin {
        for (uint16 i = 0; i < pairings.length; i++) {
            if (pairings[i].length != 2) {
                continue;
            }

            maps.doubleWordPairings[pairings[i][0]] = pairings[i][1];
        }
    }

    function shuffleBipWords() external onlyAdmin {
        require(config.vrfNumberGenerated, "SP:VRF_NOT_CALLED");
        require(!config.bipWordsShuffled, "SP:ALREADY_SHUFFLED");
        bipWordIds = SeedPhraseUtils.shuffleBipWords(config.vrfRandomValue);
        config.bipWordsShuffled = true;
    }
}