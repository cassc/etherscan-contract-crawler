// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BettorverseNFT is ERC721, Ownable { 
    
    string internal baseTokenURI = 'https://bettorverse.com/api/';
    uint public price = 0.05 ether;
    uint public totalSupply = 4000;
    uint public nonce = 0;
    uint public maxTx = 0;
    
    string private _mintPhrase;
    
    mapping(address => mapping(uint => uint)) internal blockMints;
    
    event Mint(address owner, uint qty);
    event Withdraw(uint amount);
    
    constructor() ERC721("Bettorverse", "BTV") {}
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setMintPhrase(string calldata phrase) external onlyOwner {
        _mintPhrase = phrase;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }
    
    function buy(uint qty, string calldata phrase) external payable {
        require(keccak256(bytes(phrase)) == keccak256(bytes(_mintPhrase)), "hmmmm");
        require(qty <= maxTx || qty > 0, "TRANSACTION: qty of mints not alowed");
        require((qty + blockMints[_msgSender()][block.number]) <= maxTx, "Asshole");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(msg.value == price * qty, "PAYMENT: invalid value");
        blockMints[_msgSender()][block.number] += qty;
        for(uint i = 0; i < qty; i++){
            nonce++;
            _safeMint(_msgSender(), nonce);
        }
        emit Mint(_msgSender(), qty);
    }
    
    function giveaway(address to, uint qty) external onlyOwner{
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
         for(uint i = 0; i < qty; i++){
            nonce++;
            _safeMint(to, nonce);
        }
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
}