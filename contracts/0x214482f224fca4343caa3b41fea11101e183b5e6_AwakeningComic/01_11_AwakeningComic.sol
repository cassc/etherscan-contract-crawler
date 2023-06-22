// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AwakeningComic is ERC721, Ownable {
    bool public saleActive = false;
    bool public claimActive = false;
    
    string internal baseTokenURI;

    uint public price = 0.02 ether;
    uint public totalSupply = 9999;
    uint public nonce = 0;
    uint public claimed = 0;
    uint public maxTx = 3;

    ERC721 public NFT;
    
    event Mint(address owner, uint qty);
    event Giveaway(address to, uint qty);
    event Withdraw(uint amount);

    mapping(address => bool) public holders;
    
    constructor(address nft) ERC721("The Awakening Comic", "AWAKC") {
        setAwakeningAddress(nft);
    }

    function setAwakeningAddress(address newAddress) public onlyOwner {
        NFT = ERC721(newAddress);
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

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function setClaimActive(bool val) public onlyOwner {
        claimActive = val;
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

    function claim() external {
        require(claimActive, "TRANSACTION: claim is not active");
        uint[] memory balance = new uint[](NFT.balanceOf(msg.sender));
        require(holders[msg.sender] != true, "TRANSACTION: You already claimed");
        require(balance.length > 0, "TRANSACTION: Not enough balance");
        require(balance.length + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        for(uint i=0; i < balance.length; i++){
            uint tokenId = nonce;
            _safeMint(msg.sender, tokenId);
            holders[msg.sender] = true;
            nonce++;
            claimed++;
        }
        emit Mint(_msgSender(), balance.length);
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