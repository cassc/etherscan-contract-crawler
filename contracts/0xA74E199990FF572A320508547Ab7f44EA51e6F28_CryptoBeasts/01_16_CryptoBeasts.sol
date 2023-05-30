pragma solidity ^0.7.3;

import "./NFT.sol";

contract CryptoBeasts is NFT {
    using SafeMath for uint256;
    
    constructor() NFT(
        "CryptoBeasts",
        "rare-eggs",
        "87d13e0e44453b2ed9195eec21af62451a07d811de8ca593d507ee06f01744a4",
        100000000000000000 wei,
        10000,
        2000,
        "ipfs://QmTMSCeXsgexBYj7pNjarzzRe1fZK6P7B9uMCv61BwakSX/") {
    }
    
    function becomeEggLord() public payable{
        uint numberOfTokens = 10;
        
        require(_price.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        require(totalSupply().add(numberOfTokens) <= _max_supply, "Minting would exceed max supply");
        
         uint[10] memory eggTypes = [uint(0), 0, 0, 0, 0, 0, 0, 0, 0, 0];
         uint tokensMinted = 0;
         
         uint i = _current_purchase_index;
         
         while(i < _max_supply){
             uint eggType = getEggType(i);
             
             if (tokensMinted == numberOfTokens){
                 return;
             }
             else if (!_exists(i) && eggTypes[eggType] == 0){
                _secureMint(msg.sender, i);
                tokensMinted = tokensMinted.add(1);
                eggTypes[eggType] = 1;
                i = ((i / 100)+1) * 100;
             }
             else{
                i++;
             }
         }
         
         require(tokensMinted == numberOfTokens, "Not enough tokens to become Egg Lord");
    }
    
    function getEggType(uint eggNumber) public view virtual returns (uint){
        return (eggNumber % 1000) / 100;
    }
    
    
    function getEggTypeSupply() public view virtual returns (uint[10] memory) {
        uint[10] memory eggTypeSupply = [uint(0), 0, 0, 0, 0, 0, 0, 0, 0, 0];
        
        for (uint i = 0; i < _max_supply; i++){
            if (_exists(i)){
                uint eggType = getEggType(i);
                eggTypeSupply[eggType] += 1;
            }
        }
        
        return eggTypeSupply;
    }
}