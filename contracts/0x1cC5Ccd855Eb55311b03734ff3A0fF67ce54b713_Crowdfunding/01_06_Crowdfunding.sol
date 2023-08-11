//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";
import './Project.sol';

contract Crowdfunding is Ownable {
   mapping (address => uint256) public rewards;
   mapping (address => uint256) public totalRewards;
   mapping (IERC20 => bool) public acceptedTokens;
   // mapping (IERC20 => bool) public rewardTokenAddresses;
   IERC20[] public rewardTokenAddresses;
   mapping (IERC20 => uint256[4]) public rewardTokensTiers;
   // uint256[4] rewardTiers = [8e17, 2e18, 3e18, 5e18];

   struct ProjectArray {
      address projectAddress;
      string title;
      string descriptions;
      uint256 contributedAmount;
   }

   // Requirements
   // [X] Can create project
   // [X] Can donate to project
   // [X] User must be able to donate in stable coins USDT, USDC BUSD, DAI (Made it extensible by whitelist)
   // [X] Test set project to visible
   // [X] Test set project to verified  
   // [X] Admin must be able to earn 2% on each project raise. 
   // [X] Developer must be able to earn 1% on each project raise during set grace period
   // [X] Admin must be able to earn 1% on each project raise during set grace period
   // [X] Users must be able to earn token rewards according to the network they contribute on. (Made it extensible by whitelist)
   // [X] Rewards are tiered according to contribution
   // [X] User must be able to withdraw their share of rewards
   // [X] Creator must be able to request for withdrawal 
   // [X] Withdrawal threshold lowered to 20%
   // [X] Creator must be able to withdraw funds donated their projects to the recipient wallet set during project creation
   // [X] Fees accrued to admin will be sent directly to wallet whenever project funds are withdrawn by creators
   // [X] Admin must be able to withdraw pooled rewards that are sent to the smart contract
   // [X] Tiered reward rules needs to be mutable

   event ProjectStarted(
      address projectContractAddress,
      address creator,
      uint256 projectDeadline,
      uint256 goalAmount,
      uint256 currentAmount,
      uint256 noOfContributors,
      string title,
      string desc,
      uint256 currentState, 
      string websiteUrl, 
      string socialUrl, 
      string projectCoverUrl, 
      string filterTags
   );

   event ContributionReceived(
      address projectAddress,
      uint256 contributedAmount,
      address indexed contributor
   );

   Project[] private projects;

   // @dev Anyone can start a fund rising
   // @return null
   function createProject(
      uint256 deadline,
      uint256 targetContribution,
      string memory projectTitle,
      string memory projectDesc,
      string memory websiteUrl, 
      string memory socialUrl, 
      string memory githubUrl, 
      string memory projectCoverUrl, 
      string memory filterTags,
      address usdt,
      address usdc
   ) public {

      Project newProject = new Project(owner(), msg.sender, address(this),  usdt, usdc, deadline, targetContribution, projectTitle, projectDesc, websiteUrl, socialUrl, githubUrl, projectCoverUrl, filterTags);
      projects.push(newProject);
   
      emit ProjectStarted(
         address(newProject) ,
         msg.sender,
         deadline,
         targetContribution,
         0,
         0,
         projectTitle,
         projectDesc,
         0, 
         websiteUrl, 
         socialUrl, 
         projectCoverUrl, 
         filterTags
      );
   }

   function addAcceptedContributionToken(IERC20 tokenAddress) onlyOwner external {
      acceptedTokens[tokenAddress] = true;
   }


   function removeAcceptedContributionToken(IERC20 tokenAddress) onlyOwner external {
      acceptedTokens[tokenAddress] = false;
   }

   //For admin to set reward token address
   function addRewardTokenAddress(IERC20 tokenAddress) onlyOwner external {
      rewardTokenAddresses.push(tokenAddress);
   }

   function removeRewardTokenAddress(uint rewardTokenAddressesIndex) onlyOwner external {
      delete rewardTokenAddresses[rewardTokenAddressesIndex];
   }

   // @dev Get projects list
   // @return array
   function returnAllProjects() external view returns(Project[] memory){
      return projects;
   }

   function addRewardTokenTier(IERC20 tokenAddress, uint256[4]  memory rewardTiers) onlyOwner external {
      rewardTokensTiers[tokenAddress] = rewardTiers;
   }

   //Calculate rewards eligible based on contribution amount
   function getRewards(uint256 amount, IERC20 rewardTokenAddress) internal view returns(uint256) {
      //get chainId (block.chainid)
      if(amount >= 3e18 && amount <= 5e18) {
         return rewardTokensTiers[rewardTokenAddress][0];
      }

      if(amount > 5e18 && amount <= 10e18) {
         return rewardTokensTiers[rewardTokenAddress][1];
      }

      if(amount > 10e18 && amount <= 50e18) {
         return rewardTokensTiers[rewardTokenAddress][2];
      }

      if(amount > 50e18 ) {
         return rewardTokensTiers[rewardTokenAddress][3];
      }

      return 0;

      // on Matic chain(usdt, usdc, dai)
      // 1. Donate $3 - 5 to get 0.8 MATIC
      // 2. Donate $5 - 10 to get 2 MATIC
      // 3. Donate $10 - 50 to get 3 MATIC
      // 4. Donate $51 - 100 to get 5 MATIC


      // On optimism chain (USDT/USDC)
      // 1. Donate $3 - 5 to get 0.2 OP Tokens
      // 2. Donate $5 - 10 to get 0.9 OP Tokens
      // 3. Donate $10 - 50 to get 2 OP Tokens
      // 4. Donate $51 - 100 to get 4 OP tokens


      // On binance chain. (USDT, USDC, BUSD)
      // 1. Donate $3 - 5 to get 0.002 BNB
      // 2. Donate $5 - 10 to get 0.003 BNB
      // 3. Donate $10 - 50 to get 0.005 BNB
      // 4. Donate $51 - 100 to get 0.08.BNB


      // on ethereum chain. (USDT, USDC, DAI, ETH)
      // 1. Donate $3 - 5 to get 0.001073 ETH Tokens
      // 2. Donate $5 - 10 to get 0.001127 ETH Tokens
      // 3. Donate $10 - 50 to get 009 ETH Tokens
      // 4. Donate $51 - 100 to get 0.005366 ETH tokens

      // On Arbitrum chain. (USDT, USDC)
      // 1. Donate $3 - 5 to get 0.8 ARB
      // 2. Donate $5 - 10 to get 1 ARB
      // 3. Donate $10 - 50 to get 2 ARB
      // 4. Donate $51 - 100 to get 5 ARB


      // On ZKSYNC ERA chain. (USDT, USDC)
      // 1. Donate $3 - 5 to get  0.0003805 ETH
      // 2. Donate $5 - 10 to get 0.0005433 ETH
      // 3. Donate $10 - 50 to get 0.010 ETH
      // 4. Donate $51 - 100 to get 0.011 ETH
   }


   //To update rewards when successful contribution is made
  function updateRewards(address contributor, uint256 amount, IERC20 contributedToken) internal {
         rewards[contributor] +=  getRewards(amount, contributedToken);
         totalRewards[contributor] +=  getRewards(amount, contributedToken);
         
   }
   
   //rewards
   function showRewardUser(address contributor) public view returns (uint256){
      return rewards[contributor];      
   }

   //total Rewards
   function showTotalRewardUser(address contributor) public view returns (uint256){
      return totalRewards[contributor];      
   }

   // @dev Get 
   // @return array
   function getContributedProject() external view returns(ProjectArray[] memory){
      ProjectArray[] memory project = new ProjectArray[](projects.length);
      uint256 i;
      uint256 j=0;
      for(i = 0; i < projects.length; i ++) {
         
         uint256 _amount = projects[i].contributiors(msg.sender);
         if(_amount > 0){
            project[j] = ProjectArray(address(projects[i]), projects[i].projectTitle(), projects[i].projectDes(), _amount);
            j ++;
         }
      }
      return project;
   }

   // //For user to withdraw accumulated rewards
   // function withdrawUserRewards(uint256 amount, IERC20 tokenAddress) external {
   //    require(tokenAddress.balanceOf(address(this)) >= amount, 'Insufficient balance in pool to pay out rewards');
   //    require(rewards[msg.sender] >= amount, 'Insufficient balance to withdraw from pool');
   //    tokenAddress.transferFrom(address(this), msg.sender, amount);
   // }

   // For user to withdraw accumulated bnb rewards
   function withdrawUserRewards(uint256 amount) external {
      require((address(this)).balance >= amount, 'Insufficient balance in pool to pay out rewards');
      require(rewards[msg.sender] >= amount, 'Insufficient balance to withdraw from pool');
      payable(msg.sender).transfer(amount);
      rewards[msg.sender] -= amount;
   }

   function withdrawPooledRewards(uint256 amount, address recipientAddress,IERC20 tokenAddress) onlyOwner external {
      require(tokenAddress.balanceOf(address(this)) >= amount, 'Insufficient balance in pool to withdraw rewards');
      tokenAddress.transferFrom(address(this), recipientAddress, amount);
   }

   // @dev User can contribute
   // @return null

   function contribute(address _projectAddress, IERC20 token, uint256 amount) public{
      //Contribute to project
      Project.State projectState = Project(_projectAddress).state();
      require(projectState == Project.State.Fundraising, 'Invalid state');
      require(acceptedTokens[token], 'Token not accepted');
      Project(_projectAddress).contribute(msg.sender, amount, token);

      //Update user rewards
      updateRewards(msg.sender, amount, token);

      emit ContributionReceived(_projectAddress, amount, msg.sender);
   }
   
   /// @dev REMOVE WHEN DEPLOYING
   fallback() external payable {}
}