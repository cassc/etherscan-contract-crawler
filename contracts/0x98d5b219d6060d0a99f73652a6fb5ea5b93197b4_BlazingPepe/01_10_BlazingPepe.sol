// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract BlazingPepe is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    address private constant feeAddress1 = 0xD5F346BCE4846e94C7600D54E487F810Dd53305e;
    address private constant feeAddress2 = 0x99b26C4d4d5e8e29f32C43e8Dca59D7fdEee8348;

    uint256 private constant feePercentage = 7;
    uint256 private constant burnPercentage = 4;
    uint256 private constant feeAddress1Percentage = 2;
    uint256 private constant feeAddress2Percentage = 1;

    bool public feesEnabled = true;
    bool public renounceEnabled = true;

    address private constant uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 private uniswapV2Router;

    uint256 public totalTokensBurned;

    constructor() ERC20("BlazingPepe", "PepeX") {
        uint256 totalSupply = 420690000000000000000000000000000;
        _mint(msg.sender, totalSupply);
        uniswapV2Router = IUniswapV2Router02(uniswapRouter);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transferWithFee(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transferWithFee(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transferWithFee(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(balanceOf(sender) >= amount, "ERC20: insufficient balance");

        uint256 feeAmount = calculateFee(amount);
        uint256 burnAmount = feeAmount.mul(burnPercentage).div(feePercentage);
        uint256 feeAddress1Amount = feeAmount.mul(feeAddress1Percentage).div(feePercentage);
        uint256 feeAddress2Amount = feeAmount.mul(feeAddress2Percentage).div(feePercentage);

        // Adjust the allowance of the sender's tokens for the contract
        _approve(sender, address(this), allowance(sender, address(this)).add(feeAmount));

        _burn(sender, burnAmount);
        _transfer(sender, feeAddress1, feeAddress1Amount);
        _transfer(sender, feeAddress2, feeAddress2Amount);
        _transfer(sender, recipient, amount.sub(feeAmount));

        totalTokensBurned = totalTokensBurned.add(burnAmount);
     
    }

    function calculateFee(uint256 amount) internal view returns (uint256) {
        if (feesEnabled) {
            return amount.mul(feePercentage).div(100);
        } else {
            return 0;
        }
    }

    function disableFees() public onlyOwner {
        feesEnabled = false;
    }

    function enableFees() public onlyOwner {
        feesEnabled = true;
    }

    function renounceOwnership() public override onlyOwner {
        require(renounceEnabled, "Ownership renouncement is disabled");
        super.renounceOwnership();
    }

    function disableRenounce() public onlyOwner {
        renounceEnabled = false;
    }

    function enableRenounce() public onlyOwner {
        renounceEnabled = true;
    }
    
    function swapAndBurn(uint256 tokenAmount) external {
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 deadline = block.timestamp + 300; // Set a fixed deadline of 5 minutes (300 seconds)

        uint256 feeAmount = calculateFee(tokenAmount);
        uint256 burnAmount = feeAmount.mul(burnPercentage).div(feePercentage);
        uint256 feeAddress1Amount = feeAmount.mul(feeAddress1Percentage).div(feePercentage);
        uint256 feeAddress2Amount = feeAmount.mul(feeAddress2Percentage).div(feePercentage);

        // Transfer tokens including fees to the contract address
        _transferWithFee(msg.sender, address(this), tokenAmount);

        // Approve the token transfer to the Uniswap router
        _approve(address(this), address(uniswapRouter), tokenAmount);

        // Perform the swap with specified gas limit
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
         tokenAmount.sub(feeAmount),
         0,
         path,
         address(this),
         deadline
        );

        // Transfer fees
        _transfer(address(this), feeAddress1, feeAddress1Amount);
        _transfer(address(this), feeAddress2, feeAddress2Amount);

        // Burn tokens
        _burn(address(this), burnAmount);

        // Transfer ETH back to the user
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to transfer ETH");

        // Update the total tokens burned
        totalTokensBurned = totalTokensBurned.add(burnAmount);
     
    }


   
}