pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FrontrunTrap is Ownable, ERC721 {

    bool public isOpen = true;
    uint256 public cost = 0.002 ether;
    uint256 public totalSupply = 0;

    constructor() ERC721("Do Not Mint This NFT, this is to stop bots from front running keeny","all legit users who minted will be refunded") {}

    modifier open() {
        require(isOpen, "open");
        _;
    }

    function flip() external onlyOwner {
        !isOpen;
    }
    
    function DO_NOT_MINT_THIS(uint256 quantity) external payable open {
        require(quantity * cost <= msg.value, "wrong value");
        for(uint256 i = 0; i < quantity;) {
            _safeMint(msg.sender, totalSupply++);
            unchecked { i++; }
        }
    }

    function setPrice(uint256 _price) external payable onlyOwner {
        cost = _price;
    }

    function withdraw() external onlyOwner {
        owner().call{value: address(this).balance}("");
    }
}