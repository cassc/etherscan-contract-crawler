// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface NFT {
    function mint(address to, uint256 quantity) external;
    function maxSupply() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract HotlinePublicSale is Ownable, Pausable, ReentrancyGuard {
    address public _tokenAddress;
    uint256 public _auctionStartTime;
    uint256 public _salePrice;

    constructor() {
        _pause();
        _auctionStartTime = 1667001600; // Oct 29, 2022 00:00:00 AM GMT+08:00
        _salePrice = 0.05 ether;
    }

    function buy() external payable nonReentrant whenNotPaused {
        require(msg.sender == tx.origin, "Runtime error: contract not allowed");
        require(
            block.timestamp > _auctionStartTime,
            "Runtime error: public sale not started"
        );
        require(
            msg.value >= _salePrice,
            "Runtime error: ether value not enough"
        );
        NFT(_tokenAddress).mint(msg.sender, 1);
    }

    function auctionStartTime() public view returns (uint256) {
        return _auctionStartTime;
    }

    function salePrice() public view returns (uint256) {
        return _salePrice;
    }

    function maxSupply() public view returns (uint256) {
        return NFT(_tokenAddress).maxSupply();
    }

    function totalSupply() public view returns (uint256) {
        return NFT(_tokenAddress).totalSupply();
    }

    function setTokenAddress(address tokenAddress) external onlyOwner {
        _tokenAddress = tokenAddress;
    }

    function setAuction(uint256 auctionStartTime_, uint256 salePrice_)
        external
        onlyOwner
    {
        _auctionStartTime = auctionStartTime_;
        _salePrice = salePrice_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw(address to) public onlyOwner {
        (bool sent, ) = to.call{value: address(this).balance}("");
        require(sent, "Runtime error: withdraw failed");
    }
}