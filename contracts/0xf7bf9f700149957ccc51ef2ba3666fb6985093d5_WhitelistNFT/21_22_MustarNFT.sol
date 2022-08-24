// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Import Ownable from the OpenZeppelin Contracts library
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Make Box inherit from the Ownable contract
contract MustarNFT is ERC721, Ownable {
    uint256 private _value;

    uint256 private increment;
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;
    mapping (uint256 => string) private _tokenURIs;

    event ValueChanged(uint256 value);

    event Minted(uint256 value, address receipient);

    // The onlyOwner modifier restricts who can call the store function
    function store(uint256 value) public onlyOwner {
        _value = value;
        emit ValueChanged(value);
    }

    function retrieve() public view returns (uint256) {
        return _tokenIds.current();
    }

    function hardcoded() public returns (uint256) {
        increment += 1;
        return increment;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
    internal
    virtual
    {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) 
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        return _tokenURI;
    }

    function mint(address recipient, string memory uri)
    public
    returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, uri);
        emit Minted(newItemId, recipient);
        return newItemId;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function approve(address to, uint256 tokenId)
    override
    public
    {
        super.approve(to, tokenId);
    }
}