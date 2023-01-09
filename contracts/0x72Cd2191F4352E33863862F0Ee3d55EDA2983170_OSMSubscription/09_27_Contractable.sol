// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { SetContractable, ContractableData, AllowedContract, AllowedPath } from "./SetContractable.sol";
import "./Mintable.sol";


abstract contract Contractable is Mintable {  
    using SetContractable for ContractableData;
    ContractableData contractables;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {        
        super.transferFrom(from,to,tokenId);
        contractables.transferPath(from,to);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        super.safeTransferFrom(from,to,tokenId,data);
        contractables.transferPath(from,to);
    }         
    function balanceOfAllowance(address wallet) public view returns (uint256) {
        return contractables.balanceOfAllowance(wallet);
    }
    function allowances(address wallet) public view returns (AllowedContract [] memory) {
        return contractables.allowances(wallet);
    }
    function allowContract(
        address allowed, 
        string calldata urlPath, 
        string calldata erc, 
        string calldata guild, 
        uint256 balanceRequired, 
        bool isStaking, 
        bool isProxy) public {
        contractables.allowContract(allowed, urlPath, erc, guild, balanceRequired, isStaking, isProxy);
    }
    function pathAllows(string calldata path) public view returns (AllowedPath memory) {
        return contractables.pathAllows(path);
    }
    function revokePath(string calldata revoked) public {
        contractables.revokePath(revoked);
    }    
    function findGuildPath(string calldata guild) public view returns (AllowedPath memory) {
        return contractables.findGuildPath(guild);
    }    
}