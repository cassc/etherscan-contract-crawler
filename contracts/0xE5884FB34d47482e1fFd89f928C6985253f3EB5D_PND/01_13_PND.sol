// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PND is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;

    // whitelist mint data
    uint256 public constant WHITELIST_MAX_SUPPLY = 3000;
    uint256 public whitelistSupply = 0;
    bool public whitelistMintState = false;

    mapping(address => uint256) private _whiteList;

    // public mint data
    bool public publicMintState = false;
    uint256 public maxPerTx = 10;
    uint256 public maxPerAddress = 100;
    uint256 public price = 0.01 ether;

    constructor() ERC721A("Punks Never Die", "PND") {}

    function startPublicMint() public onlyOwner {
        publicMintState = true;
    }

    function stopPublicMint() public onlyOwner {
        publicMintState = false;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerAddress(uint256 _maxPerAddress) external onlyOwner {
        maxPerAddress = _maxPerAddress;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function startWhitelistMint() public onlyOwner {
        whitelistMintState = true;
    }

    function stopWhitelistMint() public onlyOwner {
        whitelistMintState = false;
    }

    function setWhiteList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whiteList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address addr) external view returns (uint256) {
        return _whiteList[addr];
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function reserve(uint256 quantity) external onlyOwner {
        require((totalSupply() + quantity) <= MAX_SUPPLY, "Exceed max supply.");
        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(publicMintState, "Public mint is not active.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceed max supply.");
        require((price * quantity) <= msg.value, "Not enough amount sent.");
        require(quantity <= maxPerTx, "Too many per transaction.");
        require(numberMinted(msg.sender) + quantity <= maxPerAddress, "Too many per wallet.");

        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(uint256 quantity) external payable {
        require(whitelistMintState, "Whitelist mint is not active.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceed max supply.");
        require(whitelistSupply + quantity <= WHITELIST_MAX_SUPPLY, "Exceed max whitelist supply.");
        require(quantity <= _whiteList[msg.sender], "Exceeded max available to purchase.");

        whitelistSupply += quantity;
        _whiteList[msg.sender] -= quantity;
        _safeMint(msg.sender, quantity);
    }
}