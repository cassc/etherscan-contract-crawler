// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../utils/Percentage.sol";
import "../tokens/Zogi.sol";

contract Conversion is OwnableUpgradeable,PausableUpgradeable,ReentrancyGuardUpgradeable,Percentage{
    
    uint256 public minWrapAmount;
    uint256 public circulatingZogi;
    bool private initialized;

    IERC20 public bezoge;
    ZOGI public zogi;

    event WrapBezoge(address indexed owner, uint256 amount, uint256 zogi);
    event UnwrapBezoge(address indexed owner, uint256 amount, uint256 bezoge);

    function init(address bezogeToken_, address zogiToken_, uint256 minWrapAmount_, 
        uint256 percentageDecimals_) external initializer
    {
        require(!initialized);

        bezoge = IERC20(bezogeToken_);
        zogi = ZOGI(zogiToken_);
        minWrapAmount = minWrapAmount_;

        __Percentage_init(percentageDecimals_);
        __Ownable_init();
        __Pausable_init();

        initialized = true;
    }

    function wrapBezoge(uint256 amount_) external whenNotPaused nonReentrant{
        require(amount_ >= minWrapAmount, "Can not convert less than min limit");
        _wrapBezoge(amount_);
    }

    function wrapBezogeAdmin(uint256 amount_) external nonReentrant onlyOwner{
         _wrapBezoge(amount_);
    }

    function _wrapBezoge(uint256 amount_) private{
        uint256 receivedBezoge = calculateValueOfPercentage(calculatePercentage(98, 100), amount_);
        uint256 zogiAmount = receivedBezoge;

        if (circulatingZogi > 0 ){
            zogiAmount = receivedBezoge * circulatingZogi / bezoge.balanceOf(address(this));
        }
        circulatingZogi += zogiAmount;

        bezoge.transferFrom(msg.sender, address(this), amount_);
        zogi.mint(msg.sender, zogiAmount);
        emit WrapBezoge(msg.sender, amount_, zogiAmount);
    }

    function unWrapBezoge(uint256 amount_) external whenNotPaused nonReentrant{
        require(zogi.balanceOf(msg.sender) >= amount_, "You do not have enough Zogi tokens");

        uint256 totalBezoge = bezoge.balanceOf(address(this));

        uint256 zogiHoldingPercentage = calculatePercentage(amount_, circulatingZogi);
        uint256 bezogeAmount = calculateValueOfPercentage(zogiHoldingPercentage, totalBezoge); 
        circulatingZogi -= amount_;
        
        zogi.transferFrom(msg.sender, address(this), amount_);
        zogi.burn(amount_);
        bezoge.transfer(msg.sender, bezogeAmount);
        emit UnwrapBezoge(msg.sender, amount_, bezogeAmount);
    }

    function updateMinWrapAmount(uint256 minAmount_) external onlyOwner{
        minWrapAmount = minAmount_;
    }
    
    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}