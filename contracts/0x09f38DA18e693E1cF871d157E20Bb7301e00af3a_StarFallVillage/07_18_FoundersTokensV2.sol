pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//import "./FoundersTokens.sol";


contract FoundersTokensV2 is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private _owner;

    uint32 private MAX_TOKENS = 3999;

    //uint256 SEED_NONCE = 0;

    uint256 private SALE_PRICE = 0.08 ether;

    uint256 private balance = 0;

    bool private isActive = false;
    
    //bool private REVEAL = false;

    string private baseURI = "https://gtsdfp.s3.amazonaws.com/preview/";

    mapping(uint256 => Trait) private tokenIdTrait;

    //uint arrays
    //uint16[][2] TIERS;

    uint16[][4] RARITIES; // = [[695, 695, 695, 695], [150, 150, 150, 150], [100, 100, 100, 100], [50, 50, 50, 50], [5, 5, 5, 5]];


    struct Trait {
        uint16 artType;
        uint16 materialType;
    }

    string[] private artTypeValues = [
        'Mean Cat',
        'Mouse',
        'Marshal',
        'Hero'
    ];

    string[] private materialTypeValues = [
        'Paper',
        'Bronze',
        'Silver',
        'Gold',
        'Ghostly'
    ];

    mapping(string=>uint16) artMap; //= {'Mean Cat': 0, 'Mouse': 1, 'Marshal': 2, 'Hero': 3];
    
    mapping(string=>uint16) materialMap;

    address v1Contract;

    constructor() ERC721("Ghost Town Founders Pass V2", "GTFP") public {
        _owner = msg.sender;

        //v1Contract = _v1Contract;

        _tokenIds.increment();

        artMap['MeanCat'] = 0;
        artMap['Mouse'] = 1;
        artMap['Marshal'] = 2;
        artMap['Hero'] = 3;

        materialMap['Paper'] = 0;
        materialMap['Bronze'] = 1;
        materialMap['Silver'] = 2;
        materialMap['Gold'] = 3;
        materialMap['Ghostly'] = 4;

        //Declare all the rarity tiers

        //Art
        //TIERS[0] = [5, 5, 5, 5];//TIERS[0] = [1000, 1000, 1000, 1000]; // Mean Cat, MM, FM, Landscape
        //material
        //TIERS[1] = [10, 4, 3, 2, 1]; // paper, bronze, silver, gold, ghostly

        //RARITIES[0] = [695, 695, 695, 695]; //, [150, 150, 150, 150], [100, 100, 100, 100], [50, 50, 50, 50], [5, 5, 5, 5]];
        //RARITIES[1] = [150, 150, 150, 150];
        //RARITIES[2] = [100, 100, 100, 100];
        //RARITIES[3] = [50, 50, 50, 50];
        //RARITIES[4] = [5, 5, 5, 5];

        RARITIES[0] = [695, 150, 100, 50, 5]; // rotating creates a better overall random distribution
        RARITIES[1] = [695, 150, 100, 50, 5];
        RARITIES[2] = [695, 150, 100, 50, 5];
        RARITIES[3] = [695, 150, 100, 50, 5];
        //RARITIES = _RARITIES;
    }


    function tokenURI(uint256 tokenId) 
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        //string memory _tokenURI = _tokenURIs[tokenId];
        //string(abi.encodePacked("ipfs://"));
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function activate(bool active) external onlyOwner {
        isActive = active;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /*function setReveal(bool _reveal) external onlyOwner {
        REVEAL = _reveal;
    }*/

    function changePrice(uint256 _salePrice) external onlyOwner {
        SALE_PRICE = _salePrice;
    }

    function mintV1(uint256 numberOfMints, string[] calldata artList, string[] calldata matList, address[] calldata addrList) public {

        require(msg.sender == _owner, "not owner");

        uint256 newItemId = _tokenIds.current();

        require((newItemId - 1 + numberOfMints <= 247), "v1 limit exceeded");

        //FoundersTokens fpV1 = FoundersTokens(v1Contract);

        for (uint256 i=0; i < numberOfMints; i++) {

            //(string memory artType, string memory materialType) = fpV1.getTraits(newItemId);

            //require(RARITIES[artMap[artType]][materialMap[materialType]], "no rare");

            RARITIES[artMap[artList[i]]][materialMap[matList[i]]] -= 1;

            //tokenIdTrait[newItemId] = createTraits(newItemId, addresses[i]);
            tokenIdTrait[newItemId] = Trait({artType: artMap[artList[i]], materialType: materialMap[matList[i]]});

            _safeMint(addrList[i], newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }

    }

    function createItem(uint256 numberOfTokens) public payable returns (uint256) {
        //require(((block.timestamp >= _startDateTime && block.timestamp < _endDateTime  && !isWhiteListSale) || msg.sender == _owner), "sale not active");
        require(isActive || msg.sender == _owner, "sale not active");
        require(msg.value >= SALE_PRICE || msg.sender == _owner, "not enough money");
        //require(((mintTracker[msg.sender] + numberOfTokens) <= MAXQ || msg.sender == _owner), "ALready minted during sale");

        uint256 newItemId = _tokenIds.current();
        //_setTokenURI(newItemId, string(abi.encodePacked("ipfs://", _hash)));
        require(newItemId > 247, "need to transfer v1");
        require((newItemId - 1 + numberOfTokens) <= MAX_TOKENS, "collection fully minted");

        //mintTracker[msg.sender] = mintTracker[msg.sender] + numberOfTokens;

        for (uint256 i=0; i < numberOfTokens; i++) {
            tokenIdTrait[newItemId] = createTraits(newItemId, msg.sender);

            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }


        //payable(address(this)).transfer(SALE_PRICE);

        return newItemId;
    }

    function weightedRarityGenerator(uint16 pseudoRandomNumber) private returns (uint8, uint8) {
        uint16 lowerBound = 0;

        for (uint8 i = 0; i < RARITIES.length; i++) {
            for (uint8 j = 0; j < RARITIES[i].length; j++) {
                uint16 weight = RARITIES[i][j];

                if (pseudoRandomNumber >= lowerBound && pseudoRandomNumber < lowerBound + weight) {
                    RARITIES[i][j] -= 1;
                    return (i, j);
                }

                lowerBound = lowerBound + weight;
            }
        }

        revert();
    }

    function createTraits(uint256 tokenId, address _msgSender) private returns (Trait memory) {
        uint256 pseudoRandomBase = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _msgSender, tokenId)));

        uint256 tokensMinted = itemsMinted();
        (uint8 a, uint8 m) = weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 1) % (1 + MAX_TOKENS - tokensMinted)));
        return
            Trait({
                artType: a,
                materialType: m
            });
    }

    function withdraw() onlyOwner public {
        require(address(this).balance > 0, "0 balance");
        payable(_owner).transfer(address(this).balance);
    }

    function getTraits(uint256 tokenId) public view returns (string memory artType, string memory materialType) {
        //require(REVEAL, "reveal not set yet");
        Trait memory trait = tokenIdTrait[tokenId];
        artType = artTypeValues[trait.artType];
        materialType = materialTypeValues[trait.materialType];
    }


    function itemsMinted() public view returns(uint) {
        return _tokenIds.current() - 1;
    }

    function ownerBalance() public view returns(uint256) {
        return address(this).balance;
    }

}