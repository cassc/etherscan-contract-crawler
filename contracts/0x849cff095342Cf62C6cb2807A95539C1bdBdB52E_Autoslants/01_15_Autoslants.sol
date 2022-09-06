// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Autoslants is ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  mapping(uint256 => address) internal requestIdToSender;
  mapping(uint256 => uint256) internal requestIdToTokenId;
  mapping(uint256 => uint256) internal tokenIdToRandomNumber;
  mapping(address => uint256) private mintCountMap;
  mapping(address => uint256) private allowedMintCountMap;
  uint256 public constant MINT_LIMIT_PER_WALLET = 2;
  uint64 public maxSupply = 257;
  uint256 public maxMintAmount = 1;
  uint256 public _mintAmount = 1;
  uint256 public cost = 10000000000000000;

  event requestedRandomSVG(uint256 indexed requestId, uint indexed tokenId);
  event CreatedRSVGNFT(uint indexed tokenID, string tokenURI);
  event CreatedUnfinishedRandomSVG(uint indexed, uint randomWords);

  uint256 public tokenCounter;
  uint256 public maxNumberofSlants;
  uint24 [][33] colors;
  address s_owner;
  uint256 public nftChanceValue;
  constructor() 
    ERC721("/Autoslants/","AUSLT") 
    {
    tokenCounter = 1;
    s_owner = msg.sender;
    maxNumberofSlants= 150;
        colors[0] = [16777215, 16777215, 16777215, 16777215, 1118481];
        colors[1] = [1118481,1118481,1118481,1118481,16777215];
        colors[2] = [15907775, 7308223, 15886923, 14261589, 15331570];
        colors[3] = [15879018, 14277081, 15921906, 15878473, 1118481];
        colors[4] = [1186634, 1053253, 1057411, 5201548, 9674431];
        colors[5] = [15892170, 6260953, 3384977, 15900421, 15900825];
        colors[6] = [2500134, 9204592, 12548763, 7541814, 15914453];
        colors[7] = [14277081, 10921638, 7566195, 4210752, 1118481];
        colors[8] = [1340186, 4315480, 3587914, 14859762, 1517086];
        colors[9] = [14269344, 12553327, 4202774, 14255731, 2497813];
        colors[10] = [12549806, 9985727, 7684031, 15903056, 6631641];
        colors[11] = [2490625, 15861511, 12518918, 7537411, 15921906];
        colors[12] = [15892855, 1118481, 1118481, 15892855, 14229038];
        colors[13] = [14233867, 15901196, 12529831, 8371999, 15911948];
        colors[14] = [9189168, 10918022, 13628076, 9558428, 6530707];
        colors[15] = [5197196, 6249894, 9408191, 3031385, 2500134];
        colors[16] = [15921906, 15872005, 15898743, 15887677, 15877125];
        colors[17] = [15893953, 15877284, 15875473, 14145497, 2434342];
        colors[18] = [1723097, 8762610, 15902749, 15907084, 1595609];
        colors[19] = [15903308, 15903308, 15903308, 15903308, 1054752];
        colors[20] = [1054752, 1054752, 1054752, 1054752, 15903308];
        colors[21] = [15559270, 15559270, 15559270, 15559270, 1061024];
        colors[22] = [10089539, 10089539, 10089539, 10089539, 15484059];
        colors[23] = [1176541, 1119322, 1054323, 15861218, 1186482];
        colors[24] = [14245168, 15906565, 6381247, 6982687, 15868505];
        colors[25] = [2500134, 12535579, 7548180, 1118481, 15918549];
        colors[26] = [13219570, 2626137, 4201612, 5115353, 6433753];
        colors[27] = [14273293, 3922258, 15880331, 4015858, 3554495];
        colors[28] = [4271961, 10457023, 12433625, 15913881, 15921906];
        colors[29] = [11208178, 5610457, 7173362, 8194034, 7992050];
        colors[30] = [5855318, 9210760, 12566461, 1118481, 15921387];
        colors[31] = [14389276, 15262051, 8373724, 4753608, 1521273];
        colors[32] = [8045035, 16702900, 16684433, 11754900, 3161719];
  }
  function allowedMintCount(address minter) public view returns (uint256) {
    return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
  }
   function remainFreeMint() public view returns (uint256) {
    return MINT_LIMIT_PER_WALLET - mintCountMap[msg.sender];
  }
  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }
  function mint() public payable returns (uint256 s_requestId){
    uint256 supply = totalSupply();
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    require(tokenCounter + _mintAmount <= maxSupply);
    require(saleIsActive, "Sale not active");
    if (allowedMintCount(msg.sender) >= 1) {
      updateMintCount(msg.sender, 1);
    } else {
      require(msg.value >= cost * _mintAmount);
    }

uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)))  % 2000;
  
    nftChanceValue = randomNumber*tokenCounter+1;
    requestIdToSender[nftChanceValue] = msg.sender;
    uint tokenId = tokenCounter;
    s_requestId = randomNumber*tokenId+1;
    _safeMint(msg.sender, tokenId);
    tokenIdToRandomNumber[tokenId] = nftChanceValue;
    emit CreatedUnfinishedRandomSVG(tokenId, nftChanceValue);
    tokenCounter = tokenCounter + 1 ;
    emit requestedRandomSVG(s_requestId, tokenId);
    
  }

  function tokenURI(uint tokenId) public view override returns(string memory){
    string memory _tokenURI = "Token with that ID does not exist.";
    if (_exists(tokenId)){
      require(nftChanceValue != 0, "Need to Random");
      string memory svg = generateSVG(tokenIdToRandomNumber[tokenId]);
      string memory imageURI = svgToImageURI(svg);
      _tokenURI = formatTokenURI(tokenId, imageURI);
    }
    return _tokenURI;
  }

    function generateSVG (uint256 _randomNumber) public view returns (string memory finalSvg) {
    uint256 numberOfPaths = (_randomNumber % maxNumberofSlants) + 15;
    uint256 seed = _randomNumber;
    uint256 c_set1 = uint256(keccak256(abi.encode(_randomNumber,33))) % 33;
        finalSvg = string(abi.encodePacked("<svg xmlns='http://www.w3.org/2000/svg' height='1000' width='1000'> <title>""/Autoslants/""</title><desc> Your Seed: ",uint2str(seed)," </desc>"));
        finalSvg = string(abi.encodePacked(finalSvg, "<rect width=\"100%\" height=\"100%\" fill=\"#",uint2hexstr(colors[c_set1][4]),"\" />"));
        for(uint i = 1; i < numberOfPaths; i++) {
        uint256 c_set = uint256(keccak256(abi.encode(_randomNumber,33))) % 33;
        uint256 parameterOne = uint256(keccak256(abi.encode(_randomNumber, 800*2*i))) % 800;
        uint256 widths = uint256(keccak256(abi.encode(_randomNumber, 11*i))) % 11;
        uint256 c_numb = uint256(keccak256(abi.encode(_randomNumber, 4*i))) % 4;
        uint256 parameterTwo = uint256(keccak256(abi.encode(_randomNumber, 800*5*i))) %800;
        finalSvg = string(abi.encodePacked(finalSvg, "<polyline points='",uint2str(parameterOne+100)," ",uint2str(parameterTwo+100),", ",uint2str(parameterTwo+100)," ",uint2str(parameterOne+100),"' style=\"fill:none;stroke:#",uint2hexstr(colors[c_set][c_numb]),";stroke-linecap:round;stroke-width:",uint2str(widths + 1),"\" />"));
        }
        finalSvg = string(abi.encodePacked(finalSvg, "</svg>"));
    }
  function svgToImageURI(string memory svg) public pure returns(string memory){
    string memory baseURL = "data:image/svg+xml;base64,";
    string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
    return string(abi.encodePacked(baseURL, svgBase64Encoded));
  }
  
   function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
  bool public saleIsActive = true;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }
   function uint2hexstr(uint i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (i != 0) {
            uint curr = (i & mask);
            bstr[--k] = curr > 9 ?
                bytes1(uint8(55 + curr)) :
                bytes1(uint8(48 + curr));
            i = i >> 4;
        }
        return string(bstr);
    }

  function formatTokenURI(uint256 id,string memory imageURI) public view returns(string memory){
    string memory baseURL = "data:application/json;base64,";
    string memory desc = string(abi.encodePacked('', uint2str(id)));
    uint256 numberOfSlants_ = (tokenIdToRandomNumber[id] % maxNumberofSlants);
    uint256 c_set_ = uint256(keccak256(abi.encode(tokenIdToRandomNumber[id],33))) % 33;
    string memory numberOfSlants_desc = string(abi.encodePacked('', uint2str(numberOfSlants_ + 14)));
    string memory cset_desc = string(abi.encodePacked('', uint2str(c_set_)));
    
    return string(
      abi.encodePacked(
        baseURL,
        Base64.encode(
          bytes(
            abi.encodePacked(
              '{"name": "/Autoslants/ #',desc,'",  ', 
              '"description": "/Autoslants/ is fully on-chain generative art NFTs and store on Ethereum Blockchain forever. A user submit transactions and contract randomly generate each mint via the on-chain code. Total supply is 256 and 33 different color sets are defined in the contract. Each of them contains between 15 and 165 random slants lines.", ',
              '"attributes":[{"trait_type": "Number of Slants", "value": "',numberOfSlants_desc,'"},{"trait_type": "Color Set", "value": "',cset_desc,'"}]',
              ',',
              '"image":"',
              imageURI,
              '"}'
            )
          )
        )
      )
    );
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
  }
function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

}