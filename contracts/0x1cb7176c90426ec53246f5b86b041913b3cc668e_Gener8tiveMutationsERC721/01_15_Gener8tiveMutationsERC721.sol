//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Gener8tiveMutationsERC721 is ERC721URIStorage, ERC721Holder, Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    // =======================================================
    // EVENTS
    // =======================================================
    event TokenMinted(uint256 indexed tokenIndex, string tokenUri);
    event PriceChanged(uint256 newPrice);
    event ContractMetaDataAdded(uint8 index, string info);
    event TokenUriUpdated(uint16 tokenId, string uri);

    // =======================================================
    // STORAGE
    // =======================================================
    Counters.Counter public tokenId;
    
    uint256 public price = 350000000 gwei;
    uint256 public feePercentage = 50;
    uint16 public maxSupply = 256;

    string[] public contractMetadata;
    address payable public causeBeneficiary;
    mapping(uint256 => address) public creators;
    string mintBaseUrl;

    string[] rarities = ["Ultra Rare", "Extremely Rare", "Extremely Rare", "Extremely Rare", "Rare", "Rare", "Rare", "Rare", "Rare", "Rare", "Rare", "Rare", "Extremely Rare", "Extremely Rare", "Extremely Rare", "Ultra Rare"];

    uint8[] tuning_numCreatorTrianges = [3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6];
    uint8[] tuning_numSpikes = [8, 8, 8, 8, 7, 7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 1];
    uint8[] tuning_spikeAngleMultiplier = [2, 3, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 7, 8, 8, 8];
    uint8[] tuning_spikeLengthMultiplier = [4, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 1, 1, 1];
    uint16[] tuning_creatorDrawMultiplier = [20, 19, 18, 17, 16, 15, 14, 14, 13, 13, 12, 12, 11, 11, 10, 9];

    bool mintingEnabled = true;

    // =======================================================
    // STRUCTS & ENUMS
    // =======================================================
    struct Triangle { uint x1; uint y1; uint x2; uint y2; uint x3; uint y3; }
    struct HslColor { uint32 hue; uint saturation; uint lightness; }
    struct Spike { uint8 x; uint8 y; }
    struct TokenData {
        uint8 variant;
        uint8 mutationParts;
        uint16 mutationMultiplier;
        uint8 numSpikes;
        uint8 spikeAngle;
        uint8 spikeLength;
        bytes creator;
        bytes32 tokenHash;
        string rarity;
        HslColor creatorColor;
        Triangle[] creatorTriangles;
        Spike[] spikes;
    }

    // =======================================================
    // CONSTRUCTOR
    // =======================================================
    constructor(string memory _name,
        string memory _symbol,
        string memory _baseUrl,
        address payable _causeBeneficiary
    )
        ERC721(_name, _symbol)
    {
        contractMetadata = new string[](10);
        mintBaseUrl = _baseUrl;

        changeCauseBeneficiary(_causeBeneficiary);
    }

    // =======================================================
    // ADMIN
    // =======================================================
    function applyHandbrake()
        public
        onlyOwner
    {
        mintingEnabled = false;
    }

    function releaseHandbrake()
        public
        onlyOwner
    {
        mintingEnabled = true;
    }

    function updateTokenURI(uint16 _tokenId, string memory newTokenURI)
        public
        onlyOwner
    {
        super._setTokenURI(_tokenId,  newTokenURI);
        emit TokenUriUpdated(_tokenId, newTokenURI);
    }

    function changeCauseBeneficiary(address payable newCauseBeneficiary)
        public
        onlyOwner
    {
        causeBeneficiary = newCauseBeneficiary;
    }

    function changeFeePercentage(uint256 percentage)
        public
        onlyOwner
    {
        feePercentage = percentage;
    }

    function changePrice(uint256 newPrice)
        public
        onlyOwner
    {
        price = newPrice;
        emit PriceChanged(newPrice);
    }

    function writeContractMetaData(uint8 index, string memory info)
        public
        onlyOwner
    {
        contractMetadata[index] = info;
        emit ContractMetaDataAdded(index, info);
    }

    function withdrawFunds(address payable recipient, uint256 amount)
        public
        onlyOwner
    {
        recipient.transfer(amount);
    }

    function ownerMint(address ownerAddress)
        public
        onlyOwner
    {
        internalMint(ownerAddress);
    }

    // =======================================================
    // UTILS & HELPERS
    // =======================================================
    function getCreatorData(bytes memory creator, uint8 numCreatorTrianges, uint16 creatorDrawMultiplier)
        private
        pure
        returns(HslColor memory creatorColor, Triangle[] memory creatorTriangles)
    {
        uint8 pointer = 0;

        creatorColor = HslColor({
            hue: uint8((creator[pointer] >> 4) & 0x0f), //22.5 accuracy
            saturation: uint8(creator[pointer] & 0x0f), //6.25 accuracy
            lightness: uint8(creator[++pointer] >> 4) & 0x0f //6.25 accuracy
        });

        creatorTriangles = new Triangle[](numCreatorTrianges);

        for(uint8 t = 0; t < numCreatorTrianges; t++) {
            Triangle memory triangle = Triangle({
                x1: uint8(creator[pointer] & 0x0f) * creatorDrawMultiplier,
                y1: uint8((creator[++pointer] >> 4) & 0x0f) * creatorDrawMultiplier,
                x2: uint8(creator[pointer] & 0x0f) * creatorDrawMultiplier,
                y2: uint8((creator[++pointer] >> 4) & 0x0f) * creatorDrawMultiplier,
                x3: uint8(creator[pointer] & 0x0f) * creatorDrawMultiplier,
                y3: uint8((creator[++pointer] >> 4) & 0x0f) * creatorDrawMultiplier
            });

            creatorTriangles[t] = triangle;
        }
    }

    function getSpikeData(bytes32 tokenHash,
        uint8 numSpikes,
        uint8 spikeAngleMultiplier,
        uint8 spikeLengthMultiplier
    )
        private
        pure
        returns(Spike[] memory spikes)
    {
        uint8 pointer = 0;

        spikes = new Spike[](numSpikes);

        for(uint8 s = 0; s < numSpikes; s++) {
            Spike memory spike = Spike({
                x: uint8((tokenHash[pointer] >> 4) & 0x0f) * spikeAngleMultiplier,
                y: uint8(tokenHash[pointer] & 0x0f) * spikeLengthMultiplier
            });
            pointer++;

            spikes[s] = spike;
        }
    }

    function getMutationData(uint16 _tokenId,
        uint8 numCreatorTrianges,
        uint16 creatorDrawMultiplier,
        uint8 numSpikes,
        uint8 spikeAngleMultiplier,
        uint8 spikeLengthMultiplier
    )
        private
        view
        returns(bytes memory creator,
            bytes32 tokenHash,
            HslColor memory creatorColor,
            Triangle[] memory creatorTriangles,
            Spike[] memory spikes
        )
    {
        //creator signature
        creator = abi.encodePacked(creators[_tokenId]);
        tokenHash = keccak256(abi.encodePacked(_tokenId));

        (creatorColor, creatorTriangles) = getCreatorData(creator, numCreatorTrianges, creatorDrawMultiplier);

        // spikes
        spikes = getSpikeData(tokenHash, numSpikes, spikeAngleMultiplier, spikeLengthMultiplier);
    }

    function div256(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function internalMint(address owner)
        private
    {
        super._safeMint(msg.sender, tokenId.current());
        string memory tokenUri = string(abi.encodePacked(mintBaseUrl, tokenId.current().toString()));
        super._setTokenURI(tokenId.current(), tokenUri);
        
        creators[tokenId.current()] = owner;
        tokenId.increment();

        emit TokenMinted(tokenId.current() - 1, tokenUri);
    }

    // =======================================================
    // PUBLIC API
    // =======================================================
    function getSupplyData()
        external
        view
        returns(
            uint256 currentTokenId,
            uint256 supplyDataPrice,
            uint16 supplyDataMaxSupply,
            address cBeneficiary,
            uint256 supplyDataFeePercentage
        )
    {
        currentTokenId = tokenId.current();
        supplyDataPrice = price;
        supplyDataMaxSupply = maxSupply;
        cBeneficiary = causeBeneficiary;
        supplyDataFeePercentage = feePercentage;
    }

    function mint()
        external
        payable
    {
        // check minting handbrake
        require(mintingEnabled, "Minting is currently disabled");

        // ensure the max supply has not been reached
        if(tokenId.current() > 0) {
            require(tokenId.current() - 1 < maxSupply, "Max tokens issued");
        }

        // disallow same creator for two consecutive tokens
        if(tokenId.current() > 0) {
            require(creators[tokenId.current() - 1] != msg.sender);
        }

        // ensure sufficient funds were sent
        require(msg.value >= price, "Insufficient ETH sent");
        
        // // calculate system fees percentage
        uint256 fee = div256((feePercentage * msg.value), 100);

        // // send to cause beneficiary (revert if no beneficiary is set)
        require(causeBeneficiary != address(0), "Cause Beneficiary not set");
        causeBeneficiary.transfer(msg.value - fee);

        internalMint(msg.sender);
    }

    function getCreatorOfToken(uint256 _tokenId)
        public
        view
        returns (address creatorAddress)
    {
        creatorAddress = creators[_tokenId];
    }

    function getVariantData(uint16 _tokenId)
        public
        view
        returns (TokenData[] memory tokenData)
    {
        require(_exists(_tokenId), "Requested token does not exist yet");
        
        uint16 startIndex;
        uint8 variant;

        if(_tokenId < 16) {
            startIndex = 0;
            variant = 1;
        }
        else if(_tokenId < 32) {
            startIndex = 16;
            variant = 2;
        }
        else if(_tokenId < 48) {
            startIndex = 32;
            variant = 3;
        }
        else if(_tokenId < 64) {
            startIndex = 48;
            variant = 4;
        }
        else if(_tokenId < 80) {
            startIndex = 64;
            variant = 5;
        }
        else if(_tokenId < 96) {
            startIndex = 80;
            variant = 6;
        }
        else if(_tokenId < 112) {
            startIndex = 96;
            variant = 7;
        }
        else if(_tokenId < 128) {
            startIndex = 112;
            variant = 8;
        }
        else if(_tokenId < 144) {
            startIndex = 128;
            variant = 9;
        }
        else if(_tokenId < 160) {
            startIndex = 144;
            variant = 10;
        }
        else if(_tokenId < 176) {
            startIndex = 160;
            variant = 11;
        }
        else if(_tokenId < 192) {
            startIndex = 176;
            variant = 12;
        }
        else if(_tokenId < 208) {
            startIndex = 192;
            variant = 13;
        }
        else if(_tokenId < 224) {
            startIndex = 208;
            variant = 14;
        }
        else if(_tokenId < 240) {
            startIndex = 224;
            variant = 15;
        }
        else if(_tokenId < 256) {
            startIndex = 240;
            variant = 16;
        }

        tokenData = new TokenData[]((_tokenId % 16) + 1);

        bytes memory tmpCreator;
        bytes32 tmpTokenHash;
        HslColor memory tmpCreatorColor;
        Triangle[] memory tmpCreatorTriangles;
        Spike[] memory tmpSpikes;

        uint8 counter = 0;
        for(uint16 i = startIndex; i <= _tokenId; i++) {
            (tmpCreator, tmpTokenHash, tmpCreatorColor, tmpCreatorTriangles, tmpSpikes) = getMutationData
            (
                i,
                tuning_numCreatorTrianges[variant - 1], 
                tuning_creatorDrawMultiplier[variant - 1],
                tuning_numSpikes[variant - 1],
                tuning_spikeAngleMultiplier[variant - 1],
                tuning_spikeLengthMultiplier[variant - 1]
            );

            tokenData[counter] = TokenData({
                variant: variant,
                mutationParts: tuning_numCreatorTrianges[variant - 1],
                mutationMultiplier: tuning_creatorDrawMultiplier[variant - 1],
                numSpikes: tuning_numSpikes[variant - 1],
                spikeAngle: tuning_spikeAngleMultiplier[variant - 1],
                spikeLength: tuning_spikeLengthMultiplier[variant - 1],
                creator: tmpCreator,
                tokenHash: tmpTokenHash,
                creatorColor: tmpCreatorColor,
                creatorTriangles: tmpCreatorTriangles,
                spikes: tmpSpikes,
                rarity: rarities[counter]
            });
            counter ++;
        }
    }
}