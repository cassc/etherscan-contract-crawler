pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract DosaVault is Initializable{

    mapping(address => bool) public topHolder;
    mapping(address => bool) public hasClaimed;

    address public factoryAddr;
    address public vault_token;
    
    uint256 public totalRewards;
    uint256 public topHoldersCount;

    event TopHoldersUpdated();
    event Claimed(address indexed user, uint256 amount);

    modifier onlyFactory() {
        require(msg.sender == factoryAddr);
        _;
    }

    function initialize(address _vault_token, address[] calldata users, uint256 rewardsAmt) public initializer returns(bool){
        vault_token = _vault_token;
        factoryAddr = msg.sender;
        _setTopHoldersAtInit(users);
        totalRewards = rewardsAmt;
        return true;
    }

    function _setTopHoldersAtInit(address[] calldata users) internal {
        uint256 size = users.length;
        for (uint256 i = 0; i < size;) {
            topHolder[users[i]] = true;
            unchecked { ++i;}
        }
        topHoldersCount += size;
    }

    function updateTopHolders(address[] calldata users, bool isTop) external onlyFactory {
        uint256 size = users.length;
        for (uint256 i = 0; i < size;) {
            topHolder[users[i]] = isTop;
            if(isTop) {
                topHoldersCount++;
            } else {
                topHoldersCount--;
            }
            unchecked { ++i;}
        }
        emit TopHoldersUpdated();
    }

    function rewardsPerUser() public view returns(uint256) {
        return totalRewards / topHoldersCount;
    }

    function claim() external {
        require(topHolder[msg.sender], "Only top holders can claim");
        require(totalRewards > 0, "No rewards to claim");
        require(!hasClaimed[msg.sender], "You have already claimed");
        hasClaimed[msg.sender] = true;
        uint256 amount = rewardsPerUser();
        IERC20(vault_token).transfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    function getRewardsClaimablePerUser(address user) external view returns(uint256) {
        if(!topHolder[user]) return 0;
        else if(hasClaimed[user]) return 0;
        else return rewardsPerUser();
    }

    function rescueTokens(address recipient, address tokenAddr, uint256 amount) external onlyFactory {
        IERC20(tokenAddr).transfer(recipient, amount);
    }

}