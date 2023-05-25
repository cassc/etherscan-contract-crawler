// SPDX-License-Identifier: MIT
//         _              _                    _              _      _              
//        /\_\           / /\                 /\ \           /\ \   /\_\            
//       / / /  _       / /  \                \ \ \          \ \ \ / / /         _  
//      / / /  /\_\    / / /\ \               /\ \_\         /\ \_\\ \ \__      /\_\
//     / / /__/ / /   / / /\ \ \             / /\/_/        / /\/_/ \ \___\    / / /
//    / /\_____/ /   / / /  \ \ \           / / /  _       / / /     \__  /   / / / 
//   / /\_______/   / / /___/ /\ \         / / /  /\ \    / / /      / / /   / / /  
//  / / /\ \ \     / / /_____/ /\ \       / / /   \ \_\  / / /      / / /   / / /   
// / / /  \ \ \   / /_________/\ \ \  ___/ / /__  / / /_/ / /      / / /___/ / /    
/// / /    \ \ \ / / /_       __\ \_\/\__\/_/___\/ / /__\/ /      / / /____\/ /     
//\/_/      \_\_\\_\___\     /____/_/\/_________/\/_______/       \/_________/      
//                                                                                 
//
//        /\_\            /\ \       /\ \     _    /\ \         /\ \       
//       / / /  _         \ \ \     /  \ \   /\_\ /  \ \       /  \ \      
//      / / /  /\_\       /\ \_\   / /\ \ \_/ / // /\ \_\   __/ /\ \ \     
//     / / /__/ / /      / /\/_/  / / /\ \___/ // / /\/_/  /___/ /\ \ \    
//    / /\_____/ /      / / /    / / /  \/____// / / ______\___\/ / / /    
//   / /\_______/      / / /    / / /    / / // / / /\_____\     / / /     
//  / / /\ \ \        / / /    / / /    / / // / /  \/____ /    / / /    _ 
// / / /  \ \ \   ___/ / /__  / / /    / / // / /_____/ / /     \ \ \__/\_\
/// / /    \ \ \ /\__\/_/___\/ / /    / / // / /______\/ /       \ \___\/ /
//\/_/      \_\_\\/_________/\/_/     \/_/ \/___________/         \/___/_/ 
//An Augminted Labs Project - RWASTE IS A UTILITY TOKEN FOR THE KAIJU KINGS ECOSYSTEM.
//$RWASTE is NOT an investment and has NO economic value. 
//It will be earned by active holding within the Kaiju Kingz ecosystem. Each Genesis Kaiju will be eligible to claim tokens at a rate of 5 $RWASTE per day.


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface iKaijuKingz {
    function balanceGenesis(address owner) external view returns(uint256);
}

contract RadioactiveWaste is ERC20, Ownable {

    iKaijuKingz public KaijuKingz;

    uint256 constant public BASE_RATE = 5 ether;
    uint256 public START;
    bool rewardPaused = false;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    mapping(address => bool) public allowedAddresses;

    constructor(address kaijuAddress) ERC20("RadioactiveWaste", "RWASTE") {
        KaijuKingz = iKaijuKingz(kaijuAddress);
        START = block.timestamp;
    }

    function updateReward(address from, address to) external {
        require(msg.sender == address(KaijuKingz));
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

    // !ooh
    function claimLaboratoryExperimentRewards(address _address, uint256 _amount) external {
        require(!rewardPaused,                "Claiming reward has been paused"); 
        require(allowedAddresses[msg.sender], "Address does not have permission to distrubute tokens");
        _mint(_address, _amount);
    }

    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender] || msg.sender == address(KaijuKingz), "Address does not have permission to burn");
        _burn(user, amount);
    }

    function getTotalClaimable(address user) external view returns(uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns(uint256) {
        return KaijuKingz.balanceGenesis(user) * BASE_RATE * (block.timestamp - (lastUpdate[user] >= START ? lastUpdate[user] : START)) / 86400;
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }
}