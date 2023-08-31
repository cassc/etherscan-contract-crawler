// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract DogeCBTokenSale is Ownable, ReentrancyGuard {
    IERC20 public token;
    uint256 public rate;
    uint256 public maxPurchaseAmount;

    event TokensPurchased(address buyer, uint256 amount);
    event EtherWithdrawn(address owner, uint256 amount);
    event TokensWithdrawn(address owner, uint256 amount);
    event RateChanged(address owner, uint256 newRate);
    event MaxPurchaseAmountChanged(address owner, uint256 newMaxPurchaseAmount);

    constructor(IERC20 _token, uint256 _rate, uint256 _maxPurchaseAmount) {
        require(_rate > 0, "Invalid rate.");
        require(address(_token) != address(0), "Token address cannot be 0");

        token = _token;
        rate = _rate;
        maxPurchaseAmount = _maxPurchaseAmount;
        transferOwnership(msg.sender);
    }

    function buyTokens() external payable nonReentrant returns (bool) {
        require(msg.value * rate <= maxPurchaseAmount, "Cannot purchase more than the maximum allowed.");
        require(token.balanceOf(address(this)) >= msg.value * rate, "Contract does not have enough tokens.");

        uint256 tokensToBuy = msg.value * rate;
        
        token.transfer(msg.sender, tokensToBuy);

        emit TokensPurchased(msg.sender, tokensToBuy);

        return true;
    }

    // Allow contract to receive Ether
    receive() external payable {
    }

    function withdrawEther(uint256 _amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= _amount, "Contract does not have enough Ether to withdraw.");

        payable(owner()).transfer(_amount);

        emit EtherWithdrawn(msg.sender, _amount);
    }

    function withdrawTokens(uint256 _amount) external onlyOwner {
        require(_amount <= token.balanceOf(address(this)), "Not enough tokens.");

        token.transfer(msg.sender, _amount);

        emit TokensWithdrawn(msg.sender, _amount);
    }

    function setRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0, "Invalid rate.");

        rate = _newRate;

        emit RateChanged(msg.sender, _newRate);
    }

    function setMaxPurchaseAmount(uint256 _newMaxPurchaseAmount) external onlyOwner {
        maxPurchaseAmount = _newMaxPurchaseAmount;

        emit MaxPurchaseAmountChanged(msg.sender, _newMaxPurchaseAmount);
    }

    function getContractEtherBalance() public view returns(uint256) {
        return address(this).balance;
    }
}