// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GenerascopeInfinity is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 public constant GS_MAX = 1118;
    uint256 public constant GS_PRICE = 0.1 ether;
    address public constant GS_HEX_CONTRACT_ADDRESS = 0xF5308E067ff8490DD32E24B4b0c5934a789E4783;

    mapping(address => uint256) public allPurchases;
    mapping(uint256 => bool) public mintedHexIds;

    string private _contractURI;
    string private _tokenBaseURI;

    uint256 public publicAmountMinted;
    
    bool public saleLive;
    bool public locked;

    constructor() ERC721("Generascope Infinity", "GSINF") {}

    modifier notLocked() {
        require(!locked, "Contract metadata methods are locked");
        _;
    }

    function buy(uint256 tokenQuantity) external payable {
        ERC721Enumerable hexContract = ERC721Enumerable(GS_HEX_CONTRACT_ADDRESS);
        uint256 hexBalance = hexContract.balanceOf(msg.sender);

        require(saleLive, "SALE_CLOSED");
        require(totalSupply() < GS_MAX, "OUT_OF_STOCK");
        require(
            (publicAmountMinted + tokenQuantity) <= GS_MAX,
            "EXCEED_AVAILABLE"
        );
        require(
            allPurchases[msg.sender] + tokenQuantity <= hexBalance,
            "EXCEED_ALLOC"
        );
        require((GS_PRICE * tokenQuantity) == msg.value, "INCORRECT_ETH_AMOUNT");

        uint256[] memory mintableHexIds = new uint256[](tokenQuantity);
        uint256 mintableIdsCursor = 0;
        for (uint256 i = 0; i < hexBalance && mintableIdsCursor < tokenQuantity; i++) {
            uint256 hexId = hexContract.tokenOfOwnerByIndex(msg.sender, i);
            if (mintedHexIds[hexId] != true) {
                mintableHexIds[mintableIdsCursor] = hexId;
                mintableIdsCursor++;
            }
        }

        require(mintableIdsCursor == tokenQuantity, "INVALID_MINTABLE_AMOUNT");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            mintedHexIds[mintableHexIds[i]] = true;
            publicAmountMinted++;
            allPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function ownerMint(uint256 tokenQuantity) external onlyOwner {
        require(totalSupply() < GS_MAX, "OUT_OF_STOCK");
        require(
            (publicAmountMinted + tokenQuantity) <= GS_MAX,
            "EXCEED_AVAILABLE"
        );
        for (uint256 i = 0; i < tokenQuantity; i++) {
            publicAmountMinted++;
            allPurchases[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function allPurchasedCount(address addr)
        external
        view
        returns (uint256)
    {
        return allPurchases[addr];
    }

    // Owner functions for enabling presale and sale
    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setContractURI(string calldata URI) external onlyOwner notLocked {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");

        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json"));
    }
}