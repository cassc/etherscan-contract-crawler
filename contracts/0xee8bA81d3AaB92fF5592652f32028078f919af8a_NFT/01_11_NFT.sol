// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable { 
    
    string internal baseTokenURI = 'https://llko-backend.herokuapp.com/';
    uint public price = 0.06 ether;
    uint public totalSupply = 10000;
    uint public nonce = 0;
    uint public maxTx = 20;
    
    event Mint(address owner, uint qty);
    event Giveaway(address to, uint qty);
    event Withdraw(uint amount);
    event SetMember(address indexed member, uint percent);
    
    address[] public members;
    mapping (address => uint) public society;
    uint membersCount = 0;
    
    constructor() ERC721("Lucha Libre Knockout", "LLKO") {}
    
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
    
    // percent must be multiplied by 100. ex 1000 = 10%; 575 = 5.75%;
    function setMember(address member, uint percent) external onlyOwner {
        if(society[member] < 1){
            members.push(member);
            membersCount++;
        }
        if(society[member] > 0 && percent == 0){
            membersCount--;
        }
        society[member] = percent;
        emit SetMember(member, percent);
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
    
    function buy(uint qty) external payable {
        require(qty <= maxTx || qty < 1, "TRANSACTION: qty of mints not alowed");
        require(qty + nonce <= totalSupply, "SUPPLY: Value exceeds totalSupply");
        require(msg.value == price * qty, "PAYMENT: invalid value");
        for(uint i = 0; i < qty; i++){
            uint tokenId = nonce;
            _safeMint(_msgSender(), tokenId);
            nonce++;
        }
        emit Mint(_msgSender(), qty);
    }
    
    function withdrawOwner() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
    function withdraw() external onlyOwner {
        require(address(this).balance > price, "this account doesn't have enough balance");
        require(membersCount > 0, "WITHDRAW: couldn't find any payable address");
        uint nbalance = address(this).balance - 0.01 ether;
        address[] memory payments = new address[](membersCount);
        uint pmts=0;
        for(uint i=0; i < members.length;i++){
            address m = members[i];
            bool found = false;
            for(uint j=0; j < payments.length; j++){
                if(payments[j] == m){
                    found = true;
                    break;
                }
            }
            if(!found && society[m] > 0){
                payments[pmts] = m;
                pmts++;
                payable(m).transfer((nbalance * (society[m] / 100)) / 100);
            }
        }
    }
    
}