// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IEGMC.sol";

contract EGMCShareholderDistributor is Ownable {
    using SafeMath for uint;

    IEGMC public immutable token;

    uint public shareholderPecentage = 80;
    uint public tokenPercentage = 1000; // in bp
    uint public lpPercentage = 1500; // in bp
    address public shareholderPool;
    address private dev;

    constructor (
        address _token,
        address _shareholderPool
    ) {
        token = IEGMC(_token);
        shareholderPool = _shareholderPool;

        dev = address(0x231125A43C1fC2f3699f3a9Ac078009630D11c0E);
    }

    /** VIEW FUNCTIONS */

    function getAmounts() public view returns (uint lpAmount, uint devAmount, uint tokenAmount) {
        uint lpToDistribute = IERC20(token.uniswapV2Pair()).balanceOf(address(this)).mul(lpPercentage).div(10000);
        lpAmount = lpToDistribute.mul(shareholderPecentage).div(100);
        devAmount = lpToDistribute.sub(lpAmount);
        tokenAmount = IERC20(token).balanceOf(address(this)).mul(tokenPercentage).div(10000);
    }

    /** PUBLIC FUNCTIONS */

    function distribute() external returns (uint lpAmount, uint tokenAmount) {
        require(_msgSender() == shareholderPool, "Only shareholder pool can call this function");

        uint devAmount;
        (lpAmount, devAmount, tokenAmount) = getAmounts();

        if (lpAmount > 0) {
            IERC20(token.uniswapV2Pair()).transfer(shareholderPool, lpAmount);
        }

        if (tokenAmount > 0) {
            IERC20(token).transfer(shareholderPool, tokenAmount);
        }

        if (devAmount > 0) {
            IERC20(token.uniswapV2Pair()).transfer(dev, devAmount);
        }
    }

    /** RESTRICTED FUNCTIONS */

    function setShareholderPool(address _shareholderPool) external onlyOwner {
        shareholderPool = _shareholderPool;
    }

    function setDev(address _dev) external {
        require(_msgSender() == dev, "only dev");
        dev = _dev;
    }

    function setShareholderPercentages(uint _shareholderPercentage) external onlyOwner {
        shareholderPecentage = _shareholderPercentage;
    }

    function setPercentages(uint _tokenPercentage, uint _lpPercentage) external onlyOwner {
        tokenPercentage = _tokenPercentage;
        lpPercentage = _lpPercentage;
    }

    function recover(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}