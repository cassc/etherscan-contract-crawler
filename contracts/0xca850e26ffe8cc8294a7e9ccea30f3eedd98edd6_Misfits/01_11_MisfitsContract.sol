/*
SPDX-License-Identifier: MIT

They call us misfits, they say we don't belong....but we belong here, 
in web 3, between thesewe lines of codes and amazing people.

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
***********************************#@&%%&%%%%@%@\*******************************
*********************************%&&&&&&@&%%%%&@%&%*****************************
*******************************&&@%%%(@\%%@\\\\\\,@%****************************
******************************#&&&&@###\@\\\\\\,,\\@****************************
******************************#@%##\\\# (*%\\\% @ \\%***************************
*******************************.\(((##%   #\\\(. &\\,@**************************
******************************@\#\\\\\\\@\,@@@@\**#\,@**************************
*******************************(#((\\\\*@, , % , @*\****************************
**********************************%\\\\@*@ % @ ,@*\*****************************
************************************@#(\\\(&((@\&*******************************
*****************************************#%(************************************
*****************************************(\(@***********************************
************************************%#%&&(\\@%%@%@******************************
**********************************#%%%@@\\\\\,@\%%@*****************************
*******************************#%\\[email protected]@%@\####(#[email protected]@****************************
***************************@\&%\@...(\.*.\*,#(((& *( @@\***********************
***********************\*#(@[email protected]@(((@(.**.**.** *#..#%%%*@********************
*********************\***.\\\...\#(@,*%*@&%* @...,*(((%%,%%%@*******************
**********************%...&@\\,.%\@&(%,@.\%( &[email protected](*@@%%%%%%. @@*****************
********************@(#@..\@@.\(,@ *.....\#\@,..\#%%%%%%%&*(@[email protected]****************
*******************@*\*......(\  ,@ @....\&##%@     @%\%@#.((..\****************
********************@*@\...#*.#(\\*&[email protected]\   @*   @&%...\*[email protected]@***************
******************@(*..\@*.\@@@\**********(((@@@@       *\@*\*#..%**************
******************,,\,@...\#@**\@&#***&((((((\##&\\, ,%(@**@@\*@*,**************
*****************@#,@,@@@,(#@*******(((((\@(#((((@\((@& ****#\(@ @**************
*****************#,,,,((%@@##*@*[email protected]@#(((#%((((((#&@\*@*&*****\(,  @*************
******************\@%\[email protected]\\%##%%%&@%#(((((((#(@***,&*....%.&%#@@#*************

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

contract Misfits is ERC721A, EIP712, Ownable {
	using ECDSA
	for bytes32;
	using Strings
	for uint256;

	address whitelist_signer = 0xc49333f479A27e0f2f9FebdC87c6BB891cfC876E;
	address allowlist_signer = 0x0b3ABb79c0035824BAB9A668C94c4ffcC0F042B5;
	address projectWallet = 0xa06a0C4119bC6b319B4255A6eadB705A305A9e2d;

	string public baseUri;
	string public hiddenURL = "ipfs://QmS468gr5htmengzDKi4jbKU9328dE4inDuDEZfHLhiAh3/misfits.json";
	bool public ActiveContract = false;
	bool public revealed = false;

	uint256 public MAX_SUPPLY = 7777;
	uint256 public FREE_SUPPLY = 333;
	uint256 public TEAM_SUPPLY = 200;

	uint256 public MaxPerWalletWL = 2;

	uint256 public mintFee = 0.0099 ether;

	mapping( uint256 => uint256 ) private allowlistClaimBitMask;
	mapping( uint256 => uint256 ) private whitelistClaimBitMask;
	mapping( address => bool ) private addressMinted;
	mapping( address => uint256 ) private mintedAmount;

	constructor()
	ERC721A( "MISFITS", "MF" )
	EIP712( "MIF", "1.0.0" ) {
		_safeMint(projectWallet, TEAM_SUPPLY );
	}

	function allowlistmint( bytes calldata _signature, uint256 _nftIndex, uint256 _quantity ) external payable mintCompliance() {
		require( totalSupply() <= (MAX_SUPPLY - FREE_SUPPLY)-_quantity, "SOLD OUT" );
		require( !isClaimed(_nftIndex, false), "ALLOWLIST MINT ALREADY CLAIMED" );
        require( _verify( _whitelistHash( msg.sender, _nftIndex ), _signature, false ), "ALLOWLIST INVALID SIGNATURE" );
		_setClaimed( _nftIndex, false );
		uint256 _mintedAmount = mintedAmount[ msg.sender ];
		require( _mintedAmount + _quantity <= MaxPerWalletWL, "MAX PER WALLET REACHED" );
		require( msg.value >= mintFee * _quantity, "NOT ENOUGH ETH TO MINT" );
		_mint( msg.sender, _quantity );
		mintedAmount[ msg.sender ] = _mintedAmount + _quantity;
	}

	function whitelistmint( bytes calldata _signature, uint256 _nftIndex, uint256 _quantity ) external payable  mintCompliance() {
		require( totalSupply() <= MAX_SUPPLY-_quantity, "SOLD OUT" );
    	require( !isClaimed(_nftIndex, true), "WL MINT ALREADY CLAIMED" );
		require( _verify( _whitelistHash( msg.sender, _nftIndex ), _signature, true ), "WL INVALID SIGNATURE" );
		uint256 _mintedAmount = mintedAmount[ msg.sender ];
	    _setClaimed( _nftIndex, true );
		require( _mintedAmount + _quantity <= MaxPerWalletWL, "MAX PER WALLET REACHED" );

		if ( _quantity > 1 ) {
			require( msg.value >= mintFee * ( _quantity - 1 ), "NOT ENOUGH ETH TO MINT" );
		}
		_mint( msg.sender, _quantity );
		mintedAmount[ msg.sender ] = _mintedAmount + _quantity;
	}
	function isClaimed( uint256 _nftIndex, bool isWhiteListSale ) public view returns( bool ) {
		uint256 wordIndex = _nftIndex / 256;
		uint256 bitIndex = _nftIndex % 256;
		uint256 mask = 1 << bitIndex;
		if ( isWhiteListSale ) {
			return whitelistClaimBitMask[ wordIndex ] & mask == mask;
		}
		else {
			return allowlistClaimBitMask[ wordIndex ] & mask == mask;
		}
	}

	function _setClaimed( uint256 _nftIndex, bool isWhiteListSale ) internal {
		uint256 wordIndex = _nftIndex / 256;
		uint256 bitIndex = _nftIndex % 256;
		uint256 mask = 1 << bitIndex;
		if ( isWhiteListSale ) {
			whitelistClaimBitMask[ wordIndex ] |= mask;
		}
		else {
			allowlistClaimBitMask[ wordIndex ] |= mask;
		}
	}

	function _hash( address _account, uint256 _nftIndex, uint256 _quantity )
	internal view returns( bytes32 ) {
		return _hashTypedDataV4( keccak256( abi.encode( keccak256( "NFT(address _account,uint256 _nftIndex,uint256 _quantity)" ), _account, _nftIndex, _quantity ) ) );
	}

	function _whitelistHash( address _account, uint256 _nftIndex )
	internal view returns( bytes32 ) {
		return _hashTypedDataV4( keccak256( abi.encode( keccak256( "NFT(address _account,uint256 _nftIndex)" ), _account, _nftIndex ) ) );
	}

	function _verify( bytes32 digest, bytes memory signature, bool isWhitelist )
	internal view returns( bool ) {
		if ( isWhitelist ) return SignatureChecker.isValidSignatureNow( whitelist_signer, digest, signature );
		else return SignatureChecker.isValidSignatureNow( allowlist_signer, digest, signature );
	}

	function _baseURI() internal view virtual override returns( string memory ) {
		return baseUri;
	}

	function OwnerMint( uint256 _quantity ) external onlyOwner {
		require( totalSupply() <= ( MAX_SUPPLY - _quantity ), "CANT MINT MORE THAN SUPPLY" );
		_mint( msg.sender, _quantity );
	}

	function tokenURI( uint256 _tokenId ) public view virtual override returns( string memory ) {
		require( _exists( _tokenId ), "NFT: URI query for nonexistent token" );
		if ( revealed == false ) {
			return hiddenURL;
		}
		return bytes( baseUri )
			.length > 0 ? string( abi.encodePacked( baseUri, _tokenId.toString(), ".json" ) ) : "";
	}

	function setbaseUri( string memory newBaseURI ) external onlyOwner {
		baseUri = newBaseURI;
	}
	
	function ActivateSale() public onlyOwner {
		ActiveContract = !ActiveContract;
	}
	function Reveal() external onlyOwner {
		revealed = !revealed;
	}

    function burnSupply(uint256 _newAmount) external onlyOwner {
        require(_newAmount < MAX_SUPPLY, "Cannot Increase Supply over Max Supply");
        require(_newAmount > totalSupply(), "New  Supply has to be greater that total supply.");
        
        MAX_SUPPLY = _newAmount;
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
		_;
	}
}