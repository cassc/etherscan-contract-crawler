// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NightsNara is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using SafeMath for uint256;
    using Strings for uint256;

    string public baseTokenURI;
    uint256 public mintPrice = 0.05 ether;
    uint256 public collectionSize = 10000;
    uint256 public whitelistminted;
    bool public whitelistMintPaused = true;
    bool public publicMintPaused = true;
    mapping(address => bool) public whitelistAddresses;

    constructor() ERC721A("Nights with Nara", "NARA") {}

    function freeMint(uint256 amount) external payable nonReentrant {
        require(!publicMintPaused, "Public mint is paused");
        require(totalSupply() <= 500, "Free Mint is Over");
        require(msg.value == 0, "Must provide exact required ETH");
        _safeMint(msg.sender, amount);
    }

    function mint(uint256 amount) external payable nonReentrant {
        require(!publicMintPaused, "Public mint is paused");
        require(amount > 0, "Amount to mint is 0");
        require(totalSupply()+ amount <= collectionSize, "Sold out!");
        require(msg.value == mintPrice.mul(amount), "Must provide exact required ETH");
        _safeMint(msg.sender, amount);
    }

    function setPublicSale(bool _status) external onlyOwner {
        publicMintPaused = _status;
    }

    function setWLMint(bool _status) external onlyOwner {
        whitelistMintPaused = _status;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send ether");
    }

    function TeamReserve(uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= collectionSize, "Sold out!");
        _safeMint(msg.sender, amount);
    }
    
    function addwhitelist(address [] calldata _users) public onlyOwner{
        uint256 length = _users.length;
        for (uint256 i; i < length; i++ ){
            whitelistAddresses[_users[i]] = true;
        }
    }

    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
            }
            else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
        }
        return _tokens;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return bytes(baseTokenURI).length != 0 ? string(abi.encodePacked(baseTokenURI, tokenId.toString())) : '';
    }
}