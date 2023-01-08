// SPDX-License-Identifier: MIT

pragma solidity > 0.8.9 < 0.9.0;

import "./ERC721A.sol";
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

contract testingContract is ReentrancyGuard, ERC721A{


    constructor()ERC721A("_tokenName", "_tokenSymbol") {
        owner = msg.sender;
    }


    // blobal variables
    address immutable owner;

    bool paused = true;


    // modifier
    modifier onlyOwner (){
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }


    function setPaused(bool _paused) public onlyOwner{
        paused = _paused;
    }
    // payable functions

    function Mint(uint8 _mintAmount) public payable {
        require(!paused, "Contract paused");
        _safeMint(msg.sender, _mintAmount);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "The token you are querying is inexistent");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), ".json")) : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    // whithdraw function

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner).call{value: address(this).balance}('');
        require(os);
    }

}