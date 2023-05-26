// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NFTC Contract Base
 * @author @NiftyMike, NFT Culture
 * @notice OpenZeppelin ERC721URIStorage + ERC721Enumerable with some extras.
 * @dev Featuring:
 *      - Extensible Artwork
 *      - Dynamic Forging System
 *      - Burn Minting
 *
 *  About NFT Culture:
 *  NFT Culture is about the intersection of Artists, Collectors and
 *  Marketplaces, with a focus on technology (crypto or otherwise) and
 *  how it can align all three and keep the dynamic of this NFT
 *  movement centered in a way that benefits all of the stakeholders.
 *
 *  Join us in our Discord: https://discord.gg/AhQmvs9Crq
 *
 *  Are you a solidity dev looking for a community? We would love to have
 *  you in the #💾┃tech-and-dev-home channel.
 */
abstract contract NFTCBase is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    event ActionBuy(address indexed _owner, uint256 _id, uint256 count);

    uint256 private constant MAX_MINT_PER_TRANS = 33;
    uint256 private constant MAX_COMBINABLE_TOKENS = 12;

    uint256 public startingBlockNumber;
    uint256 public pricePerNft;
    uint256 public burnMintPricePerNft;
    uint256 public maxNftsForSale;
    uint256 public numberOfFlavors;
    bool public lastBitEnabled;

    string public baseURI;
    string public defaultFlavorURI;

    bool public mintingActive;
    bool public forgingActive;
    bool public burnMintingActive;

    mapping(uint256 => string) private _flavorURIs;
    mapping(uint256 => bool) private _flavorEligibilityMap;

    mapping(uint256 => uint256) private _tokenFlavors;
    mapping(uint256 => address) private _tokenSlotOwners;

    Counters.Counter private _coinMintCounter;

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseUri,
        string memory __defaultFlavorUri,
        uint256 __startingBlockNumber,
        uint256 __maxNftsForSale,
        uint256 __pricePerNft,
        uint256 __mintableFlavors,
        bool __lastBitEnabled
    ) ERC721(__name, __symbol) {
        // Metadata config
        baseURI = __baseUri;
        defaultFlavorURI = __defaultFlavorUri;

        // Minting config
        startingBlockNumber = __startingBlockNumber;
        maxNftsForSale = __maxNftsForSale;
        pricePerNft = __pricePerNft;
        burnMintPricePerNft = __pricePerNft;

        // Config for the flavor/forging system.
        numberOfFlavors = __mintableFlavors;
        lastBitEnabled = __lastBitEnabled;

        _initFlavors(numberOfFlavors, lastBitEnabled);
    }

    /**
     * NFTCult tokens contain art featuring the NFTCulture logo, and work
     * done by the NFT Culture community. NFT Culture retains the copyright
     * to NFTCult token artwork, and grants a revokable limited commercial
     * license to active holders of the token. For exact details, see the TOS
     * and License hosted on www.nftculture.com, which is subject to change.
     * Consider this comment public notice of the terms under which these
     * tokens are minted. Accessing this function implies agreement with the
     * terms.
     */
    function mintCultTokens(uint256 count) external payable nonReentrant {
        require(block.number > startingBlockNumber, "Not started");
        require(mintingActive, "Not active");
        require(0 < count && count <= MAX_MINT_PER_TRANS, "Invalid count");
        require(pricePerNft * count == msg.value, "Invalid price");

        _mintCultTokens(_msgSender(), count);
    }

    function burnMintCultToken(uint256 tokenId, uint256 desiredFlavor)
        external
        payable
        nonReentrant
    {
        require(block.number > startingBlockNumber, "Not started");
        require(burnMintingActive, "Not active");
        require(!_exists(tokenId), "Token exists");
        require(_msgSender() == _tokenSlotOwners[tokenId], "Not owner");
        require(burnMintPricePerNft == msg.value, "Invalid price");
        require(
            _flavorEligibilityMap[desiredFlavor] == true,
            "Ineligible flavor"
        );

        _burnMintCultTokens(_msgSender(), tokenId, desiredFlavor);
    }

    function airdropCultTokens(
        address[] memory friends,
        uint256[] memory tokenIds,
        uint256 desiredFlavor
    ) external onlyOwner {
        require(friends.length == tokenIds.length, "Unmatched arrays");
        require(
            _flavorEligibilityMap[desiredFlavor] == true,
            "Ineligible flavor"
        );

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            require(!_exists(tokenIds[idx]), "Token exists");
            require(
                friends[idx] == _tokenSlotOwners[tokenIds[idx]],
                "Not owner"
            );

            _burnMintCultTokens(friends[idx], tokenIds[idx], desiredFlavor);
        }
    }

    function reserveCultTokens(address[] memory friends, uint256 count)
        external
        onlyOwner
    {
        require(0 < count && count <= MAX_MINT_PER_TRANS, "Invalid count");

        uint256 idx;
        for (idx = 0; idx < friends.length; idx++) {
            _mintCultTokens(friends[idx], count);
        }
    }

    /**
     * Forge tokens together to create new tokens.
     * Note: provided array are the owner's indexes of tokens, NOT tokenIds.
     * EX: Owner owns [ID#55, ID#99, ID#2012]
     * The owner token indexes might be [1, 3, 2] (My point: its unrelated to
     * the ID of the token.)
     */
    function forgeCultTokens(
        uint256[] memory candidateOwnerIndexes,
        uint256 opCode
    ) external nonReentrant {
        require(forgingActive == true, "Forging not active");
        require(
            candidateOwnerIndexes.length < MAX_COMBINABLE_TOKENS,
            "Too many tokens"
        );

        require(opCode == 0 || opCode == 1 || opCode == 2, "Invalid opcode");

        uint256 idx;
        uint256[] memory tokenIdsToForge = new uint256[](
            candidateOwnerIndexes.length
        );

        for (idx = 0; idx < candidateOwnerIndexes.length; idx++) {
            // Validate existence and ownership.
            tokenIdsToForge[idx] = tokenOfOwnerByIndex(
                _msgSender(),
                candidateOwnerIndexes[idx]
            );
        }

        uint256 craftedTokenId = maxNftsForSale + 1;
        uint256 targetFlavor = 0;
        uint256 checkValue = 0;

        for (idx = 0; idx < tokenIdsToForge.length; idx++) {
            uint256 tokenFlavor = _tokenFlavors[tokenIdsToForge[idx]];

            if (opCode == 0) {
                // lateral forge [Must be same flavor]
                if (checkValue == 0) {
                    checkValue = (tokenFlavor / 100) * 100;
                } else {
                    require(
                        checkValue == (tokenFlavor / 100) * 100,
                        "Incompatible flavors"
                    );
                }

                targetFlavor += tokenFlavor % 100;
            } else if (opCode == 1) {
                // vertical forge [Must be same color scheme]
                if (checkValue == 0) {
                    checkValue = tokenFlavor % 100;
                } else {
                    require(
                        checkValue == tokenFlavor % 100,
                        "Incompatible colors"
                    );
                }

                targetFlavor += tokenFlavor / 100;
            } else if (opCode == 2) {
                // multiply forge
                targetFlavor = targetFlavor == 0
                    ? tokenFlavor
                    : targetFlavor * tokenFlavor;
            }

            // Keep track of the lowest id to use for the new mint.
            if (tokenIdsToForge[idx] < craftedTokenId) {
                craftedTokenId = tokenIdsToForge[idx];
            }
        }

        if (opCode == 0) {
            targetFlavor = targetFlavor + checkValue;
        } else if (opCode == 1) {
            targetFlavor = (targetFlavor * 100) + checkValue;
        }

        // Make sure the requested forge target exists.
        require(
            bytes(_flavorURIs[targetFlavor]).length > 0,
            "Forge impossible"
        );

        // Now burn the pieces
        for (idx = 0; idx < tokenIdsToForge.length; idx++) {
            _burn(tokenIdsToForge[idx]);
        }

        // Make sure the slot is now free.
        require(!_exists(craftedTokenId), "Can't re-mint");
        require(craftedTokenId <= maxNftsForSale, "Bad token id");

        // Execute the mint.
        _safeMint(_msgSender(), craftedTokenId);
        _setTokenURI(craftedTokenId, targetFlavor);
    }

    function burnCultToken(uint256 tokenId) external nonReentrant {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not owner or approved"
        );

        _burn(tokenId);
    }

    function setBaseURI(string memory __baseUri) external onlyOwner {
        baseURI = __baseUri;
    }

    // Bulk method to allow one single call to set up the contract.
    function setFlavorURIBulk(
        uint256[] memory flavorIndex,
        string[] memory flavorUri,
        bool[] memory extendedFlavor,
        bool[] memory enableBurnMinting
    ) external onlyOwner {
        require(
            flavorIndex.length == flavorUri.length &&
                flavorIndex.length == extendedFlavor.length &&
                flavorIndex.length == enableBurnMinting.length,
            "Unmatched arrays"
        );

        uint256 idx;
        for (idx = 0; idx < flavorIndex.length; idx++) {
            _setFlavorUri(
                flavorIndex[idx],
                flavorUri[idx],
                extendedFlavor[idx],
                enableBurnMinting[idx]
            );
        }
    }

    function setMintingState(
        bool __mintingActive,
        uint256 __startingBlockNumber,
        bool __forgingActive,
        uint256 __burnMintPricePerNft,
        bool __burnMintingActive
    ) external onlyOwner {
        mintingActive = __mintingActive;

        if (__startingBlockNumber > 0) {
            startingBlockNumber = __startingBlockNumber;
        }

        forgingActive = __forgingActive;

        if (__burnMintPricePerNft > 0) {
            burnMintPricePerNft = __burnMintPricePerNft;
        }

        burnMintingActive = __burnMintingActive;
    }

    /**
     * Special thanks to my friend of 20+ years and business partner
     * Mal, wouldn't have been able to do this without you. - Mike
     *
     * Additionally, thanks to all NFT Culture community members,
     * you guys are awesome, and this has been an incredible journey.
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "No token");
        string memory base = _baseURI();
        require(bytes(base).length > 0, "Base unset");

        uint256 tokenFlavor = _tokenFlavors[tokenId];

        string memory ipfsUri;
        // If there is no flavor URI, use default uri.
        if (bytes(_flavorURIs[tokenFlavor]).length == 0) {
            ipfsUri = defaultFlavorURI;
        } else {
            ipfsUri = _flavorURIs[tokenFlavor];
        }

        return string(abi.encodePacked(base, ipfsUri, _tokenFilename(tokenId)));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _tokenFilename(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        uint256 tokenSlot = 10000 + tokenId;
        return tokenSlot.toString();
    }

    function _setTokenURI(uint256 tokenId, uint256 tokenFlavor)
        internal
        virtual
    {
        require(_exists(tokenId), "No token");
        _tokenFlavors[tokenId] = tokenFlavor;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (_tokenFlavors[tokenId] > 0) {
            delete _tokenFlavors[tokenId];
        }

        _tokenSlotOwners[tokenId] = _msgSender();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _initFlavors(uint256 __numberOfFlavors, bool __lastBitEnabled)
        internal
        virtual
    {
        // Default implementation assumes flavors will be set with write
        // calls to the contract.
    }

    function _assignFlavor(
        uint256 flavorIndex,
        string memory flavorUri,
        bool enableBurnMinting
    ) internal {
        _flavorURIs[flavorIndex] = flavorUri;
        _flavorEligibilityMap[flavorIndex] = enableBurnMinting;
    }

    function _setFlavorUri(
        uint256 flavorIndex,
        string memory flavorUri,
        bool extendedFlavor,
        bool enableBurnMinting
    ) internal {
        // Initially extendedFlavor is a safeguard against overwriting mint
        // config, but ultimately can toggle extendedFlavor as needed to
        // update or create things.
        if (extendedFlavor) {
            require(
                bytes(_flavorURIs[flavorIndex]).length == 0,
                "Cannot overwrite"
            );
        } else {
            require(
                bytes(_flavorURIs[flavorIndex]).length > 0,
                "Flavor not exists"
            );
        }

        _assignFlavor(flavorIndex, flavorUri, enableBurnMinting);
    }

    function _getEntropy(uint256 tokenId, bytes32 __previousBlockHash)
        internal
        view
        virtual
        returns (uint256)
    {
        // Pseudorandom.
        return
            uint256(keccak256(abi.encodePacked(__previousBlockHash, tokenId)));
    }

    // Underscore arguments are being passed in to reduce access to storage variables within the minting loop.
    function _randomFlavorFor(
        uint256 tokenId,
        uint256 __maxNftsForSale,
        uint256 __numberOfFlavors,
        bool __lastBitEnabled,
        bytes32 __previousBlockHash
    ) internal view returns (uint256) {
        require(numberOfFlavors <= 9, "Too many flavors");

        uint256 someEntropy = _getEntropy(tokenId, __previousBlockHash);

        // We need two pseudorandom numbers to pick our selected image,
        // so use the first half and second half of the 256 bit number
        // for this.
        uint256 rightBitSelection = uint128(someEntropy) % __maxNftsForSale;
        uint256 leftBitSelection = uint128(someEntropy >> 128) %
            __maxNftsForSale;

        uint256 theFlavor;
        uint256 lastBit = 0;

        if (__lastBitEnabled) {
            // Distributed uniformly. Start at 200, for forging compatibility.
            theFlavor = ((rightBitSelection % __numberOfFlavors) + 2) * 100;

            // Distributed based on golden ratio.
            lastBit = (leftBitSelection % 100) > 61 ? 2 : 1;
        } else {
            theFlavor = ((rightBitSelection % __numberOfFlavors) + 1) * 100;
        }

        // Combine the two variables into one 3 digit number.
        return theFlavor + lastBit;
    }

    function _mintCultTokens(address minter, uint256 count) internal {
        require(minter != address(0), "Bad address");

        // Save off global references to avoid accessing these when minting multiples.
        uint256 __maxNftsForSale = maxNftsForSale;
        uint256 __numberOfFlavors = numberOfFlavors;
        bool __lastBitEnabled = lastBitEnabled;
        bytes32 __previousBlockHash = blockhash(block.number - 1);

        require(
            _coinMintCounter.current() + count <= __maxNftsForSale,
            "Limit exceeded"
        );

        uint256 idx;
        uint256 tokenId;
        uint256 tokenFlavor;
        for (idx = 0; idx < count; idx++) {
            _coinMintCounter.increment();
            tokenId = _coinMintCounter.current();
            _safeMint(minter, tokenId);

            tokenFlavor = _randomFlavorFor(
                tokenId,
                __maxNftsForSale,
                __numberOfFlavors,
                __lastBitEnabled,
                __previousBlockHash
            );
            
            _setTokenURI(tokenId, tokenFlavor);
        }
    }

    function _burnMintCultTokens(
        address minter,
        uint256 tokenId,
        uint256 desiredFlavor
    ) internal {
        require(minter != address(0), "Bad address");

        _safeMint(minter, tokenId);
        _setTokenURI(tokenId, desiredFlavor);

        delete _tokenSlotOwners[tokenId];
    }
}