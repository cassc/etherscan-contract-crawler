pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dumpies is ERC721A, Ownable{

    uint256 public MAX_MINT = 50;
    uint256 public COST = 7000000000000000;
    uint256 public COLLECTION_SIZE = 1000;

    bool public revealed;

    address payable private WALLET;

    string internal baseURI;



    constructor() ERC721A("Dumpies", "DUMPIES"){
        baseURI = "ipfs://QmcP9ZPy2WbaKsPdCKACLvwP8TJraVU5RmQX3RT9fqN8Xg"; //Placeholder Token
        WALLET = payable(0xD13594e66f993D4a53575a858ac3718bA8245868);
    }

    function mint(uint256 quantity) external payable {
        require(quantity > 0, "Zero mint dissallowed");
        require(quantity <= MAX_MINT, "Exceeds max mint per transaction");
        require(_totalMinted() + quantity <= COLLECTION_SIZE, "Mint would exceed collection size");
        require(msg.value >= COST * quantity, "insufficient funds");

        _mint(msg.sender, quantity);
 
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return revealed ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : baseURI;
    }

    function reveal(string memory newURI) public onlyOwner{
        baseURI = newURI;
        revealed = true;
    }


    function withdraw() public onlyOwner{
        WALLET.transfer(address(this).balance);
    }


    function setPlaceholder(string memory newURI) public onlyOwner{
        baseURI = newURI;
    }

    function setPrice(uint256 newPrice) public onlyOwner{
        COST = newPrice;
    }

}