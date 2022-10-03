// SPDX-License-Identifier: MIT
// PIXEL RENGAS, to the moon 

pragma solidity ^0.8.0;


import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'contracts/ERC721A.sol';


pragma solidity ^0.8.7;

contract PIXELRENGA is Ownable, ERC721A {
    
    uint256 public maxSupply                    = 2222;
    uint256 public maxFreeSupply                = 222;
    
    uint256 public maxPerAddressDuringMint      = 10;
    uint256 public maxPerAddressDuringFreeMint  = 1;

    uint256 public price                        = 0.002 ether;
    bool    public pause                        = true;

    string private _baseTokenURI;

    mapping(address => uint256) public mintedAmount;
    mapping(address => uint256) public freeMintedAmount;

    constructor() ERC721A("PIXELRENGA", "PRENGAS") {
       
    }

    function freemint(uint256 _quantity) external payable mintCompliance() {
                require(maxFreeSupply >= (totalSupply()+_quantity),"The free supply has been minted.");
                uint256 _freeMintedAmount = freeMintedAmount[msg.sender];
                require(_freeMintedAmount + _quantity <= maxPerAddressDuringFreeMint,"Only 1 free per address.");
                freeMintedAmount[msg.sender] = _freeMintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }

    function mint(uint256 _quantity) external payable mintCompliance(){
         require(msg.value >= price * _quantity, "No money");
                require(maxSupply >= totalSupply() + _quantity,"Sold Out");
                uint256 _mintedAmount = mintedAmount[msg.sender];
                require(_mintedAmount + _quantity <= maxPerAddressDuringMint,"10 per address max");
                mintedAmount[msg.sender] = _mintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }

    function Sale() public onlyOwner {
        pause = !pause;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),".json")) : '';
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function burnSupply(uint256 _amount) public onlyOwner {
        require(_amount<maxSupply, "Can't increase supply");
        maxSupply = _amount;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function withdraw() public onlyOwner {
		( bool os, ) = payable( owner() )
			.call {value: address( this ).balance}( "" );
		require( os );
	}
        modifier mintCompliance() {
        require(!pause, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

}