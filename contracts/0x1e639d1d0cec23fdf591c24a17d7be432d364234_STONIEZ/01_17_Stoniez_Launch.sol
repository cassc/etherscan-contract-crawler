// SPDX-License-Identifier: MIT

//$$$$$$\ $$$$$$$$\  $$$$$$\  $$\   $$\ $$$$$$\ $$$$$$$$\ $$$$$$$$\
//$$  __$$\\__$$  __|$$  __$$\ $$$\  $$ |\_$$  _|$$  _____|\____$$  |
//$$ /  \__|  $$ |   $$ /  $$ |$$$$\ $$ |  $$ |  $$ |          $$  /
///$$$$$$\    $$ |   $$ |  $$ |$$ $$\$$ |  $$ |  $$$$$\       $$  /
///\____$$\   $$ |   $$ |  $$ |$$ \$$$$ |  $$ |  $$  __|     $$  /
//$$\   $$ |  $$ |   $$ |  $$ |$$ |\$$$ |  $$ |  $$ |       $$  /
//\$$$$$$  |  $$ |    $$$$$$  |$$ | \$$ |$$$$$$\ $$$$$$$$\ $$$$$$$$\
//\______/   \__|    \______/ \__|  \__|\______|\________|\________|


// ERC721A Smart Contract for Stoniez

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./ERC721A.sol"; //
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

contract STONIEZ is ERC721A, Ownable, DefaultOperatorFilterer  {
  using SafeMath for uint256;
	using Strings for uint256;
    bytes32 public merkleRoot;
    bytes32 public vipMerkleRoot;
    uint256 public MAX_SUPPLY= 10000;
	  uint256 public MAX_WL_SUPPLY = 1000;
    uint256 public MAX_VIPWL_SUPPLY = 10000;
    uint256 public WL_PRICE = 0.09 ether;
    uint256 public VIPWL_PRICE = 0.09 ether;
    uint256 public PRICE = 0.098 ether;
    uint256 public giveawayLimit = 10000;
    string public baseTokenURI;
    bool public whitelistSaleIsActive;
    bool public saleIsActive;
    address private wallet1 = 0x723cDF2c53c446A9f5F96638Aaa872069c819A3B; // Wallet 1 - 80%
    address private wallet2 = 0x1e33d0366fD2B78C2f23C3A53771A84E38D5B4B4; // Wallet 2 - 10%
    address private wallet3 = 0x7D1bD8418C785A508374C60FdFCa9401F8B02007; // Wallet 3 - 10%
    address public Authorized = 0x7a29d9a21A45E269F1bFFFa15a84c16BA0050E27; // Dev Wallet for Testing (no percentage)

    uint256 public maxPurchase = 3;
    uint256 public maxWLPurchase = 1;
    uint256 public maxVIPPurchase = 3;
	  uint256 public maxTxWL = 1;
	  uint256 public maxTxVIP = 3;
    uint256 public maxTx = 3;

    constructor() ERC721A("STONIEZ", "STONIEZ") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyAuthorized {
        require(msg.sender == owner() || msg.sender == Authorized , "Not authorized");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipWhitelistSaleState() external onlyOwner {
        whitelistSaleIsActive = !whitelistSaleIsActive;
    }

    function updateMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function updateVIPMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        vipMerkleRoot = newMerkleRoot;
    }

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
		string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : "";
    }

	function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function whitelistMint(uint256 numberOfTokens, bytes32[] calldata merkleProof ) payable external callerIsUser {
        require(whitelistSaleIsActive, "Whitelist Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_WL_SUPPLY, "Total WL Supply has been minted");
        require(numberOfTokens > 0 && numberOfTokens <= maxTxWL, "Can only mint upto 1 NFTs in a transaction");
        require(msg.value == WL_PRICE.mul(numberOfTokens), "Ether value sent is not correct");
        require(numberMinted(msg.sender).add(numberOfTokens) <= maxWLPurchase,"Exceeds Max mints allowed per whitelisted wallet");

        // Verify the merkle proof
        require(MerkleProof.verify(merkleProof, merkleRoot,  keccak256(abi.encodePacked(msg.sender))  ), "Invalid proof");

		_safeMint(msg.sender, numberOfTokens);
    }

    function vipMint(uint256 numberOfTokens, bytes32[] calldata merkleProof ) payable external callerIsUser {
        require(whitelistSaleIsActive, "Whitelist Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_VIPWL_SUPPLY, "Total VIPWL Supply has been minted");
        require(numberOfTokens > 0 && numberOfTokens <= maxTxVIP, "Can only mint max NFTs in a transaction");
        require(msg.value == VIPWL_PRICE.mul(numberOfTokens), "Ether value sent is not correct");
        require(numberMinted(msg.sender).add(numberOfTokens) <= maxVIPPurchase,"Exceeds Max mints allowed per whitelisted wallet");

        // Verify the merkle proof
        require(MerkleProof.verify(merkleProof, vipMerkleRoot,  keccak256(abi.encodePacked(msg.sender))  ), "Invalid proof");

		_safeMint(msg.sender, numberOfTokens);
    }

    function mint(uint256 numberOfTokens) external payable callerIsUser {
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply().add(numberOfTokens) <= MAX_SUPPLY, "Total Supply has been minted");
        require(msg.value == PRICE.mul(numberOfTokens), "Ether value sent is not correct");
		require(numberOfTokens > 0 && numberOfTokens <= maxTx, "1 pTX allowed");
        require(numberMinted(msg.sender).add(numberOfTokens) <= maxPurchase,"Exceeds Max mints allowed per wallet");

        _safeMint(msg.sender, numberOfTokens);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

	    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No balance");
        uint256 _amount = address(this).balance;
        (bool wallet1Success, ) = wallet1.call{value: _amount.mul(80).div(100)}("");
        (bool wallet2Success, ) = wallet2.call{value: _amount.mul(10).div(100)}("");
        (bool wallet3Success, ) = wallet3.call{value: _amount.mul(10).div(100)}("");
        require(wallet1Success && wallet2Success && wallet3Success,"Withdrawal failed.");
    }

    function giveAway(uint256 numberOfTokens, address to) external onlyOwner {
        require(giveawayLimit.sub(numberOfTokens) >= 0,"Giveaways exhausted");
        _safeMint(to, numberOfTokens);
        giveawayLimit = giveawayLimit.sub(numberOfTokens);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setMaxSupply(uint256 _mxSupply) public onlyAuthorized {
        MAX_SUPPLY = _mxSupply;
    }

    function setWLMaxSupply(uint256 _mxWLSupply) public onlyAuthorized {
        MAX_WL_SUPPLY = _mxWLSupply;
    }

    function setVIPMaxSupply(uint256 _mxVIPSupply) public onlyAuthorized {
        MAX_VIPWL_SUPPLY = _mxVIPSupply;
    }

    function setPriceWL(uint256 _wlPrice) public onlyAuthorized {
        WL_PRICE = _wlPrice;
    }

    function setPriceVIPWL(uint256 _vipwlPrice) public onlyAuthorized {
        VIPWL_PRICE = _vipwlPrice;
    }

    function setPrice(uint256 _price) public onlyAuthorized {
        PRICE = _price;
    }

    function setMaxTxLimit(uint256 _txLimit) public onlyAuthorized {
        maxTx = _txLimit;
    }

	function setMaxTxWL(uint256 _txLimit) public onlyAuthorized {
        maxTxWL = _txLimit;
    }

	function setMaxTxVIP(uint256 _txLimit) public onlyAuthorized {
        maxTxVIP = _txLimit;
    }

    function setMaxPurchaseLimit(uint256 _limit) public onlyAuthorized {
        maxPurchase = _limit;
    }

    function setMaxWLPurchaseLimit(uint256 _limit) public onlyAuthorized {
        maxWLPurchase = _limit;
    }

    function setMaxVIPPurchaseLimit(uint256 _limit) public onlyAuthorized {
        maxVIPPurchase = _limit;
    }

    /*
  --Opensea Filterer--
  */

        function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
            super.transferFrom(from, to, tokenId);
        }

        function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
            super.safeTransferFrom(from, to, tokenId);
        }

        function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
            public
            override
            onlyAllowedOperator(from)
        {
            super.safeTransferFrom(from, to, tokenId, data);
        }

}