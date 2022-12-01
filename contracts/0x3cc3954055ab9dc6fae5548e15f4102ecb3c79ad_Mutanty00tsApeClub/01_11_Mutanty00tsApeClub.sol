// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC721A } from "erc721a/contracts/IERC721A.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { ERC721AQueryable } from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { OperatorFilterer } from "./OperatorFilterer.sol";

contract Mutanty00tsApeClub is ERC721A, ERC721AQueryable, OperatorFilterer(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6, true), Ownable {
    
    using ECDSA for bytes32;
    using Strings for uint256;
    bool public MintingPublic  = false;
    bool public MintingHolder  = false;
    string public baseURI;  
    address public signer;
    uint256 public maxPerTransaction = 20;  
    uint256 public pricePublic = 6900000000000000;
    uint256 public priceHolder = 4200000000000000;
    mapping (address => uint256) public walletPublic;
    mapping (address => uint256) public walletHolder ;
    mapping (address => bool) public holderClaim;
    uint256 public maxSupply = 10000;
    uint256 public maxHolder = 3484;
    uint256 public maxPublic = 6416;
    bool public operatorFilteringEnabled = true;

    constructor() ERC721A("Mutant y00ts Ape Club", "MYAC"){}

    function publicMint(uint256 qty) external payable 
    {
        require(MintingPublic , "MYAC isMintingStart Not Open Yet !");
        require(qty <= maxPerTransaction, "MYAC Max Per Max Per Transaction !");
        require(totalSupply() + qty <= maxPublic,"MYAC Soldout !");
        require(msg.value >= qty * pricePublic,"MYAC Insufficient Funds !");
        walletPublic[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function y00tapeHolderMint(uint256 qty, bytes memory signature) external payable 
    { 
        require(MintingHolder, "MYAC isMintingStart Not Open Yet !");
        require(qty <= maxPerTransaction, "MYAC Max Per Max Per Transaction !");
        require(totalSupply() + qty <= maxHolder,"MYAC Soldout !");
        require(msg.value >= qty * priceHolder,"MYAC Insufficient Eth");
        require(isMessageValid(signature,qty),"MYAC Not Holder !");
        walletHolder[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function y00tapeHolderClaim(uint256 qty, bytes memory signature) external payable 
    { 
        require(MintingHolder, "MYAC isMintingStart Not Open Yet !");
        require(holderClaim[msg.sender] == false,"MYAC Claimed");
        require(totalSupply() + qty <= maxHolder,"MYAC Soldout !");
        require(isMessageValid(signature,qty),"MYAC Not Holder !");
        holderClaim[msg.sender] = true;
        walletHolder[msg.sender] += qty;
        _safeMint(msg.sender, qty);
    }

    function airdrop(address[] memory listedAirdrop ,uint256[] memory qty) external onlyOwner {
        for (uint256 i = 0; i < listedAirdrop.length; i++) {
           _safeMint(listedAirdrop[i], qty[i]);
        }
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function teamMint(uint256 qty) external onlyOwner
    {
        _safeMint(msg.sender, qty);
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
        priceHolder = priceHolder_;
    }

    function setmaxPerTransaction(uint256 maxPerTransaction_) external onlyOwner {
        maxPerTransaction = maxPerTransaction_;
    }

    function setPublicSupply(uint256 maxPublic_) external onlyOwner {
        maxPublic = maxPublic_;
    }

    function setHolderSupply(uint256 maxHolder_) external onlyOwner {
        maxHolder = maxHolder_;
    }

    function setWalletMint(address addr_) external onlyOwner {
        walletPublic[addr_] = 0;
        walletHolder[addr_] = 0;
        holderClaim[addr_] = false;
    }

    function setOperatorFilteringEnabled(bool _value) external onlyOwner {
        operatorFilteringEnabled = _value;
    }

    function isMessageValid(bytes memory _signature, uint256 amount) public view returns (bool)
    {
        bytes32 messagehash = keccak256(abi.encodePacked(address(this), msg.sender,amount));
        address _signer = messagehash.toEthSignedMessageHash().recover(_signature);
        if (signer == _signer) {
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