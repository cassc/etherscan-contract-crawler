// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract Hobozuki is ERC721A, ReentrancyGuard, Ownable {
    constructor(string memory _customBaseURI)

    ERC721A( "Hobozuki", "HOBOZ" ){
        customBaseURI = _customBaseURI;
    }


    enum mintTypes{ Closed, WL, Public, Free }
    mintTypes public mintType;
    function setMintType(mintTypes _mintType) external onlyOwner {
        mintType = _mintType;
    }
    function getMintType() public view returns (mintTypes) {
        return mintType;
    }


    uint256 public MAX_SUPPLY = 10000;
    function setConfig(uint256 _count) external onlyOwner {
	MAX_SUPPLY = _count;
    }
    uint256 public WL_SUPPLY = 2000;
    function setConfigWL(uint256 _count) external onlyOwner {
	WL_SUPPLY = _count;
    }


    uint256 public MAX_MULTIMINT = 5;
    function setMAX_MULTIMINT(uint256 _count) external onlyOwner {
	MAX_MULTIMINT = _count;
    }
    uint256 public MAX_MULTIMINT_WL = 3;
    function setMAX_MULTIMINT_WL(uint256 _count) external onlyOwner {
	MAX_MULTIMINT_WL = _count;
    }
    uint256 public LIMIT_PER_WALLET = 5;
    function setLIMIT_PER_WALLET(uint256 _count) external onlyOwner {
	LIMIT_PER_WALLET = _count;
    }
    uint256 public LIMIT_PER_WALLET_WL = 3;
    function setLIMIT_PER_WALLET_WL(uint256 _count) external onlyOwner {
    LIMIT_PER_WALLET_WL = _count;
    }


    uint256 public PRICE = 0.0079 ether;
    function setPRICE(uint256 _price) external onlyOwner {
	PRICE = _price;
    }
    uint256 public PRICE_WL = 0.0059 ether;
    function setPRICE_WL(uint256 _price) external onlyOwner {
	PRICE_WL = _price;
    }


    bytes32 public merkleRoot;
    function setRoot(bytes32 _root) external onlyOwner {
	merkleRoot = _root;
    }
    function isValid(bytes32[] memory proof) public view returns (bool) {
	bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
	return MerkleProof.verify(proof, merkleRoot, leaf);
    }


    function mintDrop(address _to, uint256 _count) external onlyOwner {
	require( totalSupply() + _count <= MAX_SUPPLY, "Exceeds max supply" );
	_mint( _to, _count );
    }


    function mintWL(uint256 _count, bytes32[] memory _proof) public payable nonReentrant {
	bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
	require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof!");

	require( mintType == mintTypes.WL, "WL Sale not active" );
	require( msg.value >= PRICE_WL * _count, "Insufficient payment"  );
	require( _count > 0, "0 tokens to mint" );
	require( totalSupply() + _count <= WL_SUPPLY, "Exceeds WL max supply" );
	require( totalSupply() + _count <= MAX_SUPPLY, "Exceeds max supply" );
	require( _count <= MAX_MULTIMINT_WL, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = balanceOf(msg.sender);
	require( _mintedAmount + _count <= LIMIT_PER_WALLET_WL, "Exceeds max mints per wallet" );
	_mint(msg.sender, _count);
    }


    function mint(uint256 _count) public payable nonReentrant {
	require( mintType == mintTypes.Public, "Sale not active" );
	require( msg.value >= PRICE * _count, "Insufficient payment"  );
	require( _count > 0, "0 tokens to mint" );
	require( totalSupply() + _count <= MAX_SUPPLY, "Exceeds max supply" );
	require( _count <= MAX_MULTIMINT, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = balanceOf(msg.sender);
	require( _mintedAmount + _count <= LIMIT_PER_WALLET, "Exceeds max mints per wallet" );
	_mint(msg.sender, _count);
    }


    function mintFree(uint256 _count) public nonReentrant {
	require( mintType == mintTypes.Free, "Sale not active" );
	require( _count > 0, "0 tokens to mint" );
	require( totalSupply() + _count <= MAX_SUPPLY, "Exceeds max supply" );
	require( _count <= MAX_MULTIMINT, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = balanceOf(msg.sender);
	require( _mintedAmount + _count <= LIMIT_PER_WALLET, "Exceeds max mints per wallet" );
	_mint(msg.sender, _count);
    }


    string private customBaseURI;
    function setBaseURI(string memory _URI) external onlyOwner {
	customBaseURI = _URI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
	return customBaseURI;
    }


    function withdraw() external onlyOwner {
	uint256 balance = address(this).balance;
	Address.sendValue(payable(owner()), balance);
    }
    function withdrawAmount(uint256 _amount) external onlyOwner {
	Address.sendValue(payable(owner()), _amount);
    }


    function multiSend(address[] calldata _recipients, uint256[] calldata _ids) external {
	require(_recipients.length == _ids.length, "_recipients and _ids not equal");
	for (uint256 i = 0; i < _recipients.length; i++) {
	    safeTransferFrom(msg.sender, _recipients[i], _ids[i]);
	}
    }


    modifier isHuman() {
	address _addr = msg.sender;
	uint256 _codeLength;
	assembly {_codeLength := extcodesize(_addr)}
	require(_codeLength == 0, "sorry humans only");
	_;
    }
    modifier callerIsUser() {
	require( msg.sender == tx.origin, "sorry users only");
	_;
    }


}