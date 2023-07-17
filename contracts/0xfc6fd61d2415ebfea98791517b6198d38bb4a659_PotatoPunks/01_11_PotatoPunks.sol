// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PotatoPunks is ERC721, Ownable {
    uint256 public currentTokenId;
    uint256 public maxPerTransaction = 20;
    uint256 public price = 0.025 ether;

    uint256 public constant SUPPLY = 5555;
    uint256 public constant FREE_SUPPLY = 500;
    uint256 public constant FREE_MAX = 20;

    string public _baseTokenURI;

    bool public isActive = false;

    address private a1 = 0x038fc3bEd90dEF130A40caD5C140CC990bF2e0Cc;
    address private a2 = 0x866ba6E792B0d6E3fFdaFe84ee0a54b008380365;
    address private a3 = 0x86815376e5225498532837Fae5789B0ccE657114;
    address private a4 = 0xD2Bf76BA687109FbEafE59307EFcdaAB77177425;
    address private a5 = 0x83EFCDFc85e4Ffa97133C3062edc6Cdf401a32D3;
    address private a6 = 0x985AFcA097414E5510c2C4faEbDb287E4F237A1B;
    address private a7 = 0x3B2eA2F99277BA46C261A606E7811ee136A48AF8;

    mapping(address => uint256) private freeClaimed;

    event Mint(address purchaser, uint256 amount);
    event SaleStateChange(bool newState);

    constructor(string memory baseURI) ERC721("PotatoPunks", "PUNKTATO") {
        _baseTokenURI = baseURI;
    }

    function mint(uint256 qty) external payable {
        require(isActive, "SALE_INACTIVE");
        require(qty <= maxPerTransaction, "TOO_MANY_TOKENS");
        require((currentTokenId + qty) <= SUPPLY, "SOLD_OUT");
        require(msg.value == price * qty, "INVALID_PRICE");

        for (uint256 i; i < qty; i++) {
            currentTokenId++;
            _safeMint(msg.sender, currentTokenId);
        }

        emit Mint(msg.sender, qty);
    }

    function mintFree(uint256 qty) external {
        require(isActive, "SALE_INACTIVE");
        require(freeClaimed[msg.sender] + qty <= FREE_MAX, "TOO_MANY_TOKENS");
        require(currentTokenId + qty <= FREE_SUPPLY, "SOLD_OUT");

        for (uint256 i; i < qty; i++) {
            freeClaimed[msg.sender]++;
            currentTokenId++;
            _safeMint(msg.sender, currentTokenId);
        }
    }

    function totalSupply() public view virtual returns (uint256) {
        return currentTokenId;
    }

    function setSaleActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
        emit SaleStateChange(_isActive);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(a1).transfer((balance * 15) / 100);
        payable(a2).transfer((balance * 15) / 100);
        payable(a3).transfer((balance * 15) / 100);
        payable(a4).transfer((balance * 15) / 100);
        payable(a5).transfer((balance * 15) / 100);
        payable(a6).transfer((balance * 15) / 100);
        payable(a7).transfer(address(this).balance);
    }

    function setPerTransactionMax(uint256 limit) public onlyOwner {
        maxPerTransaction = limit;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function tokensOf(address wallet) public view returns (uint256[] memory) {
        uint256 supply = totalSupply();
        uint256[] memory tokenIds = new uint256[](balanceOf(wallet));

        uint256 currIndex = 0;
        for (uint256 i = 1; i <= supply; i++) {
            if (wallet == ownerOf(i)) tokenIds[currIndex++] = i;
        }

        return tokenIds;
    }
}