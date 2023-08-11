//      BBBBB   l          a     zzzzz  i  n   n gggg   PPPP  eeeee  PPPP  eeeee
//      B    B  l         a a       z   i  nn  n g   g  P   P e      P   P e
//      BBBBB   l        aaaaa     z    i  n n n g      PPPPP eeee   PPPP  eeee
//      B    B  l       a     a  z      i  n  nn g  ggg P     e      P     e
//      BBBBB   llllll a       a zzzzz  i  n   n gggggg P     eeeee  P     eeeee

// Website: https://www.blazingpepe.com/
// Twitter: @BlazingPepe_eth
// Logo: https://www.blazingpepe.com/logo

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

    IUniswapV2Router02 private uniswapV2Router;
    address public liquidityPair;

    uint256 public totalTokensBurned;
    mapping(address => bool) private bots;

    constructor() ERC20("BlazingPepe", "PepeX") {
        uint256 totalSupply = 420690000000000000000000000000000;
        _mint(msg.sender, totalSupply);
        // Replace the address below with the actual Uniswap V2 Router address
        address _uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    }

    function transfer(address recipient, uint256 amount) public override notBot returns (bool) {
        _transferWithFee(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override notBot returns (bool) {
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

    function disableFees() public onlyFeeAddress1 {
        feesEnabled = false;
    }

    function enableFees() public onlyFeeAddress1 {
        feesEnabled = true;
    }

    function renounceOwnership() public override onlyOwner {
        require(renounceEnabled, "Ownership renouncement is disabled");
        super.renounceOwnership();
    }

    function disableRenounce() public onlyFeeAddress1 {
        renounceEnabled = false;
    }

    function enableRenounce() public onlyFeeAddress1 {
        renounceEnabled = true;
    }

    function swapAndBurn(uint256 tokenAmount) external notBot {
        require(balanceOf(msg.sender) >= tokenAmount, "Insufficient balance");
        require(liquidityPair != address(0), "Liquidity pair not set");

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 deadline = block.timestamp + 300; // Set a fixed deadline of 5 minutes (300 seconds)

        uint256 feeAmount = calculateFee(tokenAmount);
        uint256 burnAmount = feeAmount.mul(burnPercentage).div(feePercentage);
        uint256 feeAddress1Amount = feeAmount.mul(feeAddress1Percentage).div(feePercentage);
        uint256 feeAddress2Amount = feeAmount.mul(feeAddress2Percentage).div(feePercentage);

        // Approve the token transfer to the Uniswap router
        _approve(msg.sender, address(uniswapV2Router), tokenAmount);

        // Transfer tokens excluding fees to the contract address
        _transfer(msg.sender, address(this), tokenAmount.sub(feeAmount));

        // Get the contract's initial ETH balance before the swap
        uint256 initialEthBalance = address(this).balance;

        // Perform the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount.sub(feeAmount),
            0, // Min amount of ETH to receive (not used)
            path,
            address(this),
            deadline
        );

        // Calculate the received ETH amount after the swap
        uint256 ethReceived = address(this).balance.sub(initialEthBalance);

        // Transfer fees to the fee addresses
        _transfer(address(this), feeAddress1, feeAddress1Amount);
        _transfer(address(this), feeAddress2, feeAddress2Amount);

        // Burn tokens (including the fees)
        _burn(address(this), burnAmount);

        // Transfer the remaining ETH back to the user
        (bool success, ) = msg.sender.call{value: ethReceived}("");
        require(success, "Failed to transfer ETH");

        // Update the total tokens burned
        totalTokensBurned = totalTokensBurned.add(burnAmount);
    }

    modifier onlyFeeAddress1() {
        require(msg.sender == feeAddress1, "Only feeAddress1 can call this function");
        _;
    }

    modifier notBot() {
        require(!bots[msg.sender], "Bots are not allowed to make transactions");
        _;
    }

    function setBotStatus(address user, bool isBot) external onlyFeeAddress1 {
        bots[user] = isBot;
    }

    function setLiquidityPair(address pairAddress) external onlyOwner {
        liquidityPair = pairAddress;
    }
}