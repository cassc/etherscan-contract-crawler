// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EarlyAccess is ERC721A, Ownable {
    using Strings for uint256;

    // Settings
    bool private contractLocked = true;
    uint256 private unlockDate;
    string private baseTokenURI;
    uint256 private maxSupply = 1000;

    // Sale
    bool private paused = true;
    uint256 private price = 1 ether;
    uint256 private maxMints = 2;
    uint256 private reservedNFTs = 100;
    uint256 private reservedNFTsMinted;
    mapping( address => uint256 ) private addressToNFTsMinted;

    constructor( string memory _baseTokenURI, uint256 _unlockDate ) ERC721A( "Early Access", "EA" ) {
        baseTokenURI = _baseTokenURI;
        unlockDate = _unlockDate;
    }

    //////////
    // Getters
    function _startTokenId() internal view virtual override returns ( uint256 ) {
        return 1;
    }

    function _baseURI() internal view virtual override returns ( string memory ) {
        return baseTokenURI;
    }

    function tokenURI( uint256 tokenId ) public view virtual override returns ( string memory ) {
        require( _exists( tokenId ), "ERC721Metadata: URI query for nonexistent token" );
            string memory baseURI = _baseURI();
            return bytes( baseURI ).length > 0 ? string( abi.encodePacked( baseURI, tokenId.toString() ) ) : "";
    }

    function NFTsReserved() public view returns( uint256 ) {
        return reservedNFTs;
    }

    function calculatePrice( uint256 _count ) public view returns( uint256 ) {
        return _count * price;
    }

    function getNumberOfNFTsMintedByAddress( address _address ) public view returns( uint256 ) {
        return addressToNFTsMinted[_address];
    }

    function getNumberOfReservedNFTsMinted() public view returns( uint256 ) {
        return reservedNFTsMinted;
    }

    function getMaxMints() public view returns( uint256 ) {
        return maxMints;
    }

    function ownsPass( address _address ) public view returns( bool ) {
        if( balanceOf( _address ) > 0 ) {
            return true;
        } 

        return false;
    }

    function getUnlockDate() public view returns( uint256 ) {
        return unlockDate;
    }

    function isSalePaused() public view returns( bool ) {
        return paused;
    }

    function isContractLocked() public view returns( bool ) {
        if ( block.timestamp > unlockDate ) return false;
        
        return contractLocked;
    }

    ////////////////
    // Lock contract
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        require( !isContractLocked(), "Contract is currently locked!" );
        
        ERC721A.transferFrom( from, to, tokenId );
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require( !isContractLocked(), "Contract is currently locked!" );

        ERC721A.setApprovalForAll( operator, approved );
    }

    function approve(address to, uint256 tokenId) public payable virtual override {
        require( !isContractLocked(), "Contract is currently locked!" );
        
        ERC721A.approve( to, tokenId );
    }

    /////////////////
    // Mint functions
    function mint( uint256 quantity ) external payable {
        require( quantity > 0, "Quantity can't be 0!" );
        require( !paused, "Sale not active!" );
        require( totalSupply() + quantity <= maxSupply - reservedNFTs, "Reached max supply" );
        require( msg.value >= calculatePrice(quantity), "Not enough ether to purchase NFTs" );
        require( addressToNFTsMinted[msg.sender] + quantity <= maxMints, "Address can't mint more NFTs" );

        addressToNFTsMinted[msg.sender] += quantity;
        _safeMint( msg.sender, quantity );
    }

    function mintReservedNFTs( uint256 quantity, address _receiver ) external payable onlyOwner {
        require( quantity > 0, "Quantity can't be 0!" );
        require( !paused, "Sale not active!" );
        require( totalSupply() + quantity <= maxSupply, "Reached max supply" );
        require( reservedNFTsMinted + quantity <= reservedNFTs, "Reached max admin mints" );
        require( msg.value >= calculatePrice( quantity ), "Not enough ether to purchase NFTs." );

        reservedNFTsMinted += quantity;
        _safeMint( _receiver, quantity );
    }

    //////////////////
    // Owner functions 
    function toggleSale() external onlyOwner {
        if ( paused ) {
            paused = false;
        } else {
            paused = true;
        }
    }

    function toggleLockContract() external onlyOwner {
        if ( contractLocked ) {
            contractLocked = false;
        } else {
            contractLocked = true;
        }
    }

    function setBaseTokenURI( string calldata _baseTokenURI ) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setPrice( uint256 _price ) external onlyOwner {
        price = _price;
    }

    function setReservedNFTs( uint256 _reservedNFTs ) external onlyOwner {
        reservedNFTs = _reservedNFTs;
    }

    function setMaxMints( uint256 _maxMints ) external onlyOwner {
        maxMints = _maxMints;
    }

    function withdraw() external onlyOwner {
        payable( msg.sender ).transfer( address( this ).balance );
    }
}