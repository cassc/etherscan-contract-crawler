// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract VibrantApesClub is ERC721A, Ownable {
    using Address for address payable;
    using Strings for uint256;

    string private _baseTokenURI;
    bool private _saleStatus = true;
    uint256 private _salePrice = 0.004 ether;

    uint256 public MAX_SUPPLY = 9999;
    uint256 public FREE_PER_WALLET = 3;
    uint256 public MAX_MINTS_PER_TX = 10;
    uint256 public MAX_PER_WALLET = 50;

    constructor() ERC721A("VibrantApesClub", "VAC") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setMaxMintPerTx(uint256 maxMint) external onlyOwner {
        MAX_MINTS_PER_TX = maxMint;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        _salePrice = price;
    }

    function toggleSaleStatus() external onlyOwner {
        _saleStatus = !_saleStatus;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
    }
    
    function trackUserMinted(address minter) external view returns (uint32 userMinted) {
        return uint32(_numberMinted(minter));
    }        

    function mint(uint256 quantity)
        external
        payable
        callerIsUser
    {
        uint256 userMintCount = uint256(_numberMinted(msg.sender));
        uint256 freeQuantity = 0;

        if (userMintCount < FREE_PER_WALLET) {
            uint256 freeLeft = FREE_PER_WALLET - userMintCount;
            freeQuantity += freeLeft > quantity ? quantity : freeLeft;
        }

        uint256 totalPrice = (quantity - freeQuantity) * _salePrice;

        if (totalPrice > msg.value)
            revert("VAC: Insufficient fund");

        if (!isSaleActive()) revert("VAC: Sale not started");
        
        if (quantity > MAX_MINTS_PER_TX)
            revert("VAC: Amount exceeds transaction limit");
        if (quantity + userMintCount > MAX_PER_WALLET)
            revert("VAC: Amount exceeds wallet limit");
        if (totalSupply() + quantity > (MAX_SUPPLY))
            revert("VAC: Amount exceeds supply");

        _safeMint(msg.sender, quantity);
        if (msg.value > totalPrice) {
            payable(msg.sender).sendValue(msg.value - totalPrice);
        }              
    }

    function adminMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "VAC: Amount exceeds supply");

        _safeMint(msg.sender, quantity);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 1;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function mintToAddress(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY)
            revert("VAC: Amount exceeds supply");

        _safeMint(to, quantity);
    }

    function isSaleActive() public view returns (bool) {
        return _saleStatus;
    }

    function getSalePrice() public view returns (uint256) {
        return _salePrice;
    }

}