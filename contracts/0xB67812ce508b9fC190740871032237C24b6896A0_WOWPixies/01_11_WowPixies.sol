// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WOWPixies is ERC721, Ownable {
    string public PROVENANCE;
    bool public saleIsActive = false;
    string private _baseURIextended;
    uint public currentIndex = 0;

    constructor(string memory baseURI) ERC721("WoW Pixies", "PIXIES") {
        _baseURIextended = baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    //get Total Supply
    function totalSupply() view public returns (uint){
        return currentIndex;
    }

    function mintReserve(address[] calldata addresses) public onlyOwner {    
        for (uint i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], currentIndex + i);
        }
        currentIndex += addresses.length;
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(numberOfTokens <= 10, "Can only mint 5 tokens at a time");
        require(currentIndex + numberOfTokens <= 5555, "Purchase would exceed max supply of");
        require(0.06 ether * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            if (currentIndex < 5555) {
                _safeMint(msg.sender, currentIndex + i);
            }
        }
        currentIndex += numberOfTokens;
    }


/*
* Withdraw Contract Balance
*/
    // withdraw addresses
    address dao = 0x9593bC65Ee57Fa28824D24Be1F379EFd04872150;
    address artist = 0x126A0161d81B3f761F96043B29d0cA01C6cb429E; 
    address charity = 0x1eFceB312e8b72C1C114A3455048DC3e9CE6Ba6B; 
    address konop = 0x72e467b3aE0FabF667584401a82d7261Dc9138b4; 
    address devs = 0x2206168CdE2b3652E2488d9a1283531A4d200aea; 
    address chane = 0x6cc68283D4e303Df5aa07b72BDecA465fc252a30; 

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _dao = address(this).balance * 80/100;
        uint256 _artist = address(this).balance * 3/100;
        uint256 _charity = address(this).balance * 3/100;
        uint256 _konop = address(this).balance * 2/100;
        uint256 _devs = address(this).balance * 4/100;
        uint256 _chane = address(this).balance * 8/100;
        require(payable(dao).send(_dao));
        require(payable(artist).send(_artist));
        require(payable(charity).send(_charity));
        require(payable(konop).send(_konop));
        require(payable(devs).send(_devs));
        require(payable(chane).send(_chane));
    }
}