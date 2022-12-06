// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC721A } from "erc721a/contracts/IERC721A.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { ERC721AQueryable } from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { OperatorFilterer } from "./OperatorFilterer.sol";

contract Mutanty00tsApeClub is ERC721A, ERC721AQueryable, OperatorFilterer(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true), Ownable {
    
    using ECDSA for bytes32;
    using Strings for uint256;
    bool public MintingPublic = false;
    bool public MintingWhitelist = false;
    bool public MintingHolder = false;
    string public baseURI;  
    bytes32 public merkleRoot;
    address public signerHolder;
    uint256 public maxPerTransaction = 20;  
    uint256 public pricePublic = 6900000000000000;
    uint256 public priceWhitelist = 4200000000000000;
    mapping (address => uint256) public walletPublic;
    mapping (address => uint256) public walletWhitelist;
    mapping (address => uint256) public walletHolder;
    mapping (address => bool) public holderClaim;
    uint256 public publicMinted = 0;
    uint256 public whitelistMinted = 0;
    uint256 public HolderMinted = 0;
    uint256 public maxSupply = 10000;
    uint256 public maxHolder = 2967;
    uint256 public maxPublic = 6933;
    uint256 public maxWhitelist = 6933;
    bool public operatorFilteringEnabled = true;

    constructor() ERC721A("Mutant y00ts Ape Club", "MYAC"){}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function y00tsapePublicMint(uint256 qty) external payable 
    {
        require(MintingPublic , "MYAC Minting Public Not Open Yet !");
        require(qty <= maxPerTransaction, "MYAC Max Per Max Per Transaction !");
        require(totalSupply() + qty <= maxSupply,"MYAC Soldout !");
        require(publicMinted + whitelistMinted + qty <= maxPublic,"MYAC Soldout !");
        require(msg.value >= qty * pricePublic,"MYAC Insufficient Funds !");
        walletPublic[msg.sender] += qty;
        publicMinted += qty;
        _safeMint(msg.sender, qty);
    }

    function y00tapeWhitelistMint(uint256 qty, bytes32[] calldata _merkleProof) external payable 
    { 
        require(MintingWhitelist, "MYAC Minting Whitelist Not Open Yet !");
        require(qty <= maxPerTransaction, "MYAC Max Per Max Per Transaction !");
        require(totalSupply() + qty <= maxSupply,"MYAC Soldout !");
        require(publicMinted + whitelistMinted + qty <= maxWhitelist,"MYAC Soldout !");
        require(msg.value >= qty * priceWhitelist,"MYAC Insufficient Funds !");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "MYAC Not y00tapelist !");
        walletWhitelist[msg.sender] += qty;
        whitelistMinted += qty;
        _safeMint(msg.sender, qty);
    }

    function y00tapeHolderClaim(uint256 qty, bytes memory signature) external payable 
    { 
        require(MintingHolder, "MYAC Claim Holder Not Open Yet !");
        require(holderClaim[msg.sender] == false,"MYAC Claimed !");
        require(totalSupply() + qty <= maxSupply,"MYAC Soldout !");
        require(HolderMinted <= maxHolder,"MYAC Soldout !");
        require(isMessageValidHolder(signature,qty),"MYAC Not Holder !");
        holderClaim[msg.sender] = true;
        walletHolder[msg.sender] += qty;
        HolderMinted += qty;
        _safeMint(msg.sender, qty);
    }

    function airdrop(address[] memory listedAirdrop ,uint256[] memory qty) external onlyOwner {
        for (uint256 i = 0; i < listedAirdrop.length; i++) {
           _safeMint(listedAirdrop[i], qty[i]);
        }
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setSignerHolder(address _signer) external onlyOwner {
        signerHolder = _signer;
    }

    function teamMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
    }

    function setWhitelistisMintingStart() external onlyOwner {
        MintingWhitelist  = !MintingWhitelist ;
    }

    function setPublicisMintingStart() external onlyOwner {
        MintingPublic  = !MintingPublic ;
    }

    function setHolderisMintingStart() external onlyOwner {
        MintingHolder  = !MintingHolder ;
    }
    
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPricePublic(uint256 price_) external onlyOwner {
        pricePublic = price_;
    }

    function setPriceHolder(uint256 priceHolder_) external onlyOwner {
        priceWhitelist = priceHolder_;
    }

    function setmaxPerTransaction(uint256 maxPerTransaction_) external onlyOwner {
        maxPerTransaction = maxPerTransaction_;
    }

    function setPublicSupply(uint256 maxPublic_) external onlyOwner {
        maxPublic = maxPublic_;
    }

    function setWhitelistSupply(uint256 maxWhitelist_) external onlyOwner {
        maxWhitelist = maxWhitelist_;
    }

    function setHolderSupply(uint256 maxHolder_) external onlyOwner {
        maxHolder = maxHolder_;
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setWalletMint(address addr_) external onlyOwner {
        walletPublic[addr_] = 0;
        walletHolder[addr_] = 0;
        walletWhitelist[addr_] = 0;
        holderClaim[addr_] = false;
    }

    function setOperatorFilteringEnabled(bool _value) external onlyOwner {
        operatorFilteringEnabled = _value;
    }

    function isMessageValidHolder(bytes memory _signature, uint256 amount) public view returns (bool)
    {
        bytes32 messagehash = keccak256(abi.encodePacked(address(this), msg.sender,amount));
        address _signer = messagehash.toEthSignedMessageHash().recover(_signature);
        if (signerHolder == _signer) {
            return true;
        } else {
            return false;
        }
    }

    function EmergencyWithdraw() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }("");
        require(success, "Transfer failed");
    }
    
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    function approve(address to, uint256 tokenId) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperatorApproval(to, operatorFilteringEnabled) {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator, operatorFilteringEnabled) {
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from, operatorFilteringEnabled) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}