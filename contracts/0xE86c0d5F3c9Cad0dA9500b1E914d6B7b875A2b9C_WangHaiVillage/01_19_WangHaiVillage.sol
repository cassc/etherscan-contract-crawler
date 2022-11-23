// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WangHaiVillage is Ownable, ERC721A, ReentrancyGuard, DefaultOperatorFilterer {
    uint256 public maxPerAddress;
    bytes32 public merkleRoot;
    bool public flipped;
    using SafeMath for uint256;
    struct SaleConfig {
        uint32 whitelsitSaleStartTime;
        uint32 whitelistSaleDuration;
        uint32 publicSaleStartTime;
        uint32 publicSaleDuration;
        uint64 whitelsitPrice;
        uint64 publicPrice;
    }

    SaleConfig public saleConfig;

    constructor(
        uint256 maxPerAddress_,
        uint256 collectionSize_,
        string memory name_,
        string memory symbol_
    ) ERC721A(name_, symbol_, maxPerAddress_, collectionSize_) {
        maxPerAddress = maxPerAddress_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function whitelistMint(uint256 quantity, bytes32[] memory _proof)
        external
        payable
        callerIsUser
    {
        MerkleProof.verify(
            _proof,
            merkleRoot,
            keccak256(abi.encodePacked(msg.sender))
        );
        uint256 price = uint256(saleConfig.whitelsitPrice);
        require(
            block.timestamp >= saleConfig.whitelsitSaleStartTime,
            "whitelist sale has not begun yet"
        );
        require(
            saleConfig.whitelsitSaleStartTime +
                saleConfig.whitelistSaleDuration >=
                block.timestamp,
            "whitelist sale has ended"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddress,
            "can not mint this many"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        _safeMint(msg.sender, quantity);
        refundIfOver(price * quantity);
    }

    function publicSaleMint(uint256 quantity) external payable callerIsUser {
        SaleConfig memory config = saleConfig;
        uint256 publicPrice = uint256(config.publicPrice);
        require(
            block.timestamp >= saleConfig.publicSaleStartTime,
            "public sale has not begun yet"
        );
        require(
            saleConfig.publicSaleStartTime + saleConfig.publicSaleDuration >=
                block.timestamp,
            "public sale has ended"
        );
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddress,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
        refundIfOver(publicPrice * quantity);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function configSaleInfo(
        uint32 whitelsitSaleStartTime,
        uint32 whitelistSaleDuration,
        uint32 publicSaleStartTime,
        uint32 publicSaleDuration,
        uint64 whitelsitPrice,
        uint64 publicPrice
    ) external onlyOwner {
        saleConfig = SaleConfig(
            whitelsitSaleStartTime,
            whitelistSaleDuration,
            publicSaleStartTime,
            publicSaleDuration,
            whitelsitPrice,
            publicPrice
        );
    }

    function setwhitelsitSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.whitelsitSaleStartTime = timestamp;
    }

    function setpublicSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.publicSaleStartTime = timestamp;
    }

    function setwhitelistSaleDuration(uint32 duration_) external onlyOwner {
        saleConfig.whitelistSaleDuration = duration_;
    }

    function setpublicSaleDuration(uint32 duration_) external onlyOwner {
        saleConfig.publicSaleDuration = duration_;
    }

    function setMerkleProof(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMaxPerAddress(uint256 _maxPerAddress) public onlyOwner {
        maxPerAddress = _maxPerAddress;
    }

    // For marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "No ETH to withdraw");

        require(payable(msg.sender).send(_balance));
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (flipped) {
            return super.tokenURI(tokenId);
        } else {
            return _baseTokenURI;
        }
    }

    function flip() public onlyOwner {
        flipped = !flipped;
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}