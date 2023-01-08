// SPDX-License-Identifier: MIT

pragma solidity > 0.8.9 < 0.9.0;

import "./ERC721A.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/Strings.sol";


contract myContract is ReentrancyGuard, ERC721A{

    
    string constant _tokenName = "testContract";
    string constant _tokenSymbol = "TC";
    string public baseURI = "";
    address immutable owner;

    constructor()ERC721A(_tokenName, _tokenSymbol) {
        owner = msg.sender;
    }


    bool public paused = false;


    modifier onlyOwner(){
        if (msg.sender != owner) revert();
        _;
    }

    function mint(uint8 _mintAmount) public {
        if(paused) revert();
        _safeMint(msg.sender, _mintAmount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "The token you are querying is inexistent");
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), ".json")) : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setPaused (bool _paused) public onlyOwner {
        paused = _paused;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner).call{value: address(this).balance}('');
        require(os);
    }

}