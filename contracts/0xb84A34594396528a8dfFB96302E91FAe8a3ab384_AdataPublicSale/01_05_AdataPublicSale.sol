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

contract AdataPublicSale is Ownable, Pausable, ReentrancyGuard {
    address public _tokenAddress;
    uint256 public _startTime;
    uint256 public _endTime;
    uint256 public _price;

    constructor() {
        _pause();
        _startTime = 1673971200; // Jan 18, 2023 00:00:00 AM GMT+08:00
        _endTime = 1673971201; // Jan 18, 2022 00:00:00 AM GMT+08:00
        _price = 1 ether;
    }

    function info() public view returns (uint256[] memory) {
        uint256[] memory info_ = new uint256[](3);
        info_[0] = _startTime;
        info_[1] = _endTime;
        info_[2] = _price;
        return info_;
    }

    function remain() public view returns (uint256) {
        return NFT(_tokenAddress).maxSupply() - NFT(_tokenAddress).totalSupply();
    }

    function buy() external payable nonReentrant whenNotPaused {
        require(msg.sender == tx.origin, "Runtime error: contract not allowed");
        require(
            block.timestamp > _startTime,
            "Runtime error: public sale not started"
        );
        require(
            block.timestamp < _endTime,
            "Runtime error: sale ends"
        );
        require(msg.value >= _price, "Runtime error: ether value not enough");
        NFT(_tokenAddress).mint(msg.sender, 1);
    }

    function setTokenAddress(address tokenAddress) external onlyOwner {
        _tokenAddress = tokenAddress;
    }

    function setAuction(
        uint256 startTime_,
        uint256 endTime_,
        uint256 price_
    ) external onlyOwner {
        _startTime = startTime_;
        _endTime = endTime_;
        _price = price_;
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