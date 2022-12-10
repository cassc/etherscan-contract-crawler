//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

 contract XCBDistribution is Ownable, ReentrancyGuard {

    using SafeMath for uint256;
    
    IERC20 private token;
    uint256 public lastDistribution;
    address[] public receptors;

    struct Distribution {
        uint256 timestamp;
        uint256 amount;
    }

    mapping(address => Distribution[]) public distributionHistory;

    event DistributionAssigned();
    event TokensClaimed(uint256 timestamp, address user, uint256 amount);
    event OwnerWithdrawed(uint256 amount);

    constructor (address addr) {
        token = IERC20(addr);
    }

    function makeDistribution (uint256[] memory amounts, address[] memory users) external onlyOwner{
        require(amounts.length == users.length, "Some distributions are not assigned");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        require(token.balanceOf(msg.sender) >= totalAmount, "Not enough funds to distribute");
        bool inside = false;
        for (uint256 j = 0; j < users.length; j++) {
            Distribution memory newDistribution = Distribution({
                timestamp: block.timestamp,
                amount: amounts[j]
            });
            distributionHistory[users[j]].push(newDistribution);
            if(receptors.length > 0) {
                for(uint256 k = 0; k < receptors.length; k++) {
                    if(users[j] == receptors [k]) {
                        inside = true;
                    }
                }
                if(!inside) {
                    receptors.push(users[j]);
                }
            } else {
                receptors.push(users[j]);
            }
        }

        token.transferFrom(msg.sender, address(this), totalAmount);
        lastDistribution = block.timestamp;

        emit DistributionAssigned();
    }

    function claim () external nonReentrant {
        Distribution[] storage myDistributions = distributionHistory[msg.sender];
        require(myDistributions.length > 0, "No pending distributions");

        uint256 amountToTransfer = 0;
        uint256 amountToReturn = 0;

        for (uint256 i = 0; i < myDistributions.length; i++) {
            if(myDistributions[i].timestamp + 90 days > block.timestamp){
                amountToTransfer = amountToTransfer.add(myDistributions[i].amount);
            }else{
                amountToReturn = amountToReturn.add(myDistributions[i].amount);
            }
        }
        delete distributionHistory[msg.sender];

        uint256 j = 0;
        uint256 index = receptors.length;
        while((j < receptors.length) && (index == receptors.length)) {
            if(msg.sender == receptors[j]) {
                index = j;
            }
            j++;
        }

        if(index != receptors.length - 1) {
            receptors[index] = receptors[receptors.length - 1];
        }
        receptors.pop();

        token.transfer(msg.sender, amountToTransfer);
        token.transfer(owner(), amountToReturn);

        emit TokensClaimed(block.timestamp, msg.sender, amountToTransfer);
    }

    function getDistributions(address user) external view returns (Distribution[] memory) {
        return distributionHistory[user];
    }

    function withdraw () external onlyOwner {
        require(lastDistribution + 90 days < block.timestamp, "Distributions are not out of date yet");

        for(uint256 i = 0; i < receptors.length; i++) {
            delete distributionHistory[receptors[i]];
        }
        while(receptors.length > 0) {
            receptors.pop();
        }

        uint256 contractBalance = token.balanceOf(address(this));
        token.transfer(owner(), contractBalance);

        emit OwnerWithdrawed(contractBalance);
    }
}