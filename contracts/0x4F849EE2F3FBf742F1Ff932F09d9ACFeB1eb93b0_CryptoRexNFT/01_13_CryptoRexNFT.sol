/* SPDX-License-Identifier: MIT  */

pragma solidity ^ 0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/ERC721A.sol";

contract CryptoRexNFT is ERC721A, EIP712, Ownable {
	using ECDSA for bytes32;
	using Strings for uint256;

	address whitelist_signer = 0x0AB414aa2A325019861CC99e200F0D41b65bda50;
    address artist = 0xAd275728fd641B5cF66688bA47d2bE0df0cBcaf5;
	
	bool public activeContract = false;
    bool public publicMint = false;
	string public baseUri;
	uint256 public MAX_SUPPLY = 3333;
    uint256 public team_supply = 133;

	uint256 public price = 0.029 ether;
    uint256 public wl_price = 0.019 ether;
	
	mapping( uint256 => uint256 ) private whitelistClaimBitMask;
	mapping( address => bool ) private addressMinted;
	mapping( address => uint256 ) private mintedAmount;

    constructor()
	ERC721A( "CryptoRex NFT", "CRX" )
	EIP712( "CRX", "1.0.0" ) {}

	function whitelistmint( bytes calldata _signature, uint256 _nftIndex, uint256 _quantity ) external payable  mintCompliance() 
	{
            uint256 _mintedAmount = mintedAmount[msg.sender];
			require( !isClaimed(_nftIndex), "Whitelist Spot has been Claimed." );
			require(MAX_SUPPLY >= (totalSupply() + _quantity),"The collection has been sold out.");
			require( _verify( _whitelistHash( msg.sender, _nftIndex ), _signature), "Signature Invalid" );
			require(_mintedAmount + _quantity <= 2, "Max Per Wallet Reached");
			require( msg.value >= wl_price *_quantity , "ETH value isn't enough." );	
			_setClaimed( _nftIndex);		
			_mint( msg.sender, _quantity);
            mintedAmount[msg.sender] = _mintedAmount + _quantity;
		}

    function mint(uint256 _quantity) external payable mintCompliance()
	{
            uint256 _mintedAmount = mintedAmount[msg.sender];
         	require(publicMint, "Public Mint has not started.");  
         	require(msg.value >= price * _quantity, "ETH Value is not correct.");
			require(MAX_SUPPLY >= (totalSupply() + _quantity),"The collection has been sold out.");
            require(_mintedAmount + _quantity <= 2,"Max Per Wallet Reached");
            _safeMint(msg.sender, _quantity);
    }

    function teammint() external onlyOwner()
	{
			require(MAX_SUPPLY >= (totalSupply() + team_supply),"Cannot Mint Over MAX Supply");
            _safeMint(msg.sender, team_supply);
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

	function ActivateSale() external onlyOwner{
		activeContract=!activeContract;
	}

	function EnablePublicMint() external onlyOwner {
		publicMint = !publicMint;
	}

    function burnSupply(uint256 _newAmount) external onlyOwner {
        require(_newAmount < MAX_SUPPLY, "Cannot Increase Supply over Max Supply");
        require(_newAmount > totalSupply(), "New  Supply has to be greater that total supply.");
        MAX_SUPPLY = _newAmount;
    }
    function changeWLMintPrice(uint256 newMintPrice) public onlyOwner {
        wl_price = newMintPrice;
    }

        function changePublicMintPrice(uint256 newMintPrice) public onlyOwner {
        price = newMintPrice;
    }
    
      function withdraw() public payable onlyOwner {

    (bool hs, ) = payable(artist).call{value: address(this).balance * 30 / 100}("");
    require(hs);
    
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
    
	modifier mintCompliance() {
		require( tx.origin == msg.sender, "CALLER CANNOT BE A CONTRACT" );
		require(activeContract, "SALE IS NOT ACTIVE");
        require( totalSupply() <= MAX_SUPPLY, "The Collection has been Sold Out" );
		_;
	}
    
 
}