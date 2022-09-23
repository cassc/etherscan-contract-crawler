// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'contracts/ERC721A.sol';


pragma solidity ^0.8.7;

contract MoonTurds is Ownable, ERC721A {
    
    uint256 public MAXSUPPLY  = 4200;
    uint256 public FREESUPPLY = 1100;
    uint256 public MAXPERWALLET = 10;
    uint256 public MAXFREEPERWALLET = 1;
    
    uint256 public COST = 0.002 ether;
    bool    public ACTIVESALE = true;

    string private BASEURL;

    mapping(address => uint256) public mintedAmount;
    mapping(address => uint256) public freeMintedAmount;

    constructor() ERC721A("Moonturds n Frens", "MT") {
       
    }

    function FREEMINT(uint256 _quantity) external payable mintCompliance() {
                require(FREESUPPLY >= totalSupply()+_quantity,"FREE SUPPLY OVER.");
                uint256 _freeMintedAmount = freeMintedAmount[msg.sender];
                require(_freeMintedAmount + _quantity <= MAXFREEPERWALLET,"ONLY 1 FREE PER ADDRESS");
                freeMintedAmount[msg.sender] = _freeMintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }

    function MINT(uint256 _quantity) external payable mintCompliance(){
         require(msg.value >= COST * _quantity, "NO MONEY");
                require(MAXSUPPLY >= totalSupply() + _quantity,"SOLD OUT");
                uint256 _mintedAmount = mintedAmount[msg.sender];
                require(_mintedAmount + _quantity <= MAXPERWALLET,"ONLY 10 PER ADDRESS MAX");
                mintedAmount[msg.sender] = _mintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }

    function OpenMint() public onlyOwner {
        ACTIVESALE = !ACTIVESALE;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),".json")) : '';
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        BASEURL = baseURI;
    }

    function setCost(uint256 _price) external onlyOwner{
        COST = _price;
    }

    function burnSupply(uint256 _amount) public onlyOwner {
        require(_amount<MAXSUPPLY, "Can't increase supply");
        MAXSUPPLY = _amount;
    }

   function _baseURI() internal view virtual override returns (string memory) {
    return BASEURL;
  }
    
    function withdraw() public onlyOwner {
		( bool os, ) = payable( owner() )
			.call {value: address( this ).balance}( "" );
		require( os );
	}
        modifier mintCompliance() {
        require(!ACTIVESALE, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

}