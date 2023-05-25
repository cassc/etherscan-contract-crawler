// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mekaformers is ERC721, Ownable {

    bool public saleActive = false;

    string internal baseTokenURI;

    uint public price = 0.08 ether;
    uint public holderPrice = 0.05 ether;
    uint public totalSupply = 3000;
    uint public nonce = 0;
    uint public maxTx = 20;

    IERC721 public MEKAF;
    
    event Mint(address owner, uint qty);
    event Giveaway(address to, uint qty);
    event Withdraw(uint amount);

    constructor() ERC721("Mekaformers Legacy", "MEKAL") {}

    modifier mekafHolder(){
        require(MEKAF.balanceOf(msg.sender) > 0, "You must have at least one Mekaformer Genesis NFT");
        _;
    }

    function setMekafAddress(address newAddress) external onlyOwner {
        MEKAF = IERC721(newAddress);
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }

    function setHolderPrice(uint newPrice) external onlyOwner {
        holderPrice = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }
    
    function getAssetsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 0; i < nonce; i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }
    
    function giveaway(address to, uint qty) external onlyOwner {
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        for(uint i = 0; i < qty; i++){
            uint tokenId = nonce;
            _safeMint(to, tokenId);
            nonce++;
        }
        emit Giveaway(to, qty);
    }

    function buyHolder(uint qty) external payable mekafHolder {
        require(saleActive, "TRANSACTION: sale is not active");
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not alowed");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(msg.value == holderPrice * qty, "PAYMENT: invalid value");
        for(uint i = 0; i < qty; i++){
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
            nonce++;
        }
        emit Mint(msg.sender, qty);
    }

    function buy(uint qty) external payable {
        require(saleActive, "TRANSACTION: sale is not active");
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not alowed");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(msg.value == price * qty, "PAYMENT: invalid value");
        for(uint i = 0; i < qty; i++){
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
            nonce++;
        }
        emit Mint(msg.sender, qty);
    }
    
    function withdrawOwner() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}