// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DERANGEDPREMIUM is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public ethPerToken = 45015846000;

    event TokensClaimed(address indexed user, uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function swapEthForTokens() external payable {
        require(msg.value > 0, "No ETH sent");

        uint256 tokensToDistribute = msg.value.mul(10**18).div(ethPerToken);

        token.transfer(msg.sender, tokensToDistribute);

        emit TokensClaimed(msg.sender, tokensToDistribute);
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }

    function setEthPerToken(uint256 _ethPerToken) external onlyOwner {
        ethPerToken = _ethPerToken;
    }

    function addLiquidity(uint256 amount) external onlyOwner {
        require(token.transferFrom(owner(), address(this), amount), "Token transfer failed");
    }

    function addEthToContract() external payable {
        // Allows anyone to deposit ETH into the contract
    }

    function withdrawEth(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient ETH balance");
        payable(owner()).transfer(amount);
    }
}