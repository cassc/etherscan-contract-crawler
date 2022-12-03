// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/IERC721A.sol";

interface ISoulAether is IERC721A {
    function airdrop(address[] calldata _addresses) external;
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}

contract SAEProxy is Ownable {
    ISoulAether saeContract;

    uint256 public constant cost = 0.049 ether;
    uint16 public constant maxSupply = 999;
    uint8 public constant maxPerMint = 3;
    uint256 public startTime;

    constructor(address _saeContract, uint256 _startTime){
        saeContract = ISoulAether(_saeContract);
        startTime = _startTime;
    }

    modifier mintable(uint256 _mintAmount) {
        require(tx.origin == msg.sender, "Contracts are unable to mint");
        require(block.timestamp >= startTime || msg.sender == owner(), "Mint has not yet started");
        require(msg.value >= cost * _mintAmount, "Invalid amount of ETH sent");
        require(saeContract.totalSupply() + _mintAmount <= maxSupply, "Amount exceeds max supply");
        require(_mintAmount <= maxPerMint, "Cannot mint more than the max");
        _;
    }

    function publicMintAirdrop(address[] calldata _addresses) external payable mintable(_addresses.length) {
        saeContract.airdrop(_addresses);
    }

    function transferSAEOwnership(address _newOwner) external onlyOwner {
        require(saeContract.owner() == address(this), "This contract is no longer the owner!");

        saeContract.transferOwnership(_newOwner);
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }
}