pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MadBanana is ERC721, Ownable {
    
    using SafeMath for uint256;
    

    uint256 public price = 42000000000000000; // 0.042 ETH

    uint256 public MAX_BANANAS = 6969;

    uint256 public MAX_BANANA_PURCHASE = 10;

    uint256 public MAD_BANANA_RESERVE = 100;

    bool public saleIsActive = false;

    constructor() ERC721("Mad Banana Union", "MBU") { }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }   

    function setPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function reserveMadBananas(uint256 numberOfTokens) public onlyOwner {
        require(numberOfTokens > 0 && numberOfTokens <= MAD_BANANA_RESERVE, "Not enough reserve left for team");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }

        MAD_BANANA_RESERVE = MAD_BANANA_RESERVE.sub(numberOfTokens);
    }

    function mintMadBanana(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Mad Bananas");
        require(numberOfTokens <= MAX_BANANA_PURCHASE, "Can only mint 20 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_BANANAS, "Purchase would exceed max supply of Bananas");
        require(msg.value >= price.mul(numberOfTokens), "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_BANANAS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
    
}