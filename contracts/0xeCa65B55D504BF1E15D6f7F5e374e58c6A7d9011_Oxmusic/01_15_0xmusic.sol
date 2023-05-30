// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "ERC721Enumerable.sol";
import "Strings.sol";
import "Counters.sol";
import "ReentrancyGuard.sol";


contract Oxmusic is ERC721, Ownable, ReentrancyGuard {

    uint256 private constant fullMintPrice = 0.1 ether;
    uint256 private constant wlPrice = 0.07 ether;
    uint256 private constant daoPrice = 0.05 ether;
    uint256 private randNonce = 0;
    uint256 private MAX_SUPPLY;
    bool public saleIsActive = false;
    bool public wlSaleIsActive = false;
    Counters.Counter public counter;

    string private  baseURLAnimation;
    string private baseURLImage;
    string private blurredImage;
    bool public revealActive = false;

    struct Trait {
        uint tokenId;
        uint len;
        uint id;
        uint32 dj;
        uint staticSongsAllowed;
    }

    struct TokenUrIDetails {
       string orientation;
       string name;
       string records;
       string cycleLength;
       string length;
       string djStr;
       string tokenId;
       string description;
       string animationUrl;
       string imgUrl;
       string hexColor;
       string entropy;
    }

    struct RandDetails{
        uint rDJ;
        uint rId;
        uint rLen;
        uint rRec;
    }

  //  event MintDetails(uint randdj, uint len, uint records, address _from, address _to, uint _amount, uint tokenId);
    mapping(uint32 => string) private djToNameIndex;
    mapping(uint32 => string) private djToOrientation;
    mapping(uint32 => string) private djToEntropy;
    mapping(uint => string) private bgIdToHex;
    mapping(address => uint32) public whiteList;
    mapping(address => uint32) public prefList;
    mapping(address => uint32) public numberMinted;
    mapping(uint => string) public scriptIdxToTx; 

    mapping(uint256 => Trait) private tokenIdToTrait;
    mapping(address => uint32) public compMints;

    constructor(string memory baseURLAnimationInput, string memory baseURLImageInput, string memory blurred, uint maxSupply) 
    ERC721("0xmusic", "music")
    {
        MAX_SUPPLY = maxSupply;
        baseURLAnimation = baseURLAnimationInput;
        baseURLImage = baseURLImageInput;
        blurredImage = blurred;

        djToNameIndex[0] = "420";
        djToNameIndex[1] = "Athena";
        djToNameIndex[2] = "Dimend";
        djToNameIndex[3] = "Drip";
        djToNameIndex[4] = "Syn City";
        djToNameIndex[5] = "Handel";
        djToNameIndex[6] = "Bach";
        djToNameIndex[7] = "Serena";

        djToOrientation[0] = "southpaw";
        djToOrientation[1] = "southpaw";
        djToOrientation[2] = "dexter";
        djToOrientation[3] = "dexter";
        djToOrientation[4] = "dexter";
        djToOrientation[5] = "vanward";
        djToOrientation[6] = "vanward";
        djToOrientation[7] = "southpaw";
        bgIdToHex[3] = "2B2727";
        bgIdToHex[6] = "192F20";
        bgIdToHex[27] = "2B192F";

        djToEntropy[0] = "high";
        djToEntropy[1] = "high";
        djToEntropy[2] = "medium";
        djToEntropy[3] = "low";
        djToEntropy[4] = "high";
        djToEntropy[5] = "low";
        djToEntropy[6] = "low";
        djToEntropy[7] = "medium";

    }

    function setSaleIsActive(bool isActive) external onlyOwner {
        saleIsActive = isActive;
    }

    function setIsRevealActive(bool isActive) external onlyOwner {
        revealActive = isActive;
    }

    function setWhiteListSaleIsActive(bool isActive) external onlyOwner {
        wlSaleIsActive = isActive;
    }

    function setBaseURLAnimation(string memory baseURI) external onlyOwner {
        baseURLAnimation = baseURI;
    }

    function setBaseURLImage(string memory baseURI) external onlyOwner {
        baseURLImage = baseURI;
    }

    function addToWL(address input, uint32 count) external onlyOwner {
        whiteList[input] = count;
    }

    function addToDao(address input) external onlyOwner {
        prefList[input] = 2;
    }

    function addToCompMint(address input, uint32 count) external onlyOwner {
        compMints[input] = count;
    }

    function mintWL() external payable {
        require(wlSaleIsActive, "Sale must be active");
        require(whiteList[msg.sender] > 0, "You are not elligible");
        require(wlPrice <= msg.value, "Ether value sent is not correct");
        whiteList[msg.sender] -= 1;
        _mintInternal();
    }

    function mintDao() external payable {
        require(wlSaleIsActive, "Sale must be active");
        require(prefList[msg.sender] > 0, "You are not elligible");
        require(daoPrice <= msg.value, "Ether value sent is not correct");

        prefList[msg.sender] -= 1;
        _mintInternal();
    }

    function mintArtist() external onlyOwner {
        _mintInternal();
    }

    function mintComp() external {
        require(wlSaleIsActive, "Sale must be active");
        require(compMints[msg.sender] > 0, "You are not elligible");
        compMints[msg.sender] -= 1;
        _mintInternal();
    }

    function mint() external payable {
        require(saleIsActive, "Sale must be active to mint");
        require(fullMintPrice <= msg.value, "Ether value sent is not correct");
        require(numberMinted[msg.sender] < 8, "Exceeded number minted");

        _mintInternal();
    }

    function _mintInternal() private  {
        require(Counters.current(counter) < MAX_SUPPLY, "Purchase would exceed max supply");
        uint mintIndex = Counters.current(counter);
        RandDetails memory details = RandDetails(uint(random(100)),random(460) + 1,uint(random(10)),uint(random(100)));
        uint32 randDJIdx;
        if(details.rDJ > 0 && details.rDJ < 18){
            randDJIdx = 4;
        } else if(details.rDJ < 32){
            randDJIdx = 3;
        } else if(details.rDJ < 43){
            randDJIdx = 6;
        } else if(details.rDJ < 48){
            randDJIdx = 5;
        } else if(details.rDJ < 59){
            randDJIdx = 7;
        } else if(details.rDJ < 73){
            randDJIdx = 1;
        } else if(details.rDJ < 86){
            randDJIdx = 0;
        } else {
            randDJIdx = 2;
        }
        uint id = details.rId <= 200 ? details.rId/2 : details.rId - 100; 
        uint32 len = details.rLen < 5 ? 2 : details.rLen < 9 ? 3 : 4;
        uint32 records = details.rRec < 70 ? 3 : details.rRec < 96 ? 6 : 27;

        Trait memory t = Trait(mintIndex, len, id, randDJIdx, records);

        tokenIdToTrait[mintIndex] = t;
        numberMinted[msg.sender] = numberMinted[msg.sender] + 1;

      //  emit MintDetails(randDJIdx, len, records, owner(), msg.sender, msg.value, mintIndex);

        Counters.increment(counter);

        _safeMint(msg.sender, mintIndex);
    }

    function getImageDetails(uint256 tokenId) external view returns(uint32,uint, uint, uint) {
        Trait memory t = tokenIdToTrait[tokenId];
        return (t.dj, t.id, t.len, t.staticSongsAllowed);
    }

    function getImageURL(uint256 tokenId) public view returns (string memory){
        Trait memory t = tokenIdToTrait[tokenId];
        if (revealActive) {
            return string(abi.encodePacked(baseURLImage,Strings.toString(t.dj),"/",Strings.toString(t.id),"/", Strings.toString(t.staticSongsAllowed) ,'/img.png"'));
        } else {
            return string(abi.encodePacked(blurredImage, '"'));
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        Trait memory t = tokenIdToTrait[tokenId];

        TokenUrIDetails memory details = TokenUrIDetails(
            djToOrientation[t.dj],
            djToNameIndex[t.dj],
            Strings.toString(t.staticSongsAllowed),
            t.len == 2 ? "short" : t.len == 3 ? "medium" : "long",
            Strings.toString(t.len),
            Strings.toString(t.dj),
            Strings.toString(t.tokenId),
            '"description": "Your generative DJ. Hiting play destroys the previous song and creates a brand new song in real-time"',
            revealActive ? string(abi.encodePacked(baseURLAnimation,Strings.toString(t.dj),"&id=",
                Strings.toString(t.id),"&len=",Strings.toString(t.len), "&bg=",Strings.toString(t.staticSongsAllowed))): "",
            getImageURL(tokenId),
            bgIdToHex[t.staticSongsAllowed],
            djToEntropy[t.dj]
            );

        string memory djTrait = string(abi.encodePacked('{"trait_type": "0xDJ", "value": "', details.name, '"},{"trait_type": "Orientation", "value": "', details.orientation, '"} ,'));
        string memory cycleLengthTrait = string(abi.encodePacked('{"trait_type": "Cycle length", "value": "', details.cycleLength, '"} ,'));
        string memory idTrait = string(abi.encodePacked('{"trait_type": "HSL Palette", "value": "', Strings.toString(t.id), '"} ,'));
        string memory recordsTrait = string(abi.encodePacked('{"trait_type": "Records", "value": "', details.records, '"}]}'));
        string memory entropyTrait = string(abi.encodePacked('{"trait_type": "Entropy", "value": "', details.entropy, '"} ,'));
        string memory nameT = string(abi.encodePacked('{"name": "',  revealActive ? details.name : "0xDJ", " #", details.tokenId, '",'));
        string memory attributes = revealActive ? string(abi.encodePacked('"attributes": [', 
                djTrait, cycleLengthTrait, idTrait, entropyTrait, recordsTrait)) : '"attributes": []}';

        return string(abi.encodePacked('data:application/json,', nameT, details.description, ',"image":  "', 
            details.imgUrl, ',"animation_url": "', details.animationUrl, '","external_url": "https://www.0xmusic.com", "background_color": "', details.hexColor, '" ,', 
                attributes));
        
    }

    function getMasterFromTokenId(uint256 tokenId) external view returns (string memory) {
        Trait memory t = tokenIdToTrait[tokenId];
        return string(abi.encodePacked(djToNameIndex[t.dj],' ',Strings.toString(tokenId)));

    }

    function random(uint upperLimit) private returns (uint) {
        randNonce++; 
        return (uint(keccak256(abi.encodePacked(block.difficulty, msg.sender, block.timestamp, randNonce)))) % upperLimit;
    } 

    function withdrawEth() external onlyOwner nonReentrant {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function setScriptAtIndex(uint idx, string memory txId) external onlyOwner {
        scriptIdxToTx[idx] = txId;
    }
 
}