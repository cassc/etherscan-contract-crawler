// contracts/Multisend.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Multisend is Ownable, ReentrancyGuard {

    IERC20 public token;
    address public distributor;
    mapping (address => uint256) public distribution;

    modifier onlyDistributor() {
        require(
            distributor == msg.sender,
            "Only distributor can add or process"
        );
        _;
    }    

    constructor(address tokenAddress_, address distributor_) {
        token = IERC20(tokenAddress_);
        distributor = distributor_;
    }      

    function setTokenAddress(address tokenAddress_) external onlyOwner {
        token = IERC20(tokenAddress_);
    }

    function setDistributor(address distributor_) external onlyOwner {
        distributor = distributor_;
    }
    
    function withdrawTokens(address beneficiary_, uint256 amount_) external onlyOwner {
        token.transfer(beneficiary_,amount_);
    }

    function loadDistribution(address[] memory addresses_, uint256[] memory amounts_) external nonReentrant onlyDistributor {
        require(addresses_.length == amounts_.length, "Lenghts not equal");
        for (uint i = 0; i < addresses_.length; i++) {
            distribution[addresses_[i]] = amounts_[i];
        }
    }
    function processDistribution(address[] memory addresses_) external nonReentrant onlyDistributor {
        for (uint i = 0; i < addresses_.length; i++) {
            address destination = addresses_[i];
            token.transfer(destination, distribution[destination]);
        }
    }

    function distributeTokens(address[] memory addresses_, uint256[] memory amounts_) external nonReentrant onlyDistributor {
        require(addresses_.length == amounts_.length, "Lenghts not equal");
        for (uint i = 0; i < addresses_.length; i++) {
            token.transfer(addresses_[i],amounts_[i]);
        }
    }
    

}