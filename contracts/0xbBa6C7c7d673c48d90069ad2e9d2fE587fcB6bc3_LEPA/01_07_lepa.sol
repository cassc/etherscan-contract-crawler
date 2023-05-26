/*
Contract Security Audited by Certik : https://www.certik.org/projects/lepasa
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ArbitraryTokenStorage {
    function unlockERC(IERC20 token) external;
}

contract ERC20Storage is Ownable, ArbitraryTokenStorage {
    
    function unlockERC(IERC20 token) external override virtual onlyOwner{
        uint256 balance = token.balanceOf(address(this));
        
        require(balance > 0, "Contract has no balance");
        require(token.transfer(owner(), balance), "Transfer failed");
    }
}

contract LEPA is ERC20Burnable,ERC20Storage {
    bool mintCalled=false;
    
    address public StrategicBucketAddress;
    address public TeamBucketAddress;
    address public MarketingBucketAddress;
    address public AdvisersBucketAddress;
    address public FoundationBucketAddress;
    address public LiquidityBucketAddress;

    uint256 public constant StrategicLimit =  39 * (10**6) * 10**18;
    uint256 public constant PublicSaleLimit = 1 * (10**6) * 10**18;   
    uint256 public constant TeamLimit =  10 * (10**6) * 10**18; 
    uint256 public constant MarketingLimit =  25 * (10**6) * 10**18;
    uint256 public constant AdvisersLimit =  5 * (10**6) * 10**18;  
    uint256 public constant FoundationLimit =  10 * (10**6) * 10**18; 
    uint256 public constant LiquidityLimit = 10 * (10**6) * 10**18;   

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(_msgSender(), PublicSaleLimit);
    }

    function setAllocation(
        address strategicBucketAddress,
        address teamBucketAddress,
        address marketingBucketAddress,
        address advisersBucketAddress,
        address foundationBucketAddress,
        address liquidityBucketAddress
        ) external onlyOwner{
        require(mintCalled == false, "Allocation already done.");

        StrategicBucketAddress = strategicBucketAddress;
        TeamBucketAddress = teamBucketAddress;
        MarketingBucketAddress = marketingBucketAddress;
        AdvisersBucketAddress = advisersBucketAddress;
        FoundationBucketAddress = foundationBucketAddress;
        LiquidityBucketAddress = liquidityBucketAddress;
        
        _mint(StrategicBucketAddress, StrategicLimit);
        _mint(TeamBucketAddress, TeamLimit);
        _mint(MarketingBucketAddress, MarketingLimit);
        _mint(AdvisersBucketAddress, AdvisersLimit);
        _mint(FoundationBucketAddress, FoundationLimit);
        _mint(LiquidityBucketAddress, LiquidityLimit);

        mintCalled=true;
    }
}