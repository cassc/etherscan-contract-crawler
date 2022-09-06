// SPDX-License-Identifier: MIT
// $CIDER is NOT an investment and has NO economic value.
// Each Genesis Moose will be eligible to claim tokens at a rate of 10 $CIDER per day.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMoose {
    function balanceGenesis(address owner) external view returns(uint256);
}

contract Cider is ERC20, Ownable {

    IMoose public Moose;

    uint256 constant public BASE_RATE = 10 ether;
    uint256 public START;
    bool rewardPaused = false;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    mapping(address => bool) public allowedAddresses;

    constructor(address mooseAddress) ERC20("Cider", "CIDER") {
        Moose = IMoose(mooseAddress);
        START = block.timestamp; 
        _mint(msg.sender, 600_000 ether);
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(Moose));
        if(from != address(0)){
            rewards[from] += getPendingReward(from);
            lastUpdate[from] = block.timestamp;
        }
        if(to != address(0)){
            rewards[to] += getPendingReward(to);
            lastUpdate[to] = block.timestamp;
        }
    }

    function claimReward() external {
        require(!rewardPaused, "Claiming reward has been paused"); 
        _mint(msg.sender, rewards[msg.sender] + getPendingReward(msg.sender));
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
    }

    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender]  || msg.sender == address(Moose), "Address does not have permission to burn");
        _burn(user, amount);
    }

    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns(uint256) {
        return Moose.balanceGenesis(user) * BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) / 86400;
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function endRewards() public onlyOwner {
        rewardPaused = true;
    }
}