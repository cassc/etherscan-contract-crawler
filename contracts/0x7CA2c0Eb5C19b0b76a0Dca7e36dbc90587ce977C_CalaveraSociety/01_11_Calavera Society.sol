/* SPDX-License-Identifier: MIT  */
/*

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@* .((((((*  #@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&
@@@@@@@@@@@@@@@@@@@@@@@@@@@#,/(/(///////^******** / #/.&@@@@@&&&&&&&&&&&&&&&&&&&
@@@@@@@@@@@@@@@@@@@@@@@@.#//^*********,.&%,,,,,**,*,**** &@@&&&&&&&&&&&&&&&&&&&&
@@@@@@@@@@@@@@@@@@@@& /^***********,,#/ &  .,,,,,,,,,,,,****&&&&&&&&&&&&&&&&&&&&
@@@@@@@@@@@@@@@@@@& *******,,,,****,. &&&&,&#.......,,,,,***,.&&&&&&&&&&&&&&&&&&
@@@@@@@@@@@@@@@@@@/^******,*******##.&&  #&& ........,,,,,,,*,/&&&&&&&&&&&&&&&&&
@@@@@@@@@@@@@@@@&****************. &&& &&. &&,%&.,,,,,,,,,,,****&@&&&&&&&&&&&&&&
&@@@@@@@@@@@@@@&***************#%,&&. &&&&& &&&  ,,,,,,,,,*,*,***&&&&&&&&&&&&&&&
&@@@@@@@@@@@@@@.////^***#////^ .&&. &( &@@ &..&&(&%*,,,,*********.&&&&&&&&&&&&&&
@@@@@@@@@@@@@@@(////////////#%,&@&&&( & ,,. &&&&&& ./^******#////&&&&&&&&&&&&&&&
@@@@@@@@@@@@@@@////((((((%,( .,@ @&&&&&   @@&&&& &.. %.#((//////(&&&&&&&&&&&&&&&
@@@@@@@@@@@@@@@%(#(##,..(//(##/(%%.*[email protected]&&&&&& . &(/#&%#%(..%&##(,(.&&&&&&&&&&&&&&
@@@@@@@@@@@@@@@%(#%.  %@&&&&&&&&&&@#.%@&,%&* .&&&&&&&&&&&&#.,&#((&&&&&&&&&&&&&&&
&@@@@@@@@@@@@@@@,%&#@/&&&&&&&&&&&&&@*# &&& *&&&&&&&&&&&&&&&%/#%#*@&&&&&&&&&&&&&&
&@@@@@@@@@@@@@@@@((/[email protected]&&&&&&&&&&&&&&*&.& %,,,&&&&&&&&&&&&&&&,*&@&&&&&&&&&&&&&&&&
@@@@@@@@@@@@@@@@@%(..#@&&&&*.**  &&([email protected] ,&.*&&& (&&.&&&&&&,.%@&&&&&&&&&&&&&&&&
&@@@@@@@@@@@@@@@@ . . . &&&@@@@&..*(&#/% %&. @%..,&@&&&&%...  , &&&&&&&&&&&&&&&&
@@@@@@@@@@@@@@@@.,*#/////((#%%&&@&&#,&&   &&.,&@@&&%%#((////^*,,*@@&&&&@&&&&&&&&
@@@@@@@@@@@@@@@@@@@(&&&&@@@&&&%&&&/           ,&&%#@&&@@&&&&&%&@@@@@@@@@@@@&&&&&
@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@(#*.   .*& ,    ,#/@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&
@@@@@@@@@@@@@@@@@@@@@@@%@@@&@&#/,..# ..&&& * *    ,@@@&%@(@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@(@#@@#*,..& .        .%,.  #@&&@/@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&(&@@@@@&,,.(  %.,*. ..*,&#@&%/(/@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&(((%(%%@@%@@%@&@@(@#@@%&(&././^,@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@%(((/(#*@%#/@*@**&*@,[email protected]@%,*,,,,.,@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&(((((((@@*,*,,,,,,[email protected],,#,....*@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((//^@,*,,,,..,,,.&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#(//^**,,,,,/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/
 
pragma solidity ^ 0.8.7;
 
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 
import "contracts/ERC721A.sol";
 
contract CalaveraSociety is ERC721A, EIP712, Ownable {
	using ECDSA
	for bytes32;
	using Strings
	for uint256;
 
	address whitelist_signer = 0x27F0a1103B81d674dfA0BDa0d1A3dDcc32296F16;
 
	bool public activeContract = false;
    bool public publicMint = false;
	string public baseUri;
	uint256 public MAX_SUPPLY = 666;
 
	uint256 public price = 0.0249 ether;
 
	mapping( uint256 => uint256 ) private whitelistClaimBitMask;
	mapping( address => bool ) private addressMinted;
	mapping( address => uint256 ) private mintedAmount;
		mapping( address => uint256 ) private WLmintedAmount;
 
 
	constructor()
	ERC721A( "Calavera Society", "CLS" )
	EIP712( "CLS", "1.0.0" ) {
		_safeMint(0xE034E081B0c4a9Ce9b471C25C171DED941444E78, 20);
 
	}
 
	function whitelistmint( bytes calldata _signature, uint256 _nftIndex, uint256 _quantity ) external payable  mintCompliance() 
	{
			uint256 _mintedAmount = WLmintedAmount[msg.sender];
			require( !isClaimed(_nftIndex), "Whitelist Spot has been Claimed." );
			require(MAX_SUPPLY >= (totalSupply() + _quantity),"The collection has been sold out.");
			require( _verify( _whitelistHash( msg.sender, _nftIndex ), _signature), "Signature Invalid" );
			require(_mintedAmount + _quantity <= 1, "You already minted one.");
			require( msg.value >= price*_quantity , "ETH value isn't enough." );	
			_setClaimed( _nftIndex);		
			_mint( msg.sender, _quantity);
			WLmintedAmount[ msg.sender ] = _mintedAmount + _quantity;
		}
 
    function mint(uint256 _quantity) external payable mintCompliance()
	{
         	require(publicMint, "Public Mint has not started.");  
         	require(msg.value >= price * _quantity, "ETH Value is not correct.");
			require(MAX_SUPPLY >= (totalSupply() + _quantity),"The collection has been sold out.");
            uint256 _mintedAmount = mintedAmount[msg.sender];
            require(_mintedAmount + _quantity <= 3,"ONLY 3 PER ADDRESS MAX");
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
 
	function ActivateSale() external onlyOwner{
 
		activeContract=!activeContract;
	}
 
	function tokenURI( uint256 _tokenId ) public view virtual override returns( string memory ) {
		require( _exists( _tokenId ), "NFT: URI query for nonexistent token" );
		return bytes( baseUri )
			.length > 0 ? string( abi.encodePacked( baseUri, _tokenId.toString(), ".json" ) ) : "";
	}
 
	function setbaseUri( string memory newBaseURI ) external onlyOwner {
		baseUri = newBaseURI;
	}
 
 
	function EnablePublicMint() external onlyOwner {
		publicMint = !publicMint;
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
		require( tx.origin == msg.sender, "CALLER CANNOT BE A CONTRACT" );
		require(activeContract, "SALE IS NOT ACTIVE");
        require( totalSupply() <= MAX_SUPPLY, "SOLD OUT" );
		_;
	}
 
 
}