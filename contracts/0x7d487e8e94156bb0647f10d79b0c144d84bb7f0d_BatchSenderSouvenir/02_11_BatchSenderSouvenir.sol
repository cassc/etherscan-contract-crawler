pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract BatchSenderSouvenir is ERC721, Ownable {

    using Strings for uint256;

    uint256 public totalSupply;

    string public baseURI;

    constructor(string memory uri) ERC721("TokenPocket Batch Sender Souvenir", "Batch Sender Souvenir") {
        baseURI = uri;
    }

    function updateBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function mint(address[] memory accounts) public onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            uint256 tokenId = totalSupply + 1;
            _safeMint(accounts[i], tokenId);
            totalSupply = tokenId;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return baseURI;
    }
}