// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC721A.sol";

contract CosmodinosOmega is Ownable, ERC721A, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public immutable collectionSize = 8888;
    uint256 public immutable amountForDevs = 200;

    uint256 public allowlistPrice = 0.02 ether;
    uint256 public publicPrice = 0.04 ether;
    bytes32 public merkleRoot;
    bool public publicSaleIsOpen = false;
    bool public allowlistMintIsOpen = false;
    mapping(address => uint256) public publicMinted;

    string private _baseTokenURI;
    address payable private _devWallet;

    constructor(
        string memory tokenUri_,
        string memory name_,
        string memory symbol_,
        address devWallet_
    ) ERC721A(name_, symbol_) {
        _baseTokenURI = tokenUri_;
        _devWallet = payable(devWallet_);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function allowlistMint(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) external payable callerIsUser {
        require(allowlistMintIsOpen == true, "allowlist must be opened");
        require(totalSupply() + count <= collectionSize, "reached max supply");

        uint256 maxQuantity = allowance.sub(_numberMinted(msg.sender));
        require(count <= maxQuantity, "quantity error");

        uint256 totalPrice = allowlistPrice.mul(count);
        require(msg.value >= totalPrice, "Need to send more ETH.");

        require(_verify(_leaf(msg.sender, allowance), proof), "Invalid merkle proof");
        _safeMint(msg.sender, count);
    }

    function publicSaleMint(uint256 count) external payable callerIsUser {
        require(publicMinted[msg.sender].add(count) <= 3, "max mint");
        require(publicSaleIsOpen == true, "Public mint is closed");
        uint256 totalPrice = publicPrice.mul(count);
        require(msg.value >= totalPrice, "Need to send more ETH.");
        require(totalSupply() + count <= collectionSize, "reached max supply");
        publicMinted[msg.sender] = publicMinted[msg.sender].add(count);
        _safeMint(msg.sender, count);
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setMerkleRoot(uint256 _allowlistPrice, bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
        allowlistPrice = _allowlistPrice;
    }

    function setAllowlistMintIsOpen(bool allowlistMintIsOpen_) public onlyOwner {
        allowlistMintIsOpen = allowlistMintIsOpen_;
    }

    function devMint(uint256 count) external onlyOwner {
        require(
            totalSupply().add(count) <= amountForDevs,
            "too many already minted before dev mint"
        );

        require(_numberMinted(msg.sender).add(count) <= amountForDevs, "too many dev mint");
        _safeMint(msg.sender, count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function _leaf(address account, uint256 amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, amount));
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPublicSaleIsOpen(bool value) external onlyOwner {
        publicSaleIsOpen = value;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        uint256 devAmount = contractBalance.div(100).mul(10);
        uint256 ownerAmount = contractBalance.sub(devAmount);

        _devWallet.transfer(devAmount);
        (bool success, ) = msg.sender.call{value: ownerAmount}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function remainingTokens() public view returns (uint256) {
        return collectionSize.sub(totalSupply());
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }
}