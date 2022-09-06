//SPDX-License-Identifier: MIT
/*

THE REKTSISTANCE | PFP Collection by REKT Collective

Total Supply: 2,222

Twitter: @rektcollective
discord.gg/rektcollective

********************************************************************************
********************************************************************************
********************************************************************************
********************************************************************************
****************************%#&*@(**********************************************
**********************@&&&&&&&&&&&&&&@******************************************
*******************@&&&&&&&&&&&&&&&&&&&*****************************************
****************@&&&&&&&&&&&%#&%&&&&&&&@****************************************
***************@&&&&@%%%%%,%&&@%%, ###%*****************************************
****************@@# #### # ####*###  ##/^*****************************//********
*************^/#%@#@&&&[email protected]******************************@*,/*******
**************@% [email protected]@&@[email protected]&&  &&@[email protected]  & @******************************(####******
***************@***[email protected]@...&&&&&&..& &&@*******************************,##(/^*****
*****************^*@*@.........%.....%*****************************^/,,,/,&*****
********************@*...............******************************^/###,*,/^***
**********************@**..........&*******************************(####(((*****
***********************..****@@***********************************^/###(((((@  @
****************@&&&&&@....*[email protected]&&&&&&&&#*****************************##*,/##/////
***********&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@************************////#*,/#//////
/********&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@****************@ .//////#*,/#//////
/*******@&&&&&&&&&&&&&&&&&&&&&&&&&&&@&&&&&&.. @********@  ..#.//////##/,*##/////
/*******@&&&&&&&@&&&&&&&&&&&&&&&&&&&@&&&&....*[email protected]/ @// [email protected]%&*[email protected]///@##/,@#&/////
/******&&&&&&&&%&&&&&&&&&&&&&&&&&&&&@****@****..........******. ///@%&%&&///////
/******@&&&&&&&&&&&&&&&&&&&&&@&&&&&&&**@ ,////////////////////&/%%&&&&&&////////
/*******[email protected]@&&&&@&&&&&&&&&&&&@  /////////////@&&&&&@%&(%%&&&&&&&&&&/////////
********[email protected]*&&&&&&&&&&&&@  /////////////@&###@&%@&%%&&&&&&&&&&&&&&/////////#
********....(.. *&&&&&&@  /////////////@&&&&&#@@%%%@&&&&&&&&&&&&&&&&%//#########
********&#.../[email protected]  */////////////@&&&&&&@%%/(%%%#@&&&&&&&&&&&&%%%@#############
/************(.([email protected]////////////&(@%&&%%#@%%%@%%&&&&&&&&&%%%,&((################
*******%  ////@*%..........%&////#((#[email protected]%&@%%/@%&%&&&%%%*&(######################
*@,,,#############@**[email protected]#####((%(@&&&&%%%(&(###########################
######################@*....*###############&#%#################################
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

contract REKTSISTANCE is ERC721A, EIP712, Ownable {
	using ECDSA
	for bytes32;
	using Strings
	for uint256;

	address whitelist_signer = 0x06bFE747812C699d2feC7FC6ee9551ed83EED7ef;
	address allowlist_signer = 0x91bd9465ffA3f26bafDD1109676596c0f6e1697E;
	address rektwallet = 0x3079a30EC75471a58dF4ecF0E559007B2F014AFC;

	string public baseUri;
	bool public ActiveContract = false;

	uint256 public MAX_SUPPLY = 2222;
	uint256 public REKTHOLDER_RESERVE = 700;
	uint256 public TEAM_SUPPLY = 100;

	uint256 public MaxPerWalletWL = 2;

	uint256 public mintFee = 0.007 ether;

	mapping( uint256 => uint256 ) private allowlistClaimBitMask;
	mapping( uint256 => uint256 ) private whitelistClaimBitMask;
	mapping( address => bool ) private addressMinted;
	mapping( address => uint256 ) private mintedAmount;

	constructor()
	ERC721A( "REKTSISTANCE", "RT" )
	EIP712( "RT", "1.0.0" ) {
	_safeMint(rektwallet, TEAM_SUPPLY );
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

	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "NFT: URI query for nonexistent token");
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, _tokenId.toString(), ".json")) : "";
    }

	function setbaseUri( string memory newBaseURI ) external onlyOwner {
		baseUri = newBaseURI;
	}
	
	function UnleashTheRektsistance() public onlyOwner {
		ActiveContract = !ActiveContract;
	}


	function REKT() public onlyOwner {
		( bool os, ) = payable( owner() )
			.call {
				value: address( this )
					.balance
			}( "" );
		require( os );
	}
    
function allowlistmint( bytes calldata _signature, uint256 _nftIndex, uint256 _quantity ) external payable mintCompliance() {
		require( totalSupply() <= (MAX_SUPPLY - REKTHOLDER_RESERVE)-_quantity, "The collection has been sold out." );
		require( !isClaimed(_nftIndex, false), "The allowlist has been claimed." );
        require( _verify( _whitelistHash( msg.sender, _nftIndex ), _signature, false ), "Signature for allowlist is not valid." );
		_setClaimed( _nftIndex, false );
		uint256 _mintedAmount = mintedAmount[ msg.sender ];
		require( _mintedAmount + _quantity <= MaxPerWalletWL, "You can't have more than two, don't be greedy." );
		require( msg.value >= mintFee * _quantity, "REKT, not enough liquid." );
		_mint( msg.sender, _quantity );
		mintedAmount[ msg.sender ] = _mintedAmount + _quantity;
	}

	function rektlistmint( bytes calldata _signature, uint256 _nftIndex, uint256 _quantity ) external payable  mintCompliance() {
		require( totalSupply() <= MAX_SUPPLY-_quantity, "The collection sold out." );
    	require( !isClaimed(_nftIndex, true), "Wallet has claimed." );
		require( _verify( _whitelistHash( msg.sender, _nftIndex ), _signature, true ), "Signature for REKTLIST is invalid." );
		uint256 _mintedAmount = mintedAmount[ msg.sender ];
	    _setClaimed( _nftIndex, true );
		require( _mintedAmount + _quantity <= MaxPerWalletWL, "You can't have more than two, don't be greedy." );

		if ( _quantity > 1 ) {
			require( msg.value >= mintFee * ( _quantity - 1 ), "REKT, Not enough liquid." );
		}
		_mint( msg.sender, _quantity );
		mintedAmount[ msg.sender ] = _mintedAmount + _quantity;
	}
	modifier mintCompliance() {
		require( ActiveContract, "You got REKT, we haven't started." );
		require( tx.origin == msg.sender, "Don't be naughty, we don't let you use contracts to mint." );
		_;
	}
}