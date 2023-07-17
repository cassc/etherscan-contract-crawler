// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ChronixGenesis is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;
    uint256 public mintPrice = .042 ether;
    uint256 public maxMint = 7;
    uint256 public maxGenesis = 4200;
    bool public publicMinting;
    bool public reserveClaimed;
    ////////////////////////////////////////////////
    //////////////// Constructor ///////////////////
    ////////////////////////////////////////////////
    constructor(
        string memory _initBaseURI
    ) ERC721A("Chronix Genesis", "CRX") {
        //initial 30 claim
        baseURI = _initBaseURI;
        claimReserve();
    }
    ////////////////////////////////////////////////
    ///////////// External Functions ///////////////
    ////////////////////////////////////////////////
    function mint(uint256 quantity) external payable nonReentrant {
        require(publicMinting,                                          "PUBLIC MINT NOT ACTIVE");
        require(msg.value >= quantity * mintPrice,                      "NOT ENOUGH ETH SENT");
        require(quantity >= 1,                                          "AT LEAST 1 CHRONIX GENESIS NEED TO BE MINTED");
        require(quantity <= maxMint,                                    "LIMITED TO 7 CHRONIX GENESIS PER TX");
        require(totalSupply() + quantity <= maxGenesis,                 "MINTING THIS MANY WOULD EXCEED CHRONIX GENESIS SUPPLY");
        _safeMint(msg.sender, quantity);
    }
    ////////////////////////////////////////////////
    ///////////// Internal Functions ///////////////
    ////////////////////////////////////////////////
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(_baseURI(), tokenId.toString(), '.json'))
        : "";
    }
    ////////////////////////////////////////////////
    /////////////// Owner Functions ////////////////
    ////////////////////////////////////////////////
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    function giveawayMint(address to, uint256 amount) public onlyOwner { 
        require(amount > 0,                                             "CAN NOT SEND 0 CHRONIX GENESIS");
        require(totalSupply() + amount <= maxGenesis,                   "MINTING THIS MANY WOULD EXCEED CHRONIX GENESIS SUPPLY");
        _safeMint(to, amount);
    }
    function claimReserve() internal onlyOwner {
        require(!reserveClaimed,                                        "CHRONIX GENESIS RESERVE HAS ALREADY BEEN CLAIMED");
        _safeMint(msg.sender, 30);
        reserveClaimed = true;
    }
    function flipPublicMinting() public onlyOwner { 
        publicMinting = !publicMinting;
    }
    function withdraw() public onlyOwner {
        (bool hs, ) = payable(0x039eA3371Da302cA3ea9192e3801B1E9baD6e207).call{value: address(this).balance * 48 / 100}("");
        require(hs);
        (bool qs, ) = payable(0x4a40Ef1DA0e73A0df142D06470D7a2cfFC677D2f).call{value: address(this).balance * 20 / 100}(""); 
        require(qs);
        (bool bs, ) = payable(0x36dfA2B19C71F228ED8Aa46de163Cc9a61408527).call{value: address(this).balance * 9 / 100}("");  
        require(bs);
        (bool cs, ) = payable(0x4E0ebdAfACB39Cf80FB0d99DD084af63DEa01A6A).call{value: address(this).balance * 7 / 100}("");   
        require(cs);
        (bool ds, ) = payable(0xda7d9d7E5D27c019DCb6f30cFF83FA9B8aD15949).call{value: address(this).balance * 8 / 100}("");  
        require(ds);
        (bool es, ) = payable(0x3751bDD78C8409b4aE5101B9206F3a7B192123ad).call{value: address(this).balance * 4 / 100}("");  
        require(es);
        (bool fs, ) = payable(0x5c3A1fa85CEBCB46D3a0bEdADe0453dd7aeD606A).call{value: address(this).balance * 2 / 100}("");  
        require(fs);
        (bool gs, ) = payable(0xcad86d42672439cAdC077105Cef1Cb057Dc1EAE8).call{value: address(this).balance * 2 / 100}("");
        require(gs);   
    }
}