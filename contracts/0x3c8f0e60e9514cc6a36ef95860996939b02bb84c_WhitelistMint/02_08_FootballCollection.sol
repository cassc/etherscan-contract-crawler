pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FootballCollection is ERC721A, Ownable {
    address private minter;
    string private baseURI;
    mapping(address => bool) allowedMinters;

    constructor(string memory uri, address firstReceiver) ERC721A("Shaolin Soccer game", "SHT") {
        baseURI = uri;
        allowedMinters[msg.sender] = true;
        _mint(firstReceiver, 1);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), '.json')) : '';
    }

    function mint(address user, uint256 quantity) external {
        require(allowedMinters[msg.sender], 'not allowed to mint');
        _mint(user, quantity);
    }

    function addMinter(address minter) external onlyOwner {
        allowedMinters[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        allowedMinters[minter] = false;
    }

}