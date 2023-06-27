// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract SwampPotions is ERC721A, ReentrancyGuard, Ownable, ERC2981 {
    constructor(string memory _customBaseURI) ERC721A( "Swamp Potions", "SP" ){
        customBaseURI = _customBaseURI;
	_setDefaultRoyalty(msg.sender, 700);
    }

    uint256 public supplyMax = 1001;
    uint256 public supplyWL = 0;
    uint256 public supplySW = 0;
    uint256 public limitTx = 3;
    uint256 public limitWallet = 3;
    uint256 public price = 0.024 ether;
    uint256 public priceWL = 0 ether;
    uint256 public priceSW = 0 ether;

    bool public frozen = false;
    bool public burnable = false;
    bytes32 public merkleRoot;
    bytes32 public merkleRootSW;
    enum mintTypes{ Closed, WL, SW, Public, Free }
    string private customBaseURI;

    function mint(uint256 _count) public payable nonReentrant {
	require( mintType == mintTypes.Public, "Sale not active" );
	require( msg.value >= price * _count, "Insufficient payment"  );
	require( _count > 0, "Zero tokens to mint" );
	require( totalSupply() + _count <= supplyMax, "Exceeds max supply" );
	require( _count <= limitTx, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = balanceOf(msg.sender);
	require( _mintedAmount + _count <= limitWallet, "Exceeds max mints per wallet" );
	_mint(msg.sender, _count);
    }
    function mintWL(uint256 _count, bytes32[] memory _proof) public payable nonReentrant {
	bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
	require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof!");
	require( mintType == mintTypes.WL, "WL Sale not active" );
	require( msg.value >= priceWL * _count, "Insufficient payment"  );
	require( _count > 0, "Zero tokens to mint" );
	require( totalSupply() + _count <= supplyWL, "Exceeds WL max supply" );
	require( totalSupply() + _count <= supplyMax, "Exceeds max supply" );
	require( _count <= limitTx, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = balanceOf(msg.sender);
	require( _mintedAmount + _count <= limitWallet, "Exceeds max mints per wallet" );
	_mint(msg.sender, _count);
    }
    function mintSW(uint256 _count, bytes32[] memory _proof) public payable isHuman() nonReentrant {
	bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
	require(MerkleProof.verify(_proof, merkleRootSW, leaf), "Invalid proof!");
	require( mintType == mintTypes.SW, "SW Sale not active" );
	require( msg.value >= priceSW * _count, "Insufficient payment"  );
	require( _count > 0, "Zero tokens to mint" );
	require( totalSupply() + _count <= supplySW, "Exceeds WL max supply" );
	require( totalSupply() + _count <= supplyMax, "Exceeds max supply" );
	require( _count <= limitTx, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = balanceOf(msg.sender);
	require( _mintedAmount + _count <= limitWallet, "Exceeds max mints per wallet" );
	_mint(msg.sender, _count);
    }
    function mintFree(uint256 _count) public nonReentrant {
	require( mintType == mintTypes.Free, "Sale not active" );
	require( _count > 0, "Zero tokens to mint" );
	require( totalSupply() + _count <= supplyMax, "Exceeds max supply" );
	require( _count <= limitTx, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = balanceOf(msg.sender);
	require( _mintedAmount + _count <= limitWallet, "Exceeds max mints per wallet" );
	_mint(msg.sender, _count);
    }
    function freeze() external onlyOwner {
	frozen = true;
    }
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
	require( !frozen, "Transfers frozen" );
	super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
    function allowBurn() external onlyOwner {
	burnable = true;
    }
    function burn(uint256 tokenId) public {
	require( burnable, "Burn mode off" );
	require( msg.sender == ownerOf(tokenId), "caller is not owner" );
	super._burn(tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
	return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId); //return super.supportsInterface(interfaceId);
    }
    mintTypes public mintType;
    function setMintType(mintTypes _mintType) external onlyOwner {
        mintType = _mintType;
    }
    function getMintType() public view returns (mintTypes) {
        return mintType;
    }
    function setConfig(uint256 _count) external onlyOwner {
	supplyMax = _count;
    }
    function setConfigWL(uint256 _count) external onlyOwner {
	supplyWL = _count;
    }
    function setConfigSW(uint256 _count) external onlyOwner {
	supplySW = _count;
    }
    function setLimitTx(uint256 _count) external onlyOwner {
	limitTx = _count;
    }
    function setLimitWallet(uint256 _count) external onlyOwner {
	limitWallet = _count;
    }
    function setPrice(uint256 _price) external onlyOwner {
	price = _price;
    }
    function setPriceWL(uint256 _price) external onlyOwner {
	priceWL = _price;
    }
    function setPriceSW(uint256 _price) external onlyOwner {
	priceSW = _price;
    }
    function setRoot(bytes32 _root) external onlyOwner {
	merkleRoot = _root;
    }
    function setRootSW(bytes32 _root) external onlyOwner {
	merkleRootSW = _root;
    }
    function isValid(bytes32[] memory proof) public view returns (bool) {
	bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
	return MerkleProof.verify(proof, merkleRoot, leaf);
    }
    function isValidSW(bytes32[] memory proof) public view returns (bool) {
	bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
	return MerkleProof.verify(proof, merkleRootSW, leaf);
    }
    function mintDrop(address _to, uint256 _count) external onlyOwner {
	require( totalSupply() + _count <= supplyMax, "Exceeds max supply" );
	_mint( _to, _count );
    }
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
    function setDefaultRoyalty(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(msg.sender, feeNumerator);
    }
    function swampDrop(address[] calldata _recipients, uint256[] calldata _ids) external {
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