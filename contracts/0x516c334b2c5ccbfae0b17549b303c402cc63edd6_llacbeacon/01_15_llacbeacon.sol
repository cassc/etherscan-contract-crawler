// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./llacfm.sol";
contract llacbeacon  {
    address owner;
    constructor() {
        owner = msg.sender;
    }
    function createNFTContract(string memory name_,string memory symbol_,string memory title_,string memory description_,string memory ipfs_,uint256 supply_) public returns(address){
        require(msg.sender == owner);
        llacfm Llacfm = new llacfm(name_,symbol_,title_,description_,ipfs_,supply_);
        address nfadd = address(Llacfm);
        return nfadd;
    }
    function mint(address cont,address user) public returns(uint256){
        require(msg.sender == owner);
        llacfm Llacfm = llacfm(cont);
        uint256 newItemId = Llacfm.mint(user);
        return newItemId;
    }
    function addlist(address cont,address to) public {
        require(msg.sender == owner);
        llacfm Llacfm = llacfm(cont);
        Llacfm._SetList(to);
    }
    function dellist(address cont,uint256 id) public {
        require(msg.sender == owner);
        llacfm Llacfm = llacfm(cont);
        Llacfm._DelList(id);
    }
}