// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


import './ERC721Tradable.sol';


/*            HEAD DAO. NEED HEAD FR FR             */


contract HeadDao is ERC721Tradable {
    using Strings for uint256;
	using SafeMath for uint256;

    event MintHead (address indexed sender, uint256 startWith, uint256 times);

    //uints 
    uint256 public totalHead;
    uint256 public totalCount = 10000;
    uint256 public maxPurchase = 10;
    uint256 public price = 55000000000000000; 
    string public baseURI;
	uint[] public mintedIds;
	string private _contractURI;

    //bool
    bool public sale_active = false;    

	// Wallets
	address private community_wallet = 0x77a45d5BD81916901474ef1a162b34D8FAaE1030;
	address private RZ_wallet = 0x56314CCd8BB78ae9b874eb4fC3B13EDC55734694;
	address private AR_wallet = 0xEa46B6534E48dA658cA51154755Ac3cc8f9CAA0D;
	address private shamdoo_wallet = 0x11360F0c5552443b33720a44408aba01a809905e;

	// mapping
	mapping(address => uint) public mintedNFTs;

    

    //constructor args 
	constructor(address _proxyRegistryAddress, string memory _cURI) ERC721Tradable("HeadDAO", "HEAD", _proxyRegistryAddress) {_contractURI = _cURI; }


    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setContractURI(string memory _cURI) external onlyOwner {
        _contractURI = _cURI;
    }

	function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

	function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

	function setSaleStatus(bool _start) public onlyOwner {
        sale_active = _start;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }


    function changeBatchSize(uint256 _newBatch) public onlyOwner {
        maxPurchase = _newBatch;
    }




    function mintHead(uint256 _count) payable public {
		uint256 TotalSupply = totalSupply();
        require(sale_active, "sale has to be active");
        require(_count >0 && _count <= maxPurchase, "Violated Max Tx Purchase Constraint");
        require(TotalSupply + _count <= totalCount, "Exceeds Max Tokens Available");
        require(msg.value == _count * price, "value error");
		require(msg.value >= price.mul(_count), "Ether value sent is not correct");
        emit MintHead(_msgSender(), TotalSupply+1, _count);

        for(uint256 i=0; i < _count; i++){
            _mint(_msgSender(), _getNextTokenId());
            mintedIds.push(_getNextTokenId());
            _incrementTokenId();

        }
    }  
    
    function devMint(uint256 _count) public onlyOwner {
		uint256 TotalSupply = totalSupply();
		require(TotalSupply + _count <= totalCount, "Exceeds Max Tokens Available");
        emit MintHead(_msgSender(), TotalSupply+1, _count);


        for(uint256 i=0; i < _count; i++){
            _mint(_msgSender(), _getNextTokenId());
            mintedIds.push(_getNextTokenId());
            _incrementTokenId();

        }
    }

	function withdraw() public payable onlyOwner {

        uint256 _community = (address(this).balance * 80) / 100;

        // Calculated from the rest of the balance
		uint256 _team = address(this).balance - _community;
        
        // 20% distributed to the team
        uint256 _sh= _team.mul(33).div(100);
        uint256 _rz = _team.mul(41).div(100);
		uint256 _ar = _team.mul(26).div(100);


		payable(community_wallet).transfer(_community);
        payable(shamdoo_wallet).transfer(_sh);
		payable(RZ_wallet).transfer(_rz);
		payable(AR_wallet).transfer(_ar);



    }

	function withdraw_emerg() public payable onlyOwner {

        uint balance = address(this).balance;
        payable(shamdoo_wallet).transfer(balance);


    }




	function get_all() public view  returns (uint[] memory) {
        return mintedIds;
    }



}