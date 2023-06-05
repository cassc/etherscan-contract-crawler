// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Rooshocks is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    mapping(uint => uint) public minted;
    mapping(uint => uint) public _resMinted;

    uint[] public MAX_SUPPLY = [30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,5,5,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,5,20,20,5,10,5,15,20,20,20,10,10,10,20,20,20,10,10,20,10,10,10,10,20]; 
    uint[] public _reserved = [5,3,3,3,3,2,3,2,3,3,3,2,2,2,2,3,2,3,1,2,3,2,3,2,2,2,2,2,2,2,2,2,2,2,2,2,1,2,2,1,1,1,5,1,1,1,1,2,2,1,1,1,1,1,1,2,1,1,1,2];
    uint[] private _buffer = [0,30,60,90,120,150,180,210,240,270,300,330,360,390,420,450,480,510,540,545,550,570,590,610,630,650,670,690,710,730,750,770,790,810,830,850,870,875,895,915,920,930,935,950,970,990,1010,1020,1030,1040,1060,1080,1100,1110,1120,1140,1150,1160,1170,1180];

    string private baseURI;

    bool public _isSaleActive = false;

    constructor() ERC721("Rooshocks", "ROOS") {}

    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function setSaleState(bool newState) public onlyOwner {
        _isSaleActive = newState;
    }

    function mint(
        uint _type
    ) external payable nonReentrant{
        require(_isSaleActive, "sale inactive");
        require(msg.value == getPrice(_type), "Insufficient funds");
        require(minted[_type] + 1 <= MAX_SUPPLY[_type] - _reserved[_type], "Not enough tokens left");
        require(msg.sender == tx.origin, "Interaction not allowed");

        ++minted[_type];

        _tokenIdCounter.increment();

        uint _tokenID = _buffer[_type] + minted[_type] + _resMinted[_type];
        _safeMint(msg.sender, _tokenID);
    }

    function getPrice(uint _type) public pure returns(uint){
        if (_type < 20) {
            return 80000000000000000; 
        } else if (_type < 40) {
            return 120000000000000000;
        } else if (_type == 40) {
            return 240000000000000000;
        } else if (_type == 41) {
            return 330000000000000000;
        } else if (_type < 52) {
            return 120000000000000000;
        } else if (_type == 52) {
            return 240000000000000000;
        } else {
            return 120000000000000000;
        }
    }

    function claim(
        address _addr,
        uint _type
    ) external onlyOwner{
        require(_resMinted[_type] + 1 <= _reserved[_type], "Not enough tokens left");

        ++_resMinted[_type];

        _tokenIdCounter.increment();

        uint _tokenID = _buffer[_type] + minted[_type] + _resMinted[_type];
        _safeMint(_addr, _tokenID);
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      return string(abi.encodePacked(baseURI, uint2str(tokenId), ".json"));
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

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}