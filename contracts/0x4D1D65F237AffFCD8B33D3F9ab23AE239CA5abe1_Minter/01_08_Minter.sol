// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "IERC721.sol";
import "IERC20.sol";
import "Pausable.sol";
import "Ownable.sol";


import "Policy.sol";

interface HealthPotion is IERC721 {
    function safeMint(address to, uint256 _policyDays, Policy.PolicyType _policyType) external;
}

contract Minter is Pausable, Ownable {
    address public healthPotionAddress;
    IERC20 public usdcContract;
    bool public earlyAccess;
    mapping(uint256 => Policy.PolicyPrice) prices;    // Policy length in days: Prices
    mapping(uint256 => uint256) limits;               // Supply limits for policies
    mapping(uint256 => uint256) supply;               // Current supply for policies

    constructor(address _healthPotionAddress, address _usdcAddress){
        _pause();
        healthPotionAddress = _healthPotionAddress;
        usdcContract = IERC20(_usdcAddress);
        earlyAccess = true;

        // 30 days (1 Month Policy)
        prices[30] = Policy.PolicyPrice({
            earlyUSDCPrice: 15 * 10 ** 6,
            publicUSDCPrice: 20 * 10 ** 6,
            earlyETHPrice: 15000000000000000,
            publicETHPrice: 20000000000000000
            });

        // 90 days (3 Month Policy)
        prices[90] = Policy.PolicyPrice({
            earlyUSDCPrice: 40 * 10 ** 6,
            publicUSDCPrice: 50 * 10 ** 6,
            earlyETHPrice: 40000000000000000,
            publicETHPrice: 50000000000000000
            });

        // 180 days (6 Month Policy)
        prices[180] = Policy.PolicyPrice({
            earlyUSDCPrice: 60 * 10 ** 6,
            publicUSDCPrice: 80 * 10 ** 6,
            earlyETHPrice: 60000000000000000,
            publicETHPrice: 80000000000000000
            });

        // 365 days (12 Month Policy)
        prices[365] = Policy.PolicyPrice({
            earlyUSDCPrice: 80 * 10 ** 6,
            publicUSDCPrice: 120 * 10 ** 6,
            earlyETHPrice: 80000000000000000,
            publicETHPrice: 120000000000000000
            });
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function sethealthPotionAddress(address _newAddress) public onlyOwner {
        healthPotionAddress = _newAddress;
    }

    function gethealthPotionAddress() public view returns (address) {
        return healthPotionAddress;
    }

    function toggleEarlyAccess(bool _earlyAccess) public onlyOwner {
        earlyAccess = _earlyAccess;
    }

    function getEarlyAccess() public view returns (bool) {
        return earlyAccess;
    }

    function getPolicyMax(uint256 _days) public view returns(uint256) {
        return limits[_days];
    }

    function setPolicyMax(uint256 _days, uint256 _maxSupply) public onlyOwner {
        limits[_days] = _maxSupply;
    }

    function getPrice(uint256 _days, Policy.PolicyType _policyType) 
        public 
        view 
        returns (uint256) 
    {
        Policy.PolicyPrice storage policy = prices[_days];
        require(policy.publicETHPrice != 0, "Could not find price for that time period");

        if (getEarlyAccess()) {
            if (_policyType == Policy.PolicyType.ETH) {
                return policy.earlyETHPrice;
            } else if (_policyType == Policy.PolicyType.USDC) {
                return policy.earlyUSDCPrice;
            }
        }
        if (_policyType == Policy.PolicyType.ETH) {
            return policy.publicETHPrice;
        } else if (_policyType == Policy.PolicyType.USDC) {
            return policy.publicUSDCPrice;
        }
        revert("Could not get price");
    }

    function setPrice(
        uint256 _days,
        uint256 _newEarlyUSDCPrice,
        uint256 _newEarlyETHPrice,
        uint256 _newPublicUSDCPrice,
        uint256 _newPublicETHPrice
    )
        public
        onlyOwner
    {
        Policy.PolicyPrice storage price = prices[_days];
        price.earlyUSDCPrice = _newEarlyUSDCPrice;
        price.earlyETHPrice = _newEarlyETHPrice;
        price.publicUSDCPrice = _newPublicUSDCPrice;
        price.publicETHPrice = _newPublicETHPrice;
    }

    function mint(uint256 _days, Policy.PolicyType _policyType, uint256 _price)
        public
        payable
        whenNotPaused 
    {
        uint256 price = getPrice(_days, _policyType);
        require(price == _price, "Price expected did not match price on contract");             // Ensure user gets price they expected

        if (limits[_days] != 0){
            require(supply[_days] <= limits[_days], "Current supply of policy is at max capacity"); // Ensure supply is less than limit
        }
        
        // Mint an ETH-based policy
        if (_policyType == Policy.PolicyType.USDC) {
            usdcContract.transferFrom(msg.sender, address(this), price);
            HealthPotion(healthPotionAddress).safeMint(msg.sender, _days, _policyType);
        } else {
            require(msg.value == price, "Must pay with sufficient ETH for policy");
            HealthPotion(healthPotionAddress).safeMint(msg.sender, _days, _policyType);
        }
    }

    function withdrawToken(address _to, uint256 _amount) external onlyOwner {
        usdcContract.transfer(_to, _amount);
    }

    function withdrawETH(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }
}