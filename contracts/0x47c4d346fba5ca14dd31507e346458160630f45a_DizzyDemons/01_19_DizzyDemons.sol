// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";

abstract contract Dragons {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function balanceOf(address owner) public virtual view returns (uint256 balance);
}

contract DizzyDemons is ERC721Tradable {
    using SafeMath for uint256;
    address constant WALLET1 = 0xffe5CBCDdF2bd1b4Dc3c00455d4cdCcf20F77587;
    uint256 constant public MAX_SUPPLY = 5000;
    bool public saleIsActive = false;
    bool public preSaleIsActive = true;
    uint256 public mintPrice = 40000000000000000; // 0.04 ETH
    uint256 public maxToMint = 5;
    uint256 public maxToMintPresale = 1;
    string _baseTokenURI;
    string _contractURI;
    Dragons dragons;

    constructor(address _proxyRegistryAddress) ERC721Tradable("Dizzy Demons", "DEMON", _proxyRegistryAddress) {
        dragons = Dragons(0x882A47e6070acA3f38Ce6929501F4787803A072b);
    }

    struct Claims {
        uint256 tokenId;
        bool claimed;
    }
    mapping(uint256 => Claims) public claimlist;

    function baseTokenURI() override virtual public view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory _uri) public onlyOwner {
        _contractURI = _uri;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setMaxToMint(uint256 _maxToMint) external onlyOwner {
        maxToMint = _maxToMint;
    }

    function setMaxToMintPresale(uint256 _maxToMint) external onlyOwner {
        maxToMintPresale = _maxToMint;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function isClaimed(uint256 tokenId) public view returns (bool claimed) {
        return claimlist[tokenId].tokenId == tokenId;
    }

    function reserve(address to, uint256 numberOfTokens) public onlyOwner {
        uint i;
        for (i = 0; i < numberOfTokens; i++) {
            mintTo(to);
        }
    }

    function claimNDemons(uint256[] memory tokenIds) public {
        require(tokenIds.length <= 20, "Can't claim more than 20 Demons at once.");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(tokenIds[i] > 7500, "This token is not fused.");
            require(dragons.ownerOf(tokenIds[i]) == msg.sender, "You do not own this token.");
            require(!isClaimed(tokenIds[i]), "Demon has already been claimed for this token.");
            claimlist[tokenIds[i]].tokenId = tokenIds[i];
            claimlist[tokenIds[i]].claimed = true;
            mintTo(msg.sender);
        }
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active.");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Sold out.");
        require(mintPrice.mul(numberOfTokens) <= msg.value, "ETH sent is incorrect.");
        if (preSaleIsActive) {
            require(numberOfTokens <= maxToMintPresale, "Exceeds wallet pre-sale limit.");
            require(dragons.balanceOf(msg.sender) > 0, "You do not own any Dizzy Dragons.");
            require(balanceOf(msg.sender) < 1, "Limit of one per wallet during the pre-sale.");
        } else {
            require(numberOfTokens <= maxToMint, "Exceeds per transaction limit.");
        }

        for(uint i = 0; i < numberOfTokens; i++) {
            mintTo(msg.sender);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 wallet1Balance = balance.mul(5).div(100);
        payable(WALLET1).transfer(wallet1Balance);
        payable(msg.sender).transfer(balance.sub(wallet1Balance));
    }
}