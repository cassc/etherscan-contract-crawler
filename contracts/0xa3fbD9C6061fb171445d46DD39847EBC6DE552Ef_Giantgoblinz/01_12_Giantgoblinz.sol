// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Giantgoblinz is ERC721, Ownable { 

    uint public price = 0 ether;
    uint public totalSupply = 5000;
    uint public nonce = 0;
    uint public maxTx = 1;
    uint public maxWallet = 2;

    bool mintOpen = false;
    
    mapping(address => uint[]) private ownership;

    string internal baseTokenURI = 'https://us-central1-giantgoblinz.cloudfunctions.net/api/asset/';
    
    constructor() ERC721("giantgoblinz", "ggoblinz") {}

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
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

    function setMaxWallet(uint newMax) external onlyOwner {
        maxWallet = newMax;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function giveaway(address to, uint qty) external onlyOwner {
        _mintTo(to, qty);
    }
    
    function buy(uint qty) external payable {
        require(mintOpen, "store closed");
        require(msg.value >= price * qty, "PAYMENT: invalid value");
        _buy(qty);
    }

    function _buy(uint qty) internal {
        require(qty <= maxTx && qty > 0 && (balanceOf(_msgSender()) + qty <= maxWallet), "TRANSACTION: qty of mints not alowed");
        _mintTo(_msgSender(), qty);
    }

    function _mintTo(address to, uint qty) internal {
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