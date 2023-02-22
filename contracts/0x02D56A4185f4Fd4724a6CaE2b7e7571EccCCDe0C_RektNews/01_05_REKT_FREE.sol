// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RektNews is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public constant PER_WALLET = 5;
    uint256 public PRICE = .0055 ether;

    bool public IS_ACTIVE = false;
    bool public IS_FREE = true;
    bool public IS_REVEALED = false;
    string private UNREV_URL = "https://gateway.pinata.cloud/ipfs/QmStxthh3ND5Teyy7q1457gxgWWPa1J2wRzssG7oqjMbNQ";
    string private REV_URL = "https://gateway.pinata.cloud/ipfs/QmStxthh3ND5Teyy7q1457gxgWWPa1J2wRzssG7oqjMbNQ/";

    constructor() ERC721A("RektNews", "REKT") {}

    function mint(uint256 qty) external payable {
        require(IS_ACTIVE, "MINT IS NOT ACTIVE");

        require(qty > 0, "WTF YOU MINTED ZERO");
        require((totalSupply() + qty) <= MAX_SUPPLY, "OUT OF STOCK");
        require((balanceOf(msg.sender) + qty) <= PER_WALLET, "ONLY 5 PER WALLET");

        if (!IS_FREE) require(msg.value >= PRICE * qty, "NOT ENOUGH ETH");

        _safeMint(msg.sender, qty);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "TOKEN DON'T EXIST!");

        if (!IS_REVEALED) return UNREV_URL;

        return string(abi.encodePacked(REV_URL, _toString(tokenId), ".json"));
    }

    /* OWNERS ZONE. NO TRESPASSING! */
    function reveal() external onlyOwner {
        IS_REVEALED = !IS_REVEALED;
    }

    function toggleActive() external onlyOwner {
        IS_ACTIVE = !IS_ACTIVE;
    }

    function toggleFree() external onlyOwner {
        IS_FREE = !IS_FREE;
    }

    function setRevUrl(string memory _url) external onlyOwner {
        REV_URL = _url;
    }

    function setUnrevUrl(string memory _url) external onlyOwner {
        UNREV_URL = _url;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function creatorMint(uint256 _qty) external payable onlyOwner {
        _safeMint(msg.sender, _qty);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}