/*
██████╗░░█████╗░░█████╗░██╗░░██╗██████╗░░█████╗░░█████╗░██╗░░██╗███████╗██████╗░
██╔══██╗██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██╔══██╗██╔══██╗██║░██╔╝██╔════╝██╔══██╗
██████╦╝███████║██║░░╚═╝█████═╝░██████╔╝███████║██║░░╚═╝█████═╝░█████╗░░██████╔╝
██╔══██╗██╔══██║██║░░██╗██╔═██╗░██╔═══╝░██╔══██║██║░░██╗██╔═██╗░██╔══╝░░██╔══██╗
██████╦╝██║░░██║╚█████╔╝██║░╚██╗██║░░░░░██║░░██║╚█████╔╝██║░╚██╗███████╗██║░░██║
╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Backpackers is ERC721A, Ownable {
    uint public freeBag = 2;
    uint public maxPerWallet = 5;
    uint public maxBags = 3333;
    uint public constant reserve = 67;
    uint public cost = 0.003 ether;
    bool public stop = false;
    bool public live = false;
    string public baseURI = "ipfs:///";
    string public constant ext = ".json";

    constructor() ERC721A("THe BackPacKER", "TBP") {}

    function getPrice() external view returns (uint){
        return cost;
    }

    function _startTokenId() internal view virtual override returns (uint) {
        return 1;
    }

    function mint(uint _amount) external payable {
        require(!stop, "Paused");
        require(live, "Not live!");
        require(tx.origin == msg.sender, "No bots");
        require(maxBags >= totalSupply() + _amount, "Exceeds max supply");
        require(_amount > 0 && _amount <= maxPerWallet,"Excess max trx");
        require(_numberMinted(msg.sender) + _amount <= maxPerWallet,"Max per wallet exceeded!");
        
      if(_numberMinted(msg.sender) >= freeBag){
            require(msg.value >= _amount * cost, "Insufficient funds");
        }else{
            uint count = _numberMinted(msg.sender) + _amount;
            if(count > freeBag){
                require(msg.value >= (count - freeBag) * cost , "Insufficient funds");
            }   
        }
        _safeMint(_msgSender(), _amount);
    }

    function teamMint(uint amount) external onlyOwner {
        uint maxSize = maxBags + reserve;
        require(_numberMinted(msg.sender) + amount <= reserve,"Exceeds reserved size");
        require(maxSize >= totalSupply() + amount, "Exceeds max supply");
        _safeMint(msg.sender, amount);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed");
    }

    function departure() external onlyOwner {
        _safeMint(_msgSender(), 1);
    }

    function setMax(uint newBag) external onlyOwner {
        maxBags = newBag;
    }

    function pause(bool val) external onlyOwner {
        stop = val;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function start(bool val) external onlyOwner {
        live = val;
    }

    function setCost(uint _amt) external onlyOwner {
        cost = _amt;
    }

    function setFree(uint _amt) external onlyOwner {
        freeBag = _amt;
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Invalid id.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              ext
            )
        ) : "";
    }
}