// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol"; 
import "./ERC721A.sol";
 
//........................................................................
//...........MAKE LOVE AND NFTS NOT WAR................................... 
//........................................................................
//.....................................................made with <3 Kindly  
//........................................................................

contract Kindly is Ownable, ERC721A  { 
    string _baseTokenURI;  
    uint256 private _price = 0.05 ether;  
    bool public _paused = true;     
    bool public _pausedFree = true;   
    uint256 private nLimitPerWallet = 4;
    uint256 private nLimitPerTx = 5;  
    mapping(string => bool) private _mintedNonces; 
    mapping(address => uint256) public mintedAddress;
    mapping(address => uint256) public mintedVIPAddress; 
    address k1 = 0xb38Cf1583306C378a613409ED0eF9d0f815dae0f; 

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) 
    ERC721A(name,symbol) {
        setBaseURI(baseURI); 
    } 
    modifier notContract() {
        require(tx.origin == msg.sender, "9");
        _;
    }
    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        uint256 supply = totalSupply(); 
        require( supply + _amount < 4001,  "Exceeds maximum Kindly supply" ); 
        mintedAddress[msg.sender] += _amount; 
        _safeMint(_to, _amount);
    }  
    function KindlyFreeMint(uint256 num) public payable notContract {
        uint256 supply = totalSupply(); 
        require( !_pausedFree, "1" );
        require( num < nLimitPerTx, "Kindly per tx reached" );
        require( supply + num < 2001, "Exceeds maximum Kindly supply" );
        require( balanceOf(msg.sender) + num <= nLimitPerWallet, "Kindly per wallet reached"); 
        mintedAddress[msg.sender] += num; 
        _safeMint(msg.sender, num);
    }   
    function KindlyMint(uint256 num) public payable notContract {
        uint256 supply = totalSupply(); 
        require( !_paused, "1" ); 
        require( supply + num < 4001, "Exceeds maximum Kindly supply" ); 
        require( msg.value >= _price * num, "4" ); 
        mintedAddress[msg.sender] += num; 
        mintedVIPAddress[msg.sender] += num; 
        _safeMint(msg.sender, num);
    }   
    function setLimitPerWallet(uint256 _limit) public onlyOwner() {
        nLimitPerWallet = _limit;
    }

    function getLimitPerWallet() public view returns (uint256){
        return nLimitPerWallet; 
    }
    function setLimitPerTx(uint256 _limit) public onlyOwner() {
        nLimitPerTx = _limit;
    }
    function getLimitPerTx() public view returns (uint256){
        return nLimitPerTx; 
    }
    function setPrice(uint256 _nPrice) public onlyOwner() {
        _price = _nPrice;
    }
    function getPrice() public view returns (uint256){
        return _price;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    function pause(bool val) public onlyOwner {
        _paused = val;
    } 
    function pauseFree(bool val) public onlyOwner {
        _pausedFree = val;
    } 
    function KindlyStable() public payable onlyOwner { 
        uint256 _eth = address(this).balance;
        require(payable(k1).send(_eth));
    } 
    //EYES AND EGGPLANT EMOJI 
    function KindlyMeltAwayMyClothes(uint256 tokenId) external {
        _burn(tokenId, true); 
    }  
    function getNumberBurnedOwner(address addy) public view returns (uint256){
       uint256 nBurned =  _numberBurned(addy);
        return nBurned;  
     } 
    function getNumberBurned() public view returns (uint256){
       uint256 nBurned =  _numberBurned(msg.sender);
        return nBurned;  
     } 

    
}