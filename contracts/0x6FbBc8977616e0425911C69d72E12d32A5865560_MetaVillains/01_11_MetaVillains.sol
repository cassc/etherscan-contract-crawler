// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaVillains is ERC721, Ownable { 
    
    bool public saleActive = false;
    bool public claimActive = false;

    string internal baseTokenURI;

    uint public price = 0.09 ether;
    uint public totalSupply = 10000;
    uint public mintSupply = 0;
    uint public claimSupply = 10000;
    uint public nonce = 0;
    uint public maxTx = 20;
    
    mapping(address => uint) public holders;
    
    event Mint(address owner, uint qty);
    event Withdraw(uint amount);
    
    struct Holders {
        address wallet;
        uint qty;
    }
    
    modifier onlyHolders() {
        require(holders[_msgSender()] > 0, "ONLY HOLDERS");
        _;
    }
    
    constructor() ERC721("MetaVillains", "METAV") {}
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setTotalSupply(uint newSupply) external onlyOwner {
        totalSupply = newSupply;
    }

    function setMintSupply(uint newSupply) external onlyOwner {
        mintSupply = newSupply;
    }

    function setClaimSupply(uint newSupply) external onlyOwner {
        claimSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function setClaimActive(bool val) public onlyOwner {
        claimActive = val;
    }
    
    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
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
    
    function buy(uint qty) external payable {
        require(saleActive, 'Sale is not active');
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not alowed");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(msg.value == price * qty, "PAYMENT: invalid value");
        require(mintSupply >= qty, "Sold out");
        mintSupply -= qty;
        _create(_msgSender(), qty);
        emit Mint(_msgSender(), qty);
    }
    
    function addHolders(address[] calldata holders_, uint[] calldata qty) external onlyOwner {
        for(uint i=0; i< holders_.length; i++){
            holders[holders_[i]] = qty[i];
        }
    }
    
    function claimAll() external onlyHolders {
        require(claimActive, 'Claim is not active');
        uint qty = holders[_msgSender()];
        require(claimSupply > qty, "Claim over");
        require(nonce + qty <= totalSupply, "sold out");
        holders[_msgSender()] = 0;
        claimSupply -= qty;
        _create(_msgSender(), qty);
    }

    function claim(uint quantity) external onlyHolders {
        require(claimActive, 'Claim is not active');
        uint qty = holders[_msgSender()];
        require(claimSupply > quantity, "Claim over");
        require(nonce + quantity <= totalSupply, "sold out");
        require(quantity <= qty, "You can't claim that amount");
        holders[_msgSender()] -= quantity;
        claimSupply -= quantity;
        _create(_msgSender(), quantity);
    }
    
    function giveaway(address to, uint qty, bool fromHolders) external onlyOwner {
        require(nonce + qty <= totalSupply, "sold out");
        if(fromHolders){
             require(claimSupply >= qty, "Claim over");
             claimSupply -= qty;
        }
        _create(to,qty);
        
    }
    
    function _create(address to, uint qty) internal {
        for(uint i = 0; i < qty; i++){
            nonce++;
            _safeMint(to, nonce);
        }
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}