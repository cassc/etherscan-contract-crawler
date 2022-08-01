// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";


//contract OwnableDelegateProxy {}
//contract ProxyRegistry {
//	mapping(address => OwnableDelegateProxy) public proxies;
//}


contract TNP is ERC721A, ReentrancyGuard, Ownable {
    string public _metadataURI = "";
    mapping(address => uint256) public mintedAmount;
    mapping(address => uint256) public claimedAmount;


    //constructor(string memory _customBaseURI, address _proxyRegistryAddress)
    constructor(string memory _customBaseURI)
	ERC721A( "Test-NFT-Pass", "TNP" ){
	    customBaseURI = _customBaseURI;
	    //proxyRegistryAddress = _proxyRegistryAddress;
    }


    uint256 public constant MAX_SUPPLY = 10000;


    uint256 public MAX_MULTIMINT = 3;
    function setMAX_MULTIMINT(uint256 _count) external onlyOwner {
	MAX_MULTIMINT = _count;
    }


    uint256 public PRICE_PUBLIC = 2000000000000000;
    function setPRICE_PUBLIC(uint256 _price) external onlyOwner {
	PRICE_PUBLIC = _price;
    }


    function mintGod(address _to, uint256 _count) external onlyOwner {
	require( totalSupply() + _count <= MAX_SUPPLY, "Exceeds max supply" );
	uint256 _mintedAmount = mintedAmount[_to];
	_mint( _to, _count );
	mintedAmount[_to] = _mintedAmount + _count;
    }


    uint256 public CLAIM_LIMIT = 1;
    function claim(uint256 _count) public isHuman() nonReentrant onlyWhitelisted {
	require( sale_IsActive, "Sale not active" );
	require( _count > 0, "0 tokens to mint" );
	require( totalSupply() + _count <= MAX_SUPPLY, "Exceeds max supply" );
	require( _count <= CLAIM_LIMIT, "Exceeds max AL mint per address" );
	require( _count <= MAX_MULTIMINT, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = mintedAmount[msg.sender];
	uint256 _claimedAmount = claimedAmount[msg.sender];
	require( _claimedAmount + _count <= CLAIM_LIMIT, "Exceeds max claims per address" );
	_mint(msg.sender, _count);
	mintedAmount[msg.sender] = _mintedAmount + _count;
	claimedAmount[msg.sender] = _claimedAmount + _count;
    }


    function mint(uint256 _count) public payable isHuman() nonReentrant {
	require( sale_IsActive, "Sale not active" );
	require( msg.value >= PRICE_PUBLIC * _count, "Insufficient payment"  );
	require( _count > 0, "0 tokens to mint" );
	require( totalSupply() + _count <= MAX_SUPPLY, "Exceeds max supply" );
	require( _count <= MAX_MULTIMINT, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = mintedAmount[msg.sender];
	_mint(msg.sender, _count);
	mintedAmount[msg.sender] = _mintedAmount + _count;
	// Cashback
	uint _random = random( 100 );
	if( _count == 2 && _random >= 70 ){
	    _withdraw( payable(msg.sender), msg.value );
	}
	if( _count == 3 && _random >= 50 ){
	    _withdraw( payable(msg.sender), msg.value );
	}
    }


    function _withdraw(address _address, uint256 _amount) private {
	(bool success, ) = _address.call{value: _amount}("");
	require(success, "Transfer failed.");
    }


    bool public sale_IsActive = false;
    function setSale_IsActive(bool _saleIsActive) external onlyOwner {
	sale_IsActive = _saleIsActive;
    }


    string private customBaseURI;
    function setBaseURI(string memory _customBaseURI) external onlyOwner {
	customBaseURI = _customBaseURI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
	return customBaseURI;
    }


    function withdraw() public nonReentrant onlyOwner {
	uint256 balance = address(this).balance;
	Address.sendValue(payable(owner()), balance);
    }


//    address private immutable proxyRegistryAddress;
//    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
//	ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
//	if (address(proxyRegistry.proxies(owner)) == operator) {
//	    return true;
//	}
//	return super.isApprovedForAll(owner, operator);
//    }


    /////////////////////////////////////////////////////////////////////////////////
    //
    // WhiteList
    //
    mapping(address => bool) private whitelist;
    function addWhitelist(address beneficiary) external onlyOwner{
	whitelist[beneficiary] = true;
    }
    function addManyWhitelist(address[] calldata beneficiary) external onlyOwner{
	for (uint i = 0; i < beneficiary.length; i++){
	    whitelist[beneficiary[i]] = true;
	}
    }
    function removeWhitelist(address beneficiary) external onlyOwner{
	whitelist[beneficiary] = false;
    }
    modifier onlyWhitelisted {
	require(whitelist[msg.sender]);
	_;
    }
    function checkWhitelist(address beneficiary) public view returns (bool) {
	if ( whitelist[beneficiary] ){
	    return true;
	} else {
	    return false;
	}
    }
    //
    /////////////////////////////////////////////////////////////////////////////////


    function random(uint number) public view returns(uint){
	uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp+block.difficulty+((uint256(keccak256(abi.encodePacked(block.coinbase))))/(block.timestamp))+block.gaslimit+((uint256(keccak256(abi.encodePacked(msg.sender))))/(block.timestamp))+block.number)));
	return (seed - ((seed / number) * number));
    }


    modifier isHuman() {
	address _addr = msg.sender;
	uint256 _codeLength;
	assembly {_codeLength := extcodesize(_addr)}
	require(_codeLength == 0, "sorry humans only");
	_;
    }
}