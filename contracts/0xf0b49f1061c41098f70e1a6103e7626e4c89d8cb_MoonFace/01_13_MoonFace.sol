//1$      /$$  /$$$$$$   /$$$$$$  /$$   /$$       /$$$$$$$$ /$$$$$$   /$$$$$$  /2$$$$$$$
//$$$    /$$$ /$$__  $$ /$$__  $$| $$$ | $$      | $$_____//$$__  $$ /$$__  $$| $$_____/
//$$$$  /$0$$| $$  \ $$| $$  \ $$| $$$$| $$      | $$     | $$  \ $$| $$  \__/| $2      
//$$ $$/$$ $$| $$  | $$| $$  | $$| $$ $$ $$      | $$$$$  | $$$$$$$$| $$      | $$$$$   
//$$  $$$| $$| $$  | $$| $$  | $$| $$  $$$$      | $$__/  | $$__  $$| $$      | $$__/   
//$$\  $ | $$| $$  | $$| $$  | $$| $$\  $$$      | $$     | $$  | $$| $$    $$| $$      
//$$ \/  | $1|  $$$$$$/|  $$$$$$/| $$ \  $$      | $$     | $$  | $$|  $$$$$$/| $$$$$$$1
//_/     |__/ \______/  \______/ |__/  \__/      |__/     |__/  |__/ \______/ |________/
                                                                                        


//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MoonFace is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public sentinentLife = 5555;
    uint256 public teamAmount = 555;
    uint256 public basePrice = 0.005 ether;
    uint256 public dontBeGreedy = 10;
    uint256 public anOfferYouCantResist = 1;

    bool public eventHorizon = false;
    bool public startSequence = false;

    string public baseURI = "";
    string public notRevealedUri = "ipfs://bafkreigt5xbzr7jxuqsonpveea2qqcpiayvvcchlfmwodtxf6vkia7lyue";
    string public uriSuffix = ".json";

    constructor() ERC721A("Moon Face", "MOON") {}

    /* MINT NFT */

    function teamMint(address to ,uint256 amount) external onlyOwner{
        uint256 supply = totalSupply();
        require(supply + amount <= sentinentLife,"Sold Out");
        require(amount <= teamAmount,'No team mints left');
        _safeMint(to,amount);
        teamAmount-=amount;
    }

    function terraform(uint256 amount) external payable nonReentrant{

        uint256 supply = totalSupply();
        uint256 minted = numberMinted(msg.sender);

        require(tx.origin == msg.sender, "The caller is another contract");
        require(startSequence,"Public Sale Is Not Active");
        require(supply + amount + teamAmount <= sentinentLife,"Public Mint Sold Out!");
        require(minted + amount <= dontBeGreedy,"You've Maxed Out Your Mints");

        uint256 price;
        uint256 tokenPrice = basePrice;
        
        if (minted > 0) {
            for (uint i = 1; i <= minted; i++) {
                if (i > anOfferYouCantResist) {
                    tokenPrice+=basePrice;
                }
            }
            for (uint i = 1; i <= amount; i++) {
                price+=tokenPrice;
                tokenPrice+=basePrice;
            }
        } else {
            for (uint i = 1; i <= amount; i++) {
                if (i > anOfferYouCantResist) {
                    price+=tokenPrice;
                    tokenPrice+=basePrice;
                }
            }
        }

            require(msg.value >= price, "Need to send more ETH.");
            
            _safeMint(msg.sender,amount);
    }
     /* END MINT */

    //SETTERS

    function setSentinentLife(uint256 _newSupply) external onlyOwner {
        require(_newSupply <= sentinentLife,"Can't Increase Supply");
        sentinentLife = _newSupply;
    }

    function setTeamAmount(uint256 _newSupply) external onlyOwner {
        require(_newSupply <= teamAmount,"Can't Increase Supply");
        teamAmount = _newSupply;
    }
    //@seekers - oY90XcdRt56

    function enterEventHorizon(bool _status) public onlyOwner {
        eventHorizon = _status;
    }

    function initiateStartSequence(bool _status) public onlyOwner {
        startSequence = _status;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setUriSuffix(string memory _newSuffix) external onlyOwner{
        uriSuffix = _newSuffix;
    }

    function setBasePrice(uint256 _newPrice) external onlyOwner {
        basePrice = _newPrice;
    }

    function setGreediness(uint256 _newSupply) external onlyOwner {
        dontBeGreedy = _newSupply;
    }

    //END SETTERS

    // GETTERS

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function mintPrice(address who,uint256 amount) public view returns (uint256) {

        uint256 minted = numberMinted(who);

        uint256 price;
        uint256 tokenPrice = basePrice;
        if (minted > 0) {
            for (uint i = 1; i <= minted; i++) {
                if (i > anOfferYouCantResist) {
                    tokenPrice+=basePrice;
                }
            }
            for (uint i = 1; i <= amount; i++) {
                price+=tokenPrice;
                tokenPrice+=basePrice;
            }
        } else {
            for (uint i = 1; i <= amount; i++) {
                if (i > anOfferYouCantResist) {
                    price+=tokenPrice;
                    tokenPrice+=basePrice;
                }
            }
        }
        return price;
        
    }

    // END GETTERS
    // FACTORY

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (eventHorizon == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(),uriSuffix))
                : "";
    }
    //@theCurious - Np539ZdrtNMq2

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;

        (bool r1, ) = payable(0x5898E79586007aD656408C0A01330b934491c997).call{value: balance * 5000/10000}("");
        require(r1);
        (bool r2, ) = payable(0x4632Af21FAA0C8Fa52c0D8E3444F1d27bcc16F3A).call{value: balance * 5000/10000}("");
        require(r2);
    }
    
}