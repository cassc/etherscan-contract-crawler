pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract SMCryptoPass is Ownable, ERC721A, ReentrancyGuard {

    uint256 public constant STARTING_TOKEN_ID  = 1;
    uint256 public constant BATCH_SIZE         = 4;
    uint256 public constant COLLECTION_SIZE    = 1000;

    uint256 private _price;
    string private _baseTokenURI;

    constructor() ERC721A("SM CRYPTO PASS", "SMP") {
        _price           = 75_000_000_000_000_000; // .075 eth
    }

    function mint(uint256 quantity) public payable nonReentrant {
        require(quantity > 0, 'MINT_LIMIT');
        require(quantity <= BATCH_SIZE, 'MINT_LIMIT');
        require(totalSupply() + quantity <= COLLECTION_SIZE, 'MINT_LIMIT');
        require(_price * quantity <= msg.value, 'INSUFFICIENT_VALUE');

        _safeMint(msg.sender, quantity);
    }

    // starting token id
    function _startTokenId() override internal view virtual returns (uint256) {
        return STARTING_TOKEN_ID;
    }

    // metadata URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // withdraw money
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // mint price
    function setPrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    } 

    function getPrice() public view returns (uint256) {
        return _price;
    }
}