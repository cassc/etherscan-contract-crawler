// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'contracts/ERC721A.sol';


pragma solidity ^0.8.7;

contract DEGENWALKERS is Ownable, ERC721A {
    
    
    uint256 public ice = 0.009 ether;
    uint256 public max_supply = 111;
    bool public NightKing = true;

    string private baseurl ="ipfs://bafybeicsjwrnqa7qdsh7m6e4jxvtbsshoe65tygr3f5ots5s4ujyezpytu/";

    mapping(address => uint256) public mintedAmount;

    constructor() ERC721A("Degen Walkers", "DGWL") {
        	_safeMint(0x36d805A97A5F5De2c320E14032Fbd20B16d8d919, 15);

    }

    function mint(uint256 _quantity) external payable mintCompliance(){
         require(msg.value >= ice * _quantity, "NO MONEY");
                require(max_supply >= totalSupply() + _quantity,"SOLD OUT");
                uint256 _mintedAmount = mintedAmount[msg.sender];
                require(_mintedAmount + _quantity <= 1,"ONLY 1 PER ADDRESS MAX");
                mintedAmount[msg.sender] = _mintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }

    function IronThrone() public onlyOwner {
        NightKing = !NightKing;
    }


    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseurl = baseURI;
    }

    function crackIce(uint256 _price) external onlyOwner{
        ice = _price;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId+1),".json")) : '';
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseurl;
    }
    
    function withdraw() public onlyOwner {
		( bool os, ) = payable( owner() )
			.call {value: address( this ).balance}( "" );
		require( os );
	}
        modifier mintCompliance() {
        require(!NightKing, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

}