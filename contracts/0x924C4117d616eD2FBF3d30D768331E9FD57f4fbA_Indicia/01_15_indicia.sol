// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/DefaultOperatorFilterer.sol";

import {SignatureChecker} from "./libs/SignatureChecker.sol";

contract Indicia is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    uint256 public constant FAR_FUTURE = 0xFFFFFFF;
    uint256 public constant MAX_SUPPLY = 9000;
    uint256 public price = 0.02 ether;
    uint256 public presalePrice = 0.02 ether;
    string public baseURI;
    uint256 public maxMintAmount = 10;
    uint256 private _presaleStart = FAR_FUTURE;
    uint256 private _publicSaleStart = FAR_FUTURE;
    address public immutable adminSigner;
    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor(address adminSigner_) ERC721A("Indicia NFT", "INDC") {
        adminSigner = adminSigner_;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Indicia NFT"),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function setBaseURI(string memory newBaseURI_) public onlyOwner {
        baseURI = newBaseURI_;
    }

    function setMaxMintAmount(uint256 newMaxMintAmount_) public onlyOwner {
        maxMintAmount = newMaxMintAmount_;
    }

    function setPrices(uint256 presalePrice_, uint256 price_) public onlyOwner {
        presalePrice = presalePrice_;
        price = price_;
    }

    function startPresale(uint256 daysAfter_) public onlyOwner {
        _presaleStart = block.timestamp;
        _publicSaleStart = block.timestamp + daysAfter_ * 1 days;
    }

    function mint(uint256 mintAmount_) public payable nonReentrant {
        require(
            block.timestamp >= _publicSaleStart,
            "Indicia NFT: public sale is inactive"
        );
        require(mintAmount_ > 0, "Indicia NFT: invalid mint amount");
        require(
            mintAmount_ <= maxMintAmount,
            "Indicia NFT: exceeds max mint amount"
        );
        require(
            totalSupply() + mintAmount_ <= MAX_SUPPLY,
            "Indicia NFT: exceeds max supply"
        );
        require(
            msg.value >= price * mintAmount_,
            "Indicia NFT: insufficient fund"
        );
        if (msg.value > price * mintAmount_) {
            Address.sendValue(
                payable(_msgSender()),
                msg.value - price * mintAmount_
            );
        }
        _mint(_msgSender(), mintAmount_);
    }

    function whitelistMint(uint256 mintAmount_, Coupon memory coupon)
        public
        payable
        nonReentrant
    {
        require(
            block.timestamp < _publicSaleStart &&
                block.timestamp >= _presaleStart,
            "Indicia NFT: Presale is inactive"
        );
        require(mintAmount_ > 0, "Indicia NFT: invalid mint amount");
        require(
            mintAmount_ <= maxMintAmount,
            "Indicia NFT: exceeds max mint amount"
        );
        require(
            totalSupply() + mintAmount_ <= MAX_SUPPLY,
            "Indicia NFT: exceeds max supply"
        );
        require(
            msg.value >= presalePrice * mintAmount_,
            "Indicia NFT: insufficient fund"
        );
        bytes32 typeHash = keccak256("Whitelist(address whitelist)");
        bytes32 digest = keccak256(abi.encode(typeHash, _msgSender()));
        require(
            SignatureChecker.verify(
                digest,
                adminSigner,
                coupon.v,
                coupon.r,
                coupon.s,
                DOMAIN_SEPARATOR
            ),
            "Indicia NFT: Invalid signature"
        );
        if (msg.value > presalePrice * mintAmount_) {
            Address.sendValue(
                payable(_msgSender()),
                msg.value - price * mintAmount_
            );
        }
        _mint(_msgSender(), mintAmount_);
    }

    function withdraw() public onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // view
    function isPresaleActive() public view returns (bool) {
        return (block.timestamp < _publicSaleStart &&
            block.timestamp > _presaleStart);
    }

    function isPublicSaleActive() public view returns (bool) {
        return block.timestamp > _publicSaleStart;
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}