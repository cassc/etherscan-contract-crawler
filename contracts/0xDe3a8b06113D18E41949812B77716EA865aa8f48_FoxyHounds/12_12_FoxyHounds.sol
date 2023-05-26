// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./FoxyFam.sol";

contract FoxyHounds is ERC721, Ownable { 

    bool public saleActive = false;
    bool public presaleActive = false;
    bool public claimActive = false;
    
    string internal baseTokenURI;

    uint public price = 0.03 ether;
    uint public totalSupply = 10000;
    uint public claimSupply = 3333;
    uint public nonce = 0;
    uint public claimed = 0;
    uint public maxTx = 3;

    FoxyFam public NFT;
    
    event Mint(address owner, uint qty);
    event Giveaway(address to, uint qty);
    event Withdraw(uint amount);

    mapping (address => uint256) public presaleWallets;
    mapping(uint => bool) public foxyMints;
    
    constructor(address nft) ERC721("FoxyHounds", "HOUNDS") {
        setFoxyFamAddress(nft);
    }

    function setFoxyFamAddress(address newAddress) public onlyOwner {
        NFT = FoxyFam(newAddress);
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

    function setClaimSupply(uint newSupply) external onlyOwner {
        claimSupply = newSupply;
    }

    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function setClaimActive(bool val) public onlyOwner {
        claimActive = val;
    }

    function setPresaleWallets(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            presaleWallets[_a[i]] = _amount[i];
        }
    }

    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function getFoxyByOwner(address owner) public view returns (uint[] memory) {
        uint[] memory balance = new uint[](NFT.balanceOf(owner));
        uint counter = 0;
        for (uint i = 0; i < NFT.nonce(); i++) {
            if (NFT.ownerOf(i) == owner) {
                balance[counter] = i;
                counter++;
            }
        }
        return balance;
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
    
    function getMyAssets() external view returns(uint[] memory){
        return getAssetsByOwner(tx.origin);
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

    function claim(uint[] memory ids) external {
        require(claimActive, "TRANSACTION: claim is not active");
        require(ids.length + claimed <= claimSupply, "SUPPLY: Value exceeds totalSupply");
        uint qty = 0;
        for(uint i=0; i < ids.length;i++){
            uint tokenId = ids[i];
            require(NFT.ownerOf(tokenId) == _msgSender(), "SENDER IS NOT OWNER");
            require(foxyMints[tokenId] != true, "FOXY ALREADY CLAIMED");
            if(foxyMints[tokenId] != true){
                qty++;
                uint id = nonce;
                _safeMint(_msgSender(), id);
                nonce++;
                claimed++;
                foxyMints[tokenId] = true;
            }
        }
        emit Mint(_msgSender(), qty);
    }

    function buyPresale(uint qty) external payable {
        uint256 qtyAllowed = presaleWallets[msg.sender];
        require(presaleActive, "TRANSACTION: Presale is not active");
        require(qtyAllowed > 0, "TRANSACTION: You can't mint on presale");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(msg.value == price * qty, "PAYMENT: invalid value");
        presaleWallets[msg.sender] = qtyAllowed - qty;
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