// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract pdtc is ERC721A, Ownable {


    uint256 MAX_SUPPLY = 1111;
    uint256 MAX_MINTS = 10;
    mapping(address => uint8) private _whitelist;
    uint256 public mintRate = 0 ether;
    string public baseURI = "ipfs://QmefMcsc4qJcn59mBGaZd4yFoAJWBqHEweKExCaCTvv68P/";
    constructor() ERC721A("Putin Digital Trading Cards", "PDTCG") {}

    function mint(uint256 quantity) external payable {
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        _safeMint(msg.sender, quantity);
    }


    function mintTo(uint256 quantity,address to) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");   
        _safeMint(to, quantity);
    }  


    function burn(uint256 tokenId)  public onlyOwner {
        _burn(tokenId, false);
    }


    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
   
    function setBaseURI(string calldata setURI) external onlyOwner() {
        baseURI= setURI;
    }
 


    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }


    function set_MAX_MINTS(uint256 _amount) public onlyOwner {
        MAX_MINTS = _amount;
    }

    function set_MAX_SUPPLY(uint256 _amount) public onlyOwner {
        MAX_SUPPLY = _amount;
    }
}