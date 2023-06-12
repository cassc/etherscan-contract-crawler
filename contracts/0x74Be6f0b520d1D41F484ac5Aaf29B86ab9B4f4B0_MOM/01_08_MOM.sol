// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//        __               __          __    _ __          //
//       / /_  ____ ______/ /_  ____  / /_  (_/ /______    //
//      / __ \/ __ `/ ___/ __ \/ __ \/ __ \/ / __/ ___/    //
//     / /_/ / /_/ (__  / / / / /_/ / /_/ / / /_(__  )     //
//    /_____/\____/____/_/ /_/\____/_____/_/\__/____/      //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract MOM is ERC721A, Ownable {
    uint256 MAX_MINTS = 105;
    uint256 MAX_SUPPLY = 105;
    uint256 public mintRate = 0.0 ether;
    
    string public baseURI = "ipfs://Qmczi1WF4RePSbzqRJbQTnP1szdLzMjFGHVDKE9XVZiwTA/";

    constructor() ERC721A("Memories of Mobility by bashobits", "MEM") {}

    function mint(uint256 quantity) external payable onlyOwner(){
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner() {
    baseURI = _uri;
  }

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');   

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"))
        : '';
  }


}