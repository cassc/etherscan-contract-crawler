// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IEUSD.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ICurvePool{
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns(uint256);
}

contract LybraBalanceSheet is Ownable {
    using SafeERC20 for IERC20;

    IEUSD public EUSD;
    IERC20 public USDC;
    ICurvePool public curvePool;
    bool public active = true;
    uint256 public totalBorrowed;

    event ExpandBalanceSheet(uint256 borrowAmount, uint256 receivedAmount, uint256 time);
    event ReduceBalanceSheet(uint256 repayAmount, uint256 reduceAmount, uint256 time);
    event Redeem(address user, uint256 eUSDAmount, uint256 time);
    event ClaimTreasuryProfits(address to, uint256 amount, uint256 time);
    event ActivationStatus(bool active, uint256 time);

    constructor(address _eusd, address _usdc, address _curvePool) {
        EUSD = IEUSD(_eusd);
        USDC = IERC20(_usdc);
        curvePool = ICurvePool(_curvePool);
    }

    modifier activated() {
        require(active, "STOP");
        _;
    }

    function setActivationStatus(bool _bool) external onlyOwner {
        active = _bool;
        emit ActivationStatus(_bool, block.timestamp);
    }

    /**
     * @dev When the price of eUSD/USDC exceeds 1, the LBS module has the right to borrow an unlimited amount of eUSD 
     * from the Lybra protocol and exchange it for a larger amount of USDC through Curve.
     * @param amount The amount of eUSD to be borrowed and sold.
     */
    function expandBalanceSheet(uint256 amount) external activated onlyOwner {
        EUSD.mint(address(this), amount);
        EUSD.approve(address(curvePool), amount);
        uint256 preBalance = USDC.balanceOf(address(this));
        curvePool.exchange_underlying(0, 2, amount, amount / 1e12);
        uint256 received = USDC.balanceOf(address(this)) - preBalance;
        require(received > amount / 1e12, "eUSD must be sold at a premium");
        totalBorrowed += amount;
        emit ExpandBalanceSheet(amount, received, block.timestamp);
    }

    /**
     * @dev When the price of eUSD/USDC is less than 1, the USDC in LBS will be sold to become more eUSD, 
     * which will then be destroyed to repay the debt.
     * @param amount The amount of USDC to be sold.
     */
    function reduceBalanceSheet(uint256 amount) external activated {
        USDC.approve(address(curvePool), amount);
        curvePool.exchange_underlying(2, 0, amount, amount * 1e12);
        uint256 balance = EUSD.balanceOf(address(this));
        require(balance > amount * 1e12, "USDC must be sold at a premium");
        require(totalBorrowed >= balance, "Debt cannot be overpaid");
        EUSD.burn(address(this), balance);
        totalBorrowed -= balance;
        emit ReduceBalanceSheet(balance, amount, block.timestamp);
    }

    /**
     * @dev As long as there are USDC assets in LBS, users can exchange an equivalent amount of USDC with eUSD at any time.
     */
    function redeem(uint256 amount) external {
        EUSD.burn(msg.sender, amount);
        totalBorrowed -= amount;
        USDC.transfer(msg.sender, amount / 1e12);
        emit Redeem(msg.sender, amount, block.timestamp);
    }

    /**
    * @dev Allows the owner to claim the treasury profits.
    * This contract should not hold eUSD, so when eUSD is mistakenly transferred in, it can be transferred out using this function.
    * @param to The address to send the profits to.
    */
    function claimTreasuryProfits(address to) external onlyOwner {
        uint256 amount = USDC.balanceOf(address(this)) - totalBorrowed / 1e12;
        USDC.transfer(to, amount);
        uint256 balance = EUSD.balanceOf(address(this));
        if(balance > 0) {
            EUSD.transfer(to, balance);
        }
        emit ClaimTreasuryProfits(to, amount, block.timestamp);
    }

    function getTotalAsset() external view returns (uint256) {
        return USDC.balanceOf(address(this));
    }
}