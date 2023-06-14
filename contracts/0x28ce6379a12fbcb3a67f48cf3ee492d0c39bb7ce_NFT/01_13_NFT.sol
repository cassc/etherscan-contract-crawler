pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721URIStorage, Ownable {
    enum Rarity { Common, Rare, Legendary, Epic }

    struct TokenAttributes {
        Rarity rarity;
        uint256 value;
    }

    mapping (Rarity => string) public tokenUris;
    mapping (address => bool) public managers;
    mapping (uint256 => TokenAttributes) public tokensAttributes;
    uint256 public tokenNumber;

    constructor(string memory _name, string memory _symbol, string[] memory _tokenUris) ERC721(_name, _symbol) {
        require(_tokenUris.length == 4, "tokens uri size doesn't match with numbers of rarity");
        tokenUris[Rarity.Common] = _tokenUris[0];
        tokenUris[Rarity.Rare] = _tokenUris[1];
        tokenUris[Rarity.Legendary] = _tokenUris[2];
        tokenUris[Rarity.Epic] = _tokenUris[3];
    }

    function manageManagers(address[] memory _managers, bool[] memory _value) onlyOwner public {
        require(_managers.length == _value.length, "managers and value size doesn't equal");
        for(uint256 i = 0; i < _managers.length; ++i) {
            managers[_managers[i]] = _value[i];
        }
    }

    modifier onlyManager() {
        require(managers[msg.sender], "sender is not a manager");
        _;
    }

    function claim(address _receiver, Rarity _rarity, uint256 _value) onlyManager public {
        ERC721._mint(_receiver, tokenNumber);
        ERC721URIStorage._setTokenURI(tokenNumber, tokenUris[_rarity]);
        tokensAttributes[tokenNumber] = TokenAttributes(_rarity, _value); 

        tokenNumber++;
    }

    function burn(uint256 _tokenId) public {
        require(msg.sender == ERC721.ownerOf(_tokenId), "not token owner");
        ERC721._burn(_tokenId);
    }

    function changeTokenUris(string[] memory _tokenUris) onlyOwner public {
        require(_tokenUris.length == 4, "tokens uri size doesn't match with numbers of rarity");
        tokenUris[Rarity.Common] = _tokenUris[0];
        tokenUris[Rarity.Rare] = _tokenUris[1];
        tokenUris[Rarity.Legendary] = _tokenUris[2];
        tokenUris[Rarity.Epic] = _tokenUris[3];
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        _requireMinted(_tokenId);        
        return tokenUris[tokensAttributes[_tokenId].rarity];
    }
}