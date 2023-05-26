pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlackSandEditions is ERC1155, Ownable {
    struct Artwork {
        uint256 id;
        uint256 maxSupply;
        uint256 currentSupply;
        uint256 price;
        uint256 saleEndBlock;
    }

    mapping(uint256 => Artwork) private artworks;
    uint256 private nextArtworkId;
    mapping(address => uint256[]) private ownerTokens;
    string private baseURI;

    constructor() ERC1155("") {
        baseURI = "https://forgottenbabies.com/blacksand/editions/";
    }

    function createArtwork(uint256 maxSupply, uint256 price, uint256 saleEndBlock) public onlyOwner {
        artworks[nextArtworkId] = Artwork({
            id: nextArtworkId,
            maxSupply: maxSupply,
            currentSupply: 0,
            price: price,
            saleEndBlock: saleEndBlock
        });
        nextArtworkId++;
    }

    modifier requireCorrectEth(uint256 artworkId, uint256 mintCount) {
        require(msg.value == artworks[artworkId].price * mintCount, "Sent incorrect Ether");
        _;
    }

    function buyArtwork(uint256 artworkId, uint256 amount) public payable requireCorrectEth(artworkId, amount) {
        Artwork storage artwork = artworks[artworkId];

        require(artwork.id == artworkId, "Artwork not found");
        require(artwork.currentSupply + amount <= artwork.maxSupply, "Exceeds max supply");
        require(block.number <= artwork.saleEndBlock, "Sale has ended");

        _mint(msg.sender, artwork.id, amount, "");
        ownerTokens[msg.sender].push(artworkId);
        artwork.currentSupply += amount;
    }

    function totalSupply(uint256 artworkId) public view returns (uint256) {
        return artworks[artworkId].currentSupply;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, uint2str(tokenId), ".json"));
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return ownerTokens[owner];
    }

    function updateBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function uint2str(uint256 _i) private pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}