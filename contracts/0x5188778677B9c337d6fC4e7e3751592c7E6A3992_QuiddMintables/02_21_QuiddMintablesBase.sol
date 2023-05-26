pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";
import './token_id/QuiddTokenIDv0.sol';


// This is the abstract parent contract for Quidd NFTs that use the standard Quidd token format
abstract contract QuiddMintablesBase is ERC721 {
    using QuiddTokenIDv0 for uint256;
    
    
    /**
     * The constructor does not set the baseURI, but rather leaves that up to subclasses
     * The owner of the contract will automatically be set up with Admin and Minter roles
     */
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }
    
    /**
     * @dev Plain Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     * @param _tokenId the ID of the print as registered with Quidd
     * TODO: Implement custom indexing of tokens to save gas
     */
    function mint(address _to, uint256 _tokenId) public virtual {
	bool notNew = _exists(_tokenId);
	if (notNew) {
	    address owner = ownerOf(_tokenId);
	    require(owner == address(this), "Already minted");
	    
	    // Print was unminted. Transfer to new owner, with possibly new tokenId
	    // TODO: This means the count of tokens might be off
	    _transfer(address(this), _to, _tokenId);
	} else {
	    // First time minting
	    _mint(_to, _tokenId);
	}
	
    }
    
    /**
     * @dev Safe Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     * @param _tokenId the ID of the print as registered with Quidd
     */
    function safeMint(address _to, uint256 _tokenId) public virtual {
	bool notNew = _exists(_tokenId);
	if (notNew) {
	    address owner = ownerOf(_tokenId);
	    require(owner == address(this), "Already minted");
	    
	    // Print was unminted. Transfer to new owner, with possibly new tokenId
	    // TODO: This means the count of tokens might be off
	    _safeTransfer(address(this), _to, _tokenId, "");
	} else {
	    // First time minting
	    _safeMint(_to, _tokenId);
	}
	
    }
    
    /**
     * @dev Moves token ownership to the contract address, making it unminted
     * @param _tokenId the Token ID, formatted according to the QuiddTokenID standard
     *
     * TODO: Make unmint an interface!
     */
    function unmint(uint256 _tokenId) public virtual {
	address owner = ownerOf(_tokenId);
	require(owner != address(this), "Already unminted");
	_transfer(owner, address(this), _tokenId);
    }
    
    // The following functions are overrides required by Solidity.
    
    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId)
	public
	view
	virtual
	override(ERC721)
	returns (bool)
    {
	//console.log("IERC721:");
	//console.logBytes4(type(IERC721).interfaceId);
	return super.supportsInterface(interfaceId);
    }
}


contract TestQuiddMintablesBase is QuiddMintablesBase {
    constructor(string memory _name, string memory _symbol) QuiddMintablesBase(_name, _symbol) {
    }

    function mint(address _to, uint256 _tokenId) public override {
	super.mint(_to, _tokenId);
    }

    function safeMint(address _to, uint256 _tokenId) public override {
	super.safeMint(_to, _tokenId);
    }    

    function unmint(uint256 _tokenId) public override {
	super.unmint(_tokenId);
    }
}