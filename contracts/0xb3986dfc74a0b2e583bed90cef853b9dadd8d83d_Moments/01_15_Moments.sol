// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./base64.sol";

contract Moments is ERC721Enumerable, Ownable {

    using Strings for uint256;

    uint256 private _currentTokenId;
    uint256 private _priceInWei;
    mapping(uint256 => uint32) private _mintedTokenId2DateMap;
    mapping(uint32 => uint256[]) private _mintedDate2TokenIdsMap;
    bytes32 private _merkleRoot;
    mapping(address => bool) private _claimMap;

    constructor() ERC721("Moments N", "MOMENTS") {
        _currentTokenId = 1;
        _priceInWei = 30000000000000000;    //0.03eth
    }

    function priceInWei() public view returns (uint256) {
        return _priceInWei;
    }

    function merkleRoot() public view returns (bytes32) {
        return _merkleRoot;
    }

    function isClaimed(address account) external view returns (bool) {
        return _claimMap[account];
    }

    function getMintedTokenIds(uint32 date) public view returns (uint[] memory){
        return _mintedDate2TokenIdsMap[date];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Moments: URI query for nonexistent token");

        string memory svg1 = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800"><defs><linearGradient id="b"><stop offset=".2" stop-color="#feac02"/><stop offset=".8" stop-color="#ff35b2"/></linearGradient><filter id="a"><feGaussianBlur stdDeviation="10"/></filter></defs><path fill="#01b9ff" d="M0 0h800v800H0z"/><g filter="url(#a)" fill="none"><path d="M0 0h800v800H0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="100" stroke="#000" d="m160 710 150-600 200 600 150-600"/></g><path stroke-linecap="round" stroke-linejoin="round" stroke-width="100" fill="none" stroke="url(#b)" d="m150 700 150-600 200 600 150-600"/><text x="50%" y="50%" stroke="#000" fill="#fff" font-size="100" font-weight="700" text-anchor="middle" dominant-baseline="central">';
        string memory date = getDateString(_mintedTokenId2DateMap[tokenId]);
        string memory svg2 = '</text></svg>';

        string memory image = string(abi.encodePacked(svg1,date,svg2));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Moments ', date, '", "description": "The minted date is embedded in the on-chain image.","attributes": [{"trait_type":"date","value":"' , date , '"}],"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}'))));

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

   function getDate(uint _timestamp) internal pure returns (uint32) {
        int __days = int(_timestamp/86400);
        int L = __days + 68569 + 2440588;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        return uint32(uint256(_year * 10000 + _month * 100 + _day));
    }

    function getDateString(uint32 _date) internal pure returns (string memory) {
        uint _year = uint(_date) / 10000;
        uint _month = (uint(_date) % 10000) / 100;
        uint _day = uint(_date) % 100;

        string memory separate1 = "/";
        if(_month < 10)separate1 = "/0";
        string memory separate2 = "/";
        if(_day < 10)separate2 = "/0";

        return string(abi.encodePacked(Strings.toString(_year),separate1,Strings.toString(_month),separate2,Strings.toString(_day)));
    }

    //******************************
    // public functions
    //******************************
    function mint(int256 timezoneOffset) external payable {
        require(msg.value == _priceInWei, "Moments: Invalid price");
        require( -23 <= timezoneOffset && timezoneOffset <= 23, "Moments: Invalid timezoneOffset");
         uint256 tokenId = _currentTokenId++;
         uint32 date = getDate(uint256(int256(block.timestamp) + timezoneOffset * int256(3600)));
        _mintedTokenId2DateMap[tokenId] = date;
        _mintedDate2TokenIdsMap[date].push(tokenId);
        _safeMint(msg.sender, tokenId);
    }

    function claim(int256 timezoneOffset, bytes32[] calldata merkleProof) external payable {
        require(_merkleRoot != "", "Moments: No merkle root");
        require(!_claimMap[msg.sender], "Moments: Account minted token already");
        require(MerkleProof.verify(merkleProof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Moments: Can not verify");
        require( -23 <= timezoneOffset && timezoneOffset <= 23, "Moments: Invalid timezoneOffset");
        _claimMap[msg.sender] = true;
         uint256 tokenId = _currentTokenId++;
         uint32 date = getDate(uint256(int256(block.timestamp) + timezoneOffset * int256(3600)));
        _mintedTokenId2DateMap[tokenId] = date;
        _mintedDate2TokenIdsMap[date].push(tokenId);
        _safeMint(msg.sender, tokenId);
    }

    //******************************
    // admin functions
    //******************************
    function setMerkleRoot(bytes32 __merkleRoot) external onlyOwner {
        _merkleRoot = __merkleRoot;
    }

    function setPrice(uint256 __priceInWei) external onlyOwner {
        _priceInWei = __priceInWei;
    }

    function withdraw(address payable to, uint256 amountInWei) external onlyOwner {
        Address.sendValue(to, amountInWei);
    }

    receive() external payable {}
}