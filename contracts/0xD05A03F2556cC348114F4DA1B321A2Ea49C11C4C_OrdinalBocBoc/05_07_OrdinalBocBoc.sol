// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract OrdinalBocBoc is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 999;
    uint256 public constant FREE_SUPPLY = 500;
    uint256 public constant MAX_FREE_PER_WALLET = 10;
    uint256 public constant PRICE_PER_TOKEN = 0.008 ether;
    bool public mintPaused = true;
    string private _baseTokenURI;
    mapping(address => uint) private _walletFreeMintCount;

    constructor() ERC721A("OrdinalBocBoc", "BOC") {}

    function freeMint(uint256 quantity) external payable {
        require(!mintPaused, "Mint is paused.");
        require(_totalMinted() + quantity <= FREE_SUPPLY, "Max Supply Hit!");
        require(
            _walletFreeMintCount[msg.sender] + quantity <= MAX_FREE_PER_WALLET,
            "Max free mint exceeded!"
        );

        _safeMint(msg.sender, quantity);
        _walletFreeMintCount[msg.sender] =
            _walletFreeMintCount[msg.sender] +
            quantity;
    }

    function paidMint(uint256 quantity) external payable {
        require(!mintPaused, "Mint is paused.");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Max Supply Hit!");
        require(msg.value >= quantity * PRICE_PER_TOKEN, "Insufficient Funds.");
        _safeMint(msg.sender, quantity);
    }

    function mintedCount(address owner) external view returns (uint) {
        return _walletFreeMintCount[owner];
    }

    function start(bool paused) external onlyOwner {
        mintPaused = paused;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getTokenCounter() public view returns (uint256) {
        return _totalMinted();
    }

    function getPricePerToken() public pure returns (uint256) {
        return PRICE_PER_TOKEN;
    }
}