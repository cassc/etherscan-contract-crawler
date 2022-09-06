pragma solidity ^0.8.0;

/*
 _______  _______  ______     _______  _______  _______  _______ 
(  ____ \(  ___  )(  __  \   (  ____ )(  ____ \(  ____ )(  ____ \
| (    \/| (   ) || (  \  )  | (    )|| (    \/| (    )|| (    \/
| (_____ | (___) || |   ) |  | (____)|| (__    | (____)|| (__    
(_____  )|  ___  || |   | |  |  _____)|  __)   |  _____)|  __)   
      ) || (   ) || |   ) |  | (      | (      | (      | (      
/\____) || )   ( || (__/  )  | )      | (____/\| )      | (____/\
\_______)|/     \|(______/   |/       (_______/|/       (_______/
                                                                 
 _______  _______  _______  _______ 
(  ____ \(  ___  )(  ____ \(  ____ \
| (    \/| (   ) || (    \/| (    \/
| (__    | (___) || |      | (__    
|  __)   |  ___  || |      |  __)   
| (      | (   ) || |      | (      
| )      | )   ( || (____/\| (____/\
|/       |/     \|(_______/(_______/
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SadPepeFace is ERC721, Ownable, ReentrancyGuard {
    // Constants
    uint256 public TOKEN_PRICE = 10000000000000000;
    uint256 public MAX_SUPPLY = 888;

    // State variables
    uint256 private _totalSupply = 0;

    // Constructor
    constructor() ERC721("Sad Pepe Face", "SADPEPE") {}

    // Minting
    function mint(uint256 amount) public payable nonReentrant {
        require(amount > 0 && amount <= 20, "Amount must be between 1 and 20");
        require(_totalSupply + amount < MAX_SUPPLY, "There is no supply available to mint that amount");
        require(msg.value >= amount * TOKEN_PRICE, "Price must be .01 eth per token");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(_msgSender(), _totalSupply);
            _totalSupply++;
        }
    }

    // Withdraw
    function withdraw() public payable nonReentrant onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Getters
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return "ipfs://QmY73kCnAqXooQbK5kUpk2jBF1JvWPBBSR6whRaNMoTsj7";
    }
}