// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
 
contract SaltyShakers is ERC721Enumerable, Ownable {
    using SafeMath for uint256; 
    string public PROVENANCE = "";
 
    uint256 public STARTING_INDEX;
 
    uint256 public CURRENT_PRICE = 69000000000000000; // 0.069 ETH
 
    uint256 public MAX_PURCHASE = 20;
 
    uint256 public MAX_TOKENS = 10000;
 
    bool public saleIsActive = false;
 
    string private baseURI;
 
    // Constructor
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURIp,
        uint256 startingIndex
    ) ERC721(name, symbol) {
        setBaseURI(baseURIp);
        STARTING_INDEX = startingIndex;
    }
 
    // Salt
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
 
    // Reserve Tokens
    function reserveTokens() public onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply.add(30) <= MAX_TOKENS,
            "Reserve would exceed max supply of Tokens"
        );
 
        for (uint256 i = 1; i <= 30; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
 
    // Set provenance once it's calculated
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }
 
    function setBaseURI(string memory BaseURI) public onlyOwner {
        baseURI = BaseURI;
    }
 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
 
    // Toggle sale state
    function toggleSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
 
    // Mint Token
    function mintToken(uint256 numberOfTokens) public payable {
        uint256 supply = totalSupply();
        require(saleIsActive, "Mint is not available right now");
        require(numberOfTokens <= MAX_PURCHASE, "Can't mint that many in one tx");
        require(
            supply.add(numberOfTokens) <= MAX_TOKENS,
            "Purchase would exceed max supply of Tokens"
        );
        require(
            CURRENT_PRICE.mul(numberOfTokens) <= msg.value,
            "Value sent is not enough"
        );
 
        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function giveAway(address _to, uint256 numberOfTokens) external onlyOwner() {
        uint256 supply = totalSupply();
        require(
            supply.add(numberOfTokens) < MAX_TOKENS,
            "Giveaway would exceed max supply of Tokens"
        );

        for(uint256 i = 1; i <= numberOfTokens; i++){
            _safeMint(_to, supply + i );
        }
    }

    // Set price
    function setPrice(uint256 newPrice) public onlyOwner {
        CURRENT_PRICE = newPrice;
    }
}