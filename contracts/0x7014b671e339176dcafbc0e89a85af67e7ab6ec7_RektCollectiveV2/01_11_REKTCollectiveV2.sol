/*
SPDX-License-Identifier: MIT

V2 of REKT Collective Pass
Original Collection: https://opensea.io/collection/rekt-collective

Total Supply: 555

Twitter: @rektcollective
Discord: rektcollective



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

contract RektCollectiveV2 is ERC721A, EIP712, Ownable {
	using ECDSA
	for bytes32;
	using Strings
	for uint256;

	address whitelist_signer = 0x05Ecbc677D092e9E3C39230A2Cd6F6fDE26E660D;


	string public baseUri;
	uint256 public MAX_SUPPLY = 555;
	uint256 public MaxPerWallet = 1;
	uint256 public mintFee = 0.03 ether;



	mapping( uint256 => uint256 ) private whitelistClaimBitMask;
	mapping( address => bool ) private addressMinted;
	mapping( address => uint256 ) private mintedAmount;

	constructor()
	ERC721A( "REKTCOLLECTIVEv2", "REKT2" )
	EIP712( "REKT", "1.0.0" ) {
	}

	function whitelistmint( bytes calldata _signature, uint256 _nftIndex, uint256 _quantity ) external payable  mintCompliance() {
    	require( !isClaimed(_nftIndex), "REKT. Whitelist Spot has been Claimed." );
		require( _verify( _whitelistHash( msg.sender, _nftIndex ), _signature), "REKT, Signature Invalid" );
		 require( msg.value >= mintFee * ( _quantity - 1 ), "REKT, no liquidity." );

		uint256 _mintedAmount = mintedAmount[ msg.sender ];
	    _setClaimed( _nftIndex);
		_mint( msg.sender, (_quantity=1));
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
		require( tx.origin == msg.sender, "Caller cannot be a contract." );
        require( totalSupply() <= MAX_SUPPLY, "Sold out, mfers." );
		_;
	}
}