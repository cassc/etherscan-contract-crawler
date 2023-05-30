// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./console.sol";

contract GMFERS is Ownable, ERC721A, ReentrancyGuard {
    uint256 private _earlyMintCost = 5000000000000000;
    uint256 private _mintCost = 6900000000000000;
    uint256 private _collectionSize;
    uint256 private _earlyMintCount;
    bool private _isMintActive = false;
    bool private _isPreReveal = true;
    string private _baseTokenURI;
    address private _paymentAddress1;
    address private _paymentAddress2;
    address private _paymentAddress3;
    address private _paymentAddress4;
    address private _paymentAddress5;
    address private _paymentAddress6;

    constructor(
        uint256 collectionSize_,
        uint256 earlyMintCount_,
        address paymentAddress1_,
        address paymentAddress2_,
        address paymentAddress3_,
        address paymentAddress4_,
        address paymentAddress5_,
        address paymentAddress6_
        ) ERC721A("gmfers", "gmfers") {
            _collectionSize = collectionSize_;
            _earlyMintCount = earlyMintCount_;
            _paymentAddress1 = paymentAddress1_;
            _paymentAddress2 = paymentAddress2_;
            _paymentAddress3 = paymentAddress3_;
            _paymentAddress4 = paymentAddress4_;
            _paymentAddress5 = paymentAddress5_;
            _paymentAddress6 = paymentAddress6_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setIsMintActive(bool isMintActive) public onlyOwner {
        _isMintActive = isMintActive;
    }

    function getIsMintActive() public view returns (bool) {
        return _isMintActive;
    }

    function setIsPreReveal(bool isPreReveal) public onlyOwner {
        _isPreReveal = isPreReveal;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function ownerMint(uint256 quantity) external payable callerIsUser {
        require(quantity > 0);
        require(msg.sender == _paymentAddress1 || msg.sender == _paymentAddress2 || msg.sender == _paymentAddress3 || msg.sender == _paymentAddress4 || msg.sender == _paymentAddress5 || msg.sender == _paymentAddress6, "not an owner");

        _safeMint(msg.sender, quantity);
    }

    function earlyPublicMint(uint256 quantity) external payable callerIsUser {
        require(quantity > 0);
        require(_isMintActive, "mint is not open yet gmfer");
        require(
            totalSupply() + quantity <= _earlyMintCount,
            "reached max supply of early mints gmfer, now youll have to pay up"
        );
        require(msg.value >= _earlyMintCost * quantity, "not enough funds");

        _safeMint(msg.sender, quantity);
        refundIfOver(_earlyMintCost * quantity);
    }

    function publicMint(uint256 quantity) external payable callerIsUser {
        require(quantity > 0);
        require(_isMintActive, "mint is not open at this time");
        require(
            totalSupply() + quantity <= _collectionSize,
            "reached max supply"
        );
        require(msg.value >= _mintCost * quantity, "not enough funds");

        _safeMint(msg.sender, quantity);
        refundIfOver(_mintCost * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721A.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function burninate(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function xdf() external onlyOwner nonReentrant {
        uint256 payment1 = address(this).balance * 16 / 100;
        uint256 payment2 = address(this).balance * 16 / 100;
        uint256 payment3 = address(this).balance * 15 / 100;
        uint256 payment4 = address(this).balance * 15 / 100;
        uint256 payment5 = address(this).balance * 15 / 100;
        uint256 payment6 = address(this).balance * 15 / 100;

        Address.sendValue(payable(_paymentAddress1), payment1);
        Address.sendValue(payable(_paymentAddress2), payment2);
        Address.sendValue(payable(_paymentAddress3), payment3);
        Address.sendValue(payable(_paymentAddress4), payment4);
        Address.sendValue(payable(_paymentAddress5), payment5);
        Address.sendValue(payable(_paymentAddress6), payment6);
    }

    function xd() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (bytes(_baseTokenURI).length == 0) {
            return "";
        }

        string memory tokenIdString = Strings.toString(tokenId);

        if (_isPreReveal) {
            return string(abi.encodePacked(_baseTokenURI, "/pre-reveal.json"));
        } else {
            return string(abi.encodePacked(_baseTokenURI, "/", tokenIdString, ".json"));
        }
    }
}