//SPDX-License-Identifier: MIT

/**
 * BLURPEEEEEEES
*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Blurpees is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
	bool public blurpeesSale = false;
    
    Counters.Counter private _tokenIds;
    
    uint public constant MAX_BLURPEES = 8101;
    uint public constant RESERVE_BLURPEES = 25;
    uint public constant PRICE_PER_BLURP = 0.001 ether;
    uint public constant MAX_PER_MINT = 5;
    
    string public baseTokenURI;
    
    constructor(string memory baseURI) ERC721("Blurpees", "BLURP") {
        setBaseURI(baseURI);
    }
    
    function reserveBLURPEES() public onlyOwner {
        uint totalMinted = _tokenIds.current();

        require(totalMinted.add(RESERVE_BLURPEES) < MAX_BLURPEES, "Not enough BLURPEES left to reserve!");

        for (uint i = 0; i < RESERVE_BLURPEES; i++) {
            _mintSingleToken();
        }
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
	
	function setSaleState(bool newState) public onlyOwner {
        blurpeesSale = newState;
    }
    
    function mintBLURPEES(uint _count) public payable {
        uint totalMinted = _tokenIds.current();

		require(blurpeesSale, "BLURP sale must be active to mint BLURPEES");
        require(totalMinted.add(_count) <= MAX_BLURPEES, "Not enough BLURPEES left!");
        require(_count >0 && _count <= MAX_PER_MINT, "Cannot mint specified number of BLURPEES.");
        require(msg.value >= PRICE_PER_BLURP.mul(_count), "Not enough ether to purchase BLURPEES.");

        for (uint i = 0; i < _count; i++) {
            _mintSingleToken();
        }
    }
    
    function _mintSingleToken() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }
    
    function tokensOfOwner(address _owner) external view returns (uint[] memory) {

        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);

        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }
    
}