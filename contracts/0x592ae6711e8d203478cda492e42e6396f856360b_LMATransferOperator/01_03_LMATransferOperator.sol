// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

error onlyAllowList();

interface ERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract LMATransferOperator is Ownable {
    mapping(address => bool) private _allowlist;
    
    ERC721 private _lmaContract;
    address private _lmaDeployer;

    constructor(ERC721 lmaContract, address lmaDeployer, address allowListedAddress) {
        _lmaContract = lmaContract;
        _lmaDeployer = lmaDeployer;
        _allowlist[allowListedAddress] = true;
    }
    
    function addToAllowlist(address user) external onlyOwner {
        _allowlist[user] = true;
    }
    
    function removeFromAllowlist(address user) external onlyOwner {
        _allowlist[user] = false;
    }
    
    function bulkTransfer(address to, uint256[] memory tokenIds) external {
        if(!_allowlist[msg.sender]) revert onlyAllowList();

        for (uint i = 0; i < tokenIds.length; i++) {
            _lmaContract.transferFrom(_lmaDeployer, to, tokenIds[i]);
        }
    }
}