//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPirates {
    function mint(uint256 _amount, address recipient) external;
}

contract PirateXBMFMinter is Ownable {
    
    IERC20 public paymentToken;
    IPirates public pirates;
    bool public paused;
    uint256 public mintPrice;
    uint256 public mintPriceStep;
    uint256 public counter;
    uint256 public step;
    uint256 public max;

    constructor(){
        paused = true;
        mintPrice = 100000 ether;
        mintPriceStep = 10000 ether;
        counter = 0;
        step = 100;
        max = 300;
    }

    function setPiratesContract(address _address) external onlyOwner {
        pirates = IPirates(_address);
    }

    function setPaymentTokenContract(address _address) external onlyOwner {
        paymentToken = IERC20(_address);
    }

    function setPaused(bool value) external onlyOwner {
        paused = value;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function resetCounter() external onlyOwner {
        counter = 0;
    }

    function setMax(uint256 newMax) external onlyOwner {
        max = newMax;
    }

    function setStep(uint256 newStep) external onlyOwner {
        step = newStep;
    }

    function mintPirateForToken(uint256 pirateCount, uint256 paymentAmount) external {
        require(counter < max - 1, "max mint reached");
        require(!paused, "Contract is paused");
        require(paymentAmount == pirateCount * mintPrice, "Purchase: Incorrect payment");
        require(paymentToken.transferFrom(msg.sender, address(this), paymentAmount),"Transfer of token could not be made");
        pirates.mint(pirateCount, msg.sender);
        counter += 1;
        if (counter % step == 0) {
            mintPrice += mintPriceStep;
        }
    }
    
    // Withdraw

    function withdraw() public payable onlyOwner {
        uint256 bal = address(this).balance;
        require(payable(msg.sender).send(bal));
    }

    function withdrawMintToken() public payable onlyOwner {
        uint256 bal = paymentToken.balanceOf(address(this));
        paymentToken.transfer(msg.sender, bal);
    }

    function withdrawToken(address _tokenAddress) public payable onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 bal = token.balanceOf(address(this));
        token.transfer(msg.sender, bal);
    }
}