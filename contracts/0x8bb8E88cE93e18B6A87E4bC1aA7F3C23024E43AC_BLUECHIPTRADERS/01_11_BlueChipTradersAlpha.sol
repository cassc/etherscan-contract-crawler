/*
SPDX-License-Identifier: MIT


*/
pragma solidity ^ 0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/ERC721A.sol";

contract BLUECHIPTRADERS is ERC721A, EIP712, Ownable {
	using ECDSA
	for bytes32;
	using Strings
	for uint256;

	address whitelist_signer = 0x91c4268A3e251B9784A9037d96c83fFDD23Dd6Cd;


	string public baseUri;
	bool public ActiveContract = false;

	uint256 public MAX_SUPPLY = 3333;
	uint256 public FREE_SUPPLY = 333;

	uint256 public MaxPerWallet = 10;

	uint256 public mintFee = 0.007 ether;

//	mapping( uint256 => uint256 ) private allowlistClaimBitMask;
	mapping( uint256 => uint256 ) private whitelistClaimBitMask;
	mapping( address => bool ) private addressMinted;
	mapping( address => uint256 ) private mintedAmount;

	constructor()
	ERC721A( "BLUECHIPTRADERS", "BCT" )
	EIP712( "BCT", "1.0.0" ) {
	}

	function whitelistmint( bytes calldata _signature, uint256 _nftIndex, uint256 _quantity ) external payable  mintCompliance() {
		require(totalSupply()<FREE_SUPPLY, "FREE SUPPLY SOLD OUT");
    	require( !isClaimed(_nftIndex), "WL MINT ALREADY CLAIMED" );
		require( _verify( _whitelistHash( msg.sender, _nftIndex ), _signature), "WL INVALID SIGNATURE" );
		uint256 _mintedAmount = mintedAmount[ msg.sender ];
	    _setClaimed( _nftIndex);
        require( msg.value >= mintFee * ( _quantity - 1 ), "NOT ENOUGH ETH TO MINT" );
		_mint( msg.sender, 1);
		mintedAmount[ msg.sender ] = _mintedAmount + _quantity;
	}

    function publicMint(address _to, uint256 _quantity) external payable mintCompliance() {
        uint256 _mintedAmount = mintedAmount[ msg.sender ];
        require(msg.value >= mintFee * _quantity, "No ETH, this isn't free mfer.");
        require( _mintedAmount + _quantity <= MaxPerWallet, "MAX PER WALLET REACHED" );
        _mint(_to, _quantity);
        mintedAmount[ msg.sender ] = _mintedAmount + _quantity;
    }

	function isClaimed( uint256 _nftIndex) public view returns( bool ) {
		uint256 wordIndex = _nftIndex / 256;
		uint256 bitIndex = _nftIndex % 256;
		uint256 mask = 1 << bitIndex;
	return whitelistClaimBitMask[ wordIndex ] & mask == mask;
	
	}

	function _setClaimed( uint256 _nftIndex) internal {
		uint256 wordIndex = _nftIndex / 256;
		uint256 bitIndex = _nftIndex % 256;
		uint256 mask = 1 << bitIndex;
		whitelistClaimBitMask[ wordIndex ] |= mask;
		
	}

	function _hash( address _account, uint256 _nftIndex, uint256 _quantity )
	internal view returns( bytes32 ) {
		return _hashTypedDataV4( keccak256( abi.encode( keccak256( "NFT(address _account,uint256 _nftIndex,uint256 _quantity)" ), _account, _nftIndex, _quantity ) ) );
	}

	function _whitelistHash( address _account, uint256 _nftIndex )
	internal view returns( bytes32 ) {
		return _hashTypedDataV4( keccak256( abi.encode( keccak256( "NFT(address _account,uint256 _nftIndex)" ), _account, _nftIndex ) ) );
	}

	function _verify( bytes32 digest, bytes memory signature)
	internal view returns( bool ) {
	    return SignatureChecker.isValidSignatureNow( whitelist_signer, digest, signature );
		
	}

	function _baseURI() internal view virtual override returns( string memory ) {
		return baseUri;
	}

	function tokenURI( uint256 _tokenId ) public view virtual override returns( string memory ) {
		require( _exists( _tokenId ), "NFT: URI query for nonexistent token" );
		return bytes( baseUri )
			.length > 0 ? string( abi.encodePacked( baseUri, _tokenId.toString(), ".json" ) ) : "";
	}

	function setbaseUri( string memory newBaseURI ) external onlyOwner {
		baseUri = newBaseURI;
	}
	
	function ActivateSale() public onlyOwner {
		ActiveContract = !ActiveContract;
	}

    function burnSupply() external onlyOwner {   
        MAX_SUPPLY = totalSupply();
        
    }

	function withdraw() public onlyOwner {
		( bool os, ) = payable( owner() )
			.call {
				value: address( this )
					.balance
			}( "" );
		require( os );
	}
    
	modifier mintCompliance() {
		require( ActiveContract, "Sale is not active yet." );
		require( tx.origin == msg.sender, "Caller cannot be a contract." );
        require( totalSupply() <= (MAX_SUPPLY-FREE_SUPPLY), "SOLD OUT" );
		_;
	}
}