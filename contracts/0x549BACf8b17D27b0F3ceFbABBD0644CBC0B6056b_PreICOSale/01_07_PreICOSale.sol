// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract PreICOSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    uint256 internal price = 240; //USD
    IERC20 public PreICO;
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; //rinkeby USDT = 0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD;

    event Buy(
        uint256 tokenAmount,
        uint256 USDTAmount
    );

    event WithdrawnBalance(
        address receiver,
        uint256 amount,
        uint256 balance
    );

    event WithdrawnToken(
        address receiver,
        uint256 amount,
        uint256 balance
    );

    event UpdatePrice(
        uint256 price
    );

    constructor(IERC20 token) {
        require(address(token) != address(0x0));
        PreICO = token;
    }

    /**
     * @notice Buy ICO token with USDT payment
     * @param amount ICO token amount that users try to buy
     * @param payment USDT token amount
     */
    function buy(uint256 amount, uint256 payment) external nonReentrant {
        require(amount > 0, "PreICOSale.buy: Token amount should be positive");
        require(payment > 0, "PreICOSale.buy: Payment should be positive");
        require(amount * price == payment * 1e18, "PreICOSale.buy: Invalid funds");
        require(amount > 0 && amount <= PreICO.balanceOf(address(this)), "PreICOSale.buy: Invalid balance");

        IERC20(USDT).transferFrom(msg.sender, address(this), payment);
        PreICO.transfer(msg.sender, amount);

        emit Buy(amount, payment);
    }

    /**
     * @notice Send / withdraw balance to receiver
     * @param receiver recipient address
     * @param amount amount to withdraw
    */
    function withdrawBalanceTo(address receiver, uint256 amount) external onlyOwner {
        require(receiver != address(0) && receiver != address(this), "PreICOSale.withdrawBalanceTo: Invalid withdrawal recipient address");
        require(amount > 0 && amount <= IERC20(USDT).balanceOf(address(this)), "PreICOSale.withdrawBalanceTo: Invalid withdrawal amount");
        IERC20(USDT).transfer(receiver, amount);

        emit WithdrawnBalance(receiver, amount, IERC20(USDT).balanceOf(address(this)));
    }

    /**
     * @notice Send / withdraw ICO Token to receiver
     * @param receiver recipient address
     * @param amount amount to withdraw
    */
    function withdrawTokenTo(address receiver, uint256 amount) external onlyOwner {
        require(receiver != address(0) && receiver != address(this), "PreICOSale.withdrawTokenTo: Invalid withdrawal recipient address");
        require(amount > 0 && amount <= PreICO.balanceOf(address(this)), "PreICOSale.withdrawTokenTo: Invalid withdrawal amount");
        PreICO.transfer(receiver, amount);

        emit WithdrawnToken(receiver, amount, PreICO.balanceOf(address(this)));
    }

    /**
     * @notice Update price of ICO token
     * @param _price new token price
     */
    function updatePrice(uint256 _price) external onlyOwner {
        require(_price > 0, "PreICOSale.updatePrice: Price value should be positive");

        price = _price;
        emit UpdatePrice(price);
    }
}