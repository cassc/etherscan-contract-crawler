// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MONWU is ERC20, Ownable {

  uint256 public cap = 1_000_000_000 * (10**decimals());
  uint256 public burned = 0;

  // allocations
  uint256 public constant foundersAllocation = 100_000_000;
  uint256 public constant marketingAllocation = 50_000_000;
  uint256 public constant developmentAllocation = 50_000_000;
  uint256 public constant privateSaleAllocation = 150_000_000;
  uint256 public constant publicSaleAllocation = 100_000_000;
  uint256 public constant liquidityPoolAllocation = 100_000_000;
  uint256 public constant stakingAllocation = 200_000_000;
  uint256 public constant rewardsAllocation = 250_000_000;


  bool public foundersVestingInitialized;
  bool public marketingVestingInitialized;
  bool public developmentVestingInitialized;
  bool public privateSaleInitialized;
  bool public publicSaleInitialized;
  bool public poolInitialized;
  bool public stakingInitialized;
  bool public rewardsInitialized;


  constructor() ERC20("MONWU Token", "MONWU") {
    transferOwnership(0xa3152e1FCbB08C6e08D30006c03E693F31c2C89f);
  }


  // ====================================================================================
  //                               PUBLIC INTERFACE
  // ====================================================================================
  function burn(uint256 amount) external {
    require(cap - amount >= 500_000_000 * (10**decimals()), "Minimal cap reached");
    cap -= amount;
    burned += amount;
    _burn(_msgSender(), amount);
  }
  // ====================================================================================


  // ====================================================================================
  //                               OWNER INTERFACE
  // ====================================================================================
  function initializeFoundersVesting(address foundersVestingContract) external onlyOwner {
    require(foundersVestingInitialized == false, "Vesting already initialized");

    uint256 amount = foundersAllocation * (10**decimals());
    foundersVestingInitialized = true;
    internalMint(foundersVestingContract, amount);
  }

  function initializeMarketingVesting(address marketingVestingContract) external onlyOwner {
    require(marketingVestingInitialized == false, "Marketing vesting already initialized");

    uint256 amount = marketingAllocation * (10**decimals());
    marketingVestingInitialized = true;
    internalMint(marketingVestingContract, amount);
  }

  function initializeDevelopmentVesting(address developmentVestingContract) external onlyOwner {
    require(developmentVestingInitialized == false, "Development vesting already initialized");

    uint256 amount = developmentAllocation * (10**decimals());
    developmentVestingInitialized = true;
    internalMint(developmentVestingContract, amount);
  }

  function initializePrivateSale(address privateSaleVestingContract) external onlyOwner {
    require(privateSaleInitialized == false, "Private sale already initialized");

    uint256 amount = privateSaleAllocation * (10**decimals());
    privateSaleInitialized = true;
    internalMint(privateSaleVestingContract, amount);
  }

  function initializePublicSale(address publicSaleAddress) external onlyOwner {
    require(publicSaleInitialized == false, "Public sale already initialized");

    uint256 amount = publicSaleAllocation * (10**decimals());
    publicSaleInitialized = true;
    internalMint(publicSaleAddress, amount);
  }

  function initializePool(address poolInitializer) external onlyOwner {
    require(poolInitialized == false, "Pool already initialized");

    uint256 amount = liquidityPoolAllocation * (10**decimals());
    poolInitialized = true;
    internalMint(poolInitializer, amount);
  }

  function initializeStaking(address stakingContract) external onlyOwner {
    require(stakingInitialized == false, "Staking already initialized");

    uint256 amount = stakingAllocation * (10**decimals());
    stakingInitialized = true;
    internalMint(stakingContract, amount);
  }

  function initializeRewards(address rewardsContract) external onlyOwner {
    require(rewardsInitialized == false, "Rewards already initialized");
    
    uint256 amount = rewardsAllocation * (10**decimals());
    rewardsInitialized = true;
    internalMint(rewardsContract, amount);
  }
  // ====================================================================================



  // ====================================================================================
  //                                   HELPERS
  // ====================================================================================
  function internalMint(address to, uint256 amount) internal {
    require(totalSupply() + amount <= cap, "ERC20Capped: cap exceeded");
    _mint(to, amount);
  }
  // ====================================================================================

}