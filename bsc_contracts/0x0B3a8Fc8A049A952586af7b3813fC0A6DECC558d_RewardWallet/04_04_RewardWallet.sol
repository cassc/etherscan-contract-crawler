// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardWallet is Ownable {
   
   uint256 public totalDeposited; 
   address public deployer;
   IERC20 public rewardToken;

   event Deposit(address user, uint256 amount);
   event Withdrawal(address user, uint256 amount);
   event LogWithdrawalBNB(address account, uint256 amount);
   event LogWithdrawToken(address token, address account, uint256 amount);
   event LogUpdateDeployerAddress(address newDeployer);

   /** 
     * @dev Throws if called by any account other than the deployer.
     */
   modifier onlyDeployer() {
       require(deployer == _msgSender(), "Caller is not the deployer");
       _;
   }
   
   constructor(address _rewardToken, address _stakingContract){
      require(_rewardToken != address(0), "RewardToken Address 0 validation");
      require(_stakingContract != address(0), "StakingContract Address 0 validation");
      deployer = _msgSender();
      rewardToken = IERC20(_rewardToken);

      //transferOwnership
      transferOwnership(_stakingContract);
   }

   function deposit(uint256 amount) external onlyDeployer{
      require(amount > 0, "Cant be 0");
      require(rewardToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance.");

      totalDeposited += amount;
      rewardToken.transferFrom(msg.sender, address(this), amount);

      emit Deposit(msg.sender, amount);
   }

   function transfer(address account, uint256 amount) external onlyOwner{
      require(amount > 0, "Cant be 0");
      require(amount <= totalDeposited, "Insufficient funds");

      totalDeposited -= amount;
      rewardToken.transfer(account, amount);

      emit Withdrawal(account, amount);
   }

   function getTotalDeposited() external view returns(uint256){
      return totalDeposited;
   }

   function withdrawBNB(address payable account, uint256 amount) external onlyDeployer {
      require(amount <= (address(this)).balance, "Incufficient funds");
      safeTransferBNB(account, amount);
      emit LogWithdrawalBNB(account, amount);
   }

   // Internal function to handle safe transfer
   function safeTransferBNB(address to, uint256 value) internal {
      (bool success, ) = to.call{value: value}(new bytes(0));
      require(success);
   }

   function withdrawToken(address token, address account, uint256 amount) external onlyDeployer {
      require(amount <= IERC20(token).balanceOf(account), "Incufficient funds");
      if(token == address(rewardToken)){
         require(amount <= totalDeposited, "Incufficient funds");
         totalDeposited -= amount;
      }
      IERC20(token).transfer(account, amount);
      emit LogWithdrawToken(token, account, amount);
   }

   function updateDeployerAddress(address newDeployer) external onlyDeployer{
      require(deployer != newDeployer, "Already set to this value");
      require(newDeployer != address(0), "Address 0 validation");
      deployer = newDeployer;
      emit LogUpdateDeployerAddress(newDeployer);
   }
}