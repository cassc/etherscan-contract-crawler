/* SPDX-License-Identifier: MIT 

The Undead Army has arrived, what will the Human army do in response ?

*/
pragma solidity ^ 0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/ERC721A.sol";

contract UndeadArmy is ERC721A, EIP712, Ownable {
	using ECDSA
	for bytes32;
	using Strings
	for uint256;

	address whitelist_signer = 0x237f5b5A4C95317C5085e1e563727A84BC5204cd;

	bool public active = false;
    bool public publicMint = false;
	string public baseUri;
	uint256 public MAX_SUPPLY = 666;
    uint256 public AIRDROP_SUPPLY = 199;

	uint256 public publicMintFee = 0.02 ether;
	uint256 public wlMintFee = 0.01 ether;
	
	mapping( uint256 => uint256 ) private whitelistClaimBitMask;
	mapping( address => bool ) private addressMinted;
	mapping( address => uint256 ) private mintedAmount;

	constructor()
	ERC721A( "UndeadArmy", "UNDA" )
	EIP712( "UNDA", "1.0.0" ) {
	_safeMint(0x36d805A97A5F5De2c320E14032Fbd20B16d8d919, 1);

	}

	function whitelistmint( bytes calldata _signature, uint256 _nftIndex, uint256 _quantity ) external payable  mintCompliance() {
		uint256 _mintedAmount = mintedAmount[msg.sender];
    	require( !isClaimed(_nftIndex), "Whitelist Spot has been Claimed." );
		require(MAX_SUPPLY >= (totalSupply() + _quantity)+AIRDROP_SUPPLY,"SOLD OUT");

		require( _verify( _whitelistHash( msg.sender, _nftIndex ), _signature), "Signature Invalid" );


		require(_mintedAmount + _quantity <= 2, "You already minted 2");

		if(_quantity==1){
			require( msg.value >= wlMintFee , "ETH value isn't enough." );
		}
		else if(_quantity==2) {
			require( msg.value >= (wlMintFee+publicMintFee), "ETH value isn't enough." );

		}
		
	    _setClaimed( _nftIndex);		
        _mint( msg.sender, _quantity);
        mintedAmount[ msg.sender ] = _mintedAmount + _quantity;
	}

        function mint(uint256 _quantity) external payable mintCompliance(){
         require(publicMint, "Public Mint Not Open");  
         require(msg.value >= publicMintFee * _quantity, "NO MONEY");
                require(MAX_SUPPLY >= (totalSupply() + _quantity)+AIRDROP_SUPPLY,"SOLD OUT");
                uint256 _mintedAmount = mintedAmount[msg.sender];
                require(_mintedAmount + _quantity <= 2,"ONLY 2 PER ADDRESS MAX");
                mintedAmount[msg.sender] = _mintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
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

	function flipActive() external onlyOwner{

		active=!active;
	}

	function tokenURI( uint256 _tokenId ) public view virtual override returns( string memory ) {
		require( _exists( _tokenId ), "NFT: URI query for nonexistent token" );
		return bytes( baseUri )
			.length > 0 ? string( abi.encodePacked( baseUri, _tokenId.toString(), ".json" ) ) : "";
	}

	function setbaseUri( string memory newBaseURI ) external onlyOwner {
		baseUri = newBaseURI;
	}

    
    function airdrop() external onlyOwner{
             _safeMint(0x36d805A97A5F5De2c320E14032Fbd20B16d8d919, AIRDROP_SUPPLY);

    }

	function UnleashArmy() external onlyOwner {
		publicMint = !publicMint;
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
		require( tx.origin == msg.sender, "CALLER CANNOT BE A CONTRACT" );
		require(active, "SALE IS NOT ACTIVE");
        require( totalSupply() <= MAX_SUPPLY, "SOLD OUT" );
		_;
	}
}