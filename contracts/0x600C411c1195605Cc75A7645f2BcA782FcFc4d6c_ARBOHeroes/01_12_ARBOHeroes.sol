pragma solidity 0.8.11;

import "./tokens/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ARBOHeroes is ERC721A, Ownable { 

    using Strings for uint256;
    string _baseTokenURI;
    
    constructor(
        string memory _name, 
        string memory _symbol,
        string memory baseURI
    ) ERC721A(_name, _symbol) {
        setBaseURI(baseURI);
    }
    
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mint(address to, uint256 quantity, bytes memory data, bool safe) public onlyOwner {
        _mint(to, quantity, data, safe);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public onlyOwner {
        _safeMint(to, tokenId, data);
    }

}