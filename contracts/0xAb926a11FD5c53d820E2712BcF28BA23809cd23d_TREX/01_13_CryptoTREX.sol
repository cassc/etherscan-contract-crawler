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

contract TREX is ERC721A, EIP712, Ownable {
	using ECDSA for bytes32;
	using Strings for uint256;

	address whitelist_signer = 0x0AB414aa2A325019861CC99e200F0D41b65bda50;

	
	bool public activeContract = false;
	string public baseUri;
	uint256 public WL_RESERVE = 401;
	uint256 public MAX_SUPPLY = 1111;
    uint256 public team_supply = 10;

	uint256 public price = 0.04 ether;
    uint256 public wl_price = 0.03 ether;
	
	mapping( uint256 => uint256 ) private whitelistClaimBitMask;
	mapping( address => bool ) private addressMinted;
	mapping( address => uint256 ) private mintedAmount;

    constructor()
	ERC721A( "TREX", "TRX" )
	EIP712( "TRX", "1.0.0" ) {}

	function whitelistmint( bytes calldata _signature, uint256 _nftIndex, uint256 _quantity ) external payable  mintCompliance() 
	{
            uint256 _mintedAmount = mintedAmount[msg.sender];
			require( !isClaimed(_nftIndex), "Whitelist Spot has been Claimed." );
			require( _verify( _whitelistHash( msg.sender, _nftIndex ), _signature), "Signature Invalid" );
			require(_mintedAmount + _quantity <= 5, "Max Per Wallet Reached");
			require( msg.value >= wl_price *_quantity , "ETH value isn't enough." );	
			_setClaimed( _nftIndex);		
			_mint( msg.sender, _quantity);
            mintedAmount[msg.sender] = _mintedAmount + _quantity;
		}

    function mint(uint256 _quantity) external payable mintCompliance()
	{
            uint256 _mintedAmount = mintedAmount[msg.sender];
         	require(msg.value >= price * _quantity, "ETH Value is not correct.");
			require((MAX_SUPPLY-WL_RESERVE) >= (totalSupply() + _quantity),"Public supply is limited at moment, please come back later.");
            require(_mintedAmount + _quantity <= 5,"Max Per Wallet Reached");
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

	  function ClearWLReserve() public onlyOwner {
        WL_RESERVE = 0;
    }

	function ActivateSale() external onlyOwner{
		activeContract=!activeContract;
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
    uint256 contractBalance = address(this).balance;

	address artist=0xC1De337B94784E172F68029f2144a6Ef26fF80B1;
	address dev=0x9D527C04FF2B28ab117224cFf2e5D6B8Dde33D5E;
	address project= 0x7669E7618FADeA92CC08e4202176133eA96D276C;

    uint256 teamShare = contractBalance*24/100;
    uint256 devShare = contractBalance*6/100;
    uint256 projectShare = contractBalance - teamShare - devShare;

   
   	payable(artist).transfer(teamShare);
   	payable(dev).transfer(devShare);
   	payable(project).transfer(projectShare);

}

    
	modifier mintCompliance() {
		require( tx.origin == msg.sender, "CALLER CANNOT BE A CONTRACT" );
		require(activeContract, "SALE IS NOT ACTIVE");
        require( totalSupply() <= MAX_SUPPLY, "The Collection has been Sold Out" );
		_;
	}
    
 
}