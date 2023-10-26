// SPDX-License-Identifier: UNLICENSED
/*

███╗   ███╗███████╗███╗   ███╗███████╗██████╗ ██╗   ██╗██████╗ ██████╗ ██╗   ██╗
████╗ ████║██╔════╝████╗ ████║██╔════╝██╔══██╗██║   ██║██╔══██╗██╔══██╗╚██╗ ██╔╝
██╔████╔██║█████╗  ██╔████╔██║█████╗  ██████╔╝██║   ██║██║  ██║██║  ██║ ╚████╔╝ 
██║╚██╔╝██║██╔══╝  ██║╚██╔╝██║██╔══╝  ██╔══██╗██║   ██║██║  ██║██║  ██║  ╚██╔╝  
██║ ╚═╝ ██║███████╗██║ ╚═╝ ██║███████╗██████╔╝╚██████╔╝██████╔╝██████╔╝   ██║   
╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═════╝ ╚═════╝    ╚═╝   

*/

pragma solidity ^0.8.13;

import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";
import {IWETH, IUniswapV2Router} from "./Uniswap.sol";

contract Token is ERC20, Owned {
    uint256 public buyTaxRate;
    uint256 public sellTaxRate;
    address public rewardsPool;
    mapping(address => bool) public isExcludedFromTax;
    mapping(address => bool) public taxableAddresses;

    event RewardsWithdrawn(uint256 amount);
    event SetRewardsPool(address rewardsPool);
    event SetExcludedFromTax(address account, bool isExcluded);
    event SetTaxable(address account, bool isTaxable);
    event SetUniswap(address weth, address uniswapV2Router);
    event Withdrawn(uint256 amount);

    // Address of the WETH token. This is needed because Uniswap V3 does not directly support ETH,
    // but it does support WETH, which is a tokenized version of ETH.
    IWETH weth;

    // Uniswap V2 router
    IUniswapV2Router uniswapV2Router;

    /**
     * @dev Contract constructor that sets initial supply, buy and sell tax rates.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _initialSupply The initial supply of the token.
     * @param _buyTaxRate The tax rate for buying the token.
     * @param _sellTaxRate The tax rate for selling the token.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint256 _buyTaxRate,
        uint256 _sellTaxRate
    ) ERC20(_name, _symbol, 18) Owned(msg.sender) {
        _mint(msg.sender, _initialSupply);
        buyTaxRate = _buyTaxRate;
        sellTaxRate = _sellTaxRate;
        isExcludedFromTax[address(this)] = true;
    }

    /**
     * @dev Overrides the transfer function of the ERC20 standard.
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 transferAmount = calcTax(msg.sender, to, amount);

        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += transferAmount;
        }

        emit Transfer(msg.sender, to, transferAmount);

        return true;
    }

    /**
     * @dev Overrides the transferFrom function of the ERC20 standard.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        uint256 transferAmount = calcTax(from, to, amount);

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += transferAmount;
        }

        emit Transfer(from, to, transferAmount);

        return true;
    }

    /**
     * @dev Calculates the tax for a given transaction.
     * @param sender The address sending the tokens.
     * @param recipient The address receiving the tokens.
     * @param amount The amount of tokens to be transferred.
     * @return The amount of tokens to be transferred after tax.
     */
    function calcTax(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 taxRate = 0;
        if (taxableAddresses[sender] && !isExcludedFromTax[recipient]) {
            // Buy operation
            taxRate = buyTaxRate;
        } else if (taxableAddresses[recipient] && !isExcludedFromTax[sender]) {
            // Sell operation
            taxRate = sellTaxRate;
        }

        uint256 tax = 0;
        if (taxRate > 0) {
            tax = amount * taxRate / 100;
            balanceOf[address(this)] += tax;
            emit Transfer(sender, address(this), tax);
        }
        return amount - tax;
    }

    /**
     * @dev Withdraws the balance of the contract, swaps to ETH and deposits in the rewards pool.
     */
    function withdraw() external onlyOwner {
        uint256 tokenBalance = balanceOf[address(this)];

        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // Make the swap
        uniswapV2Router.swapExactTokensForETH(
            tokenBalance,
            0, // Accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        // Now that you have WETH, you can unwrap it to get ETH
        weth.withdraw(weth.balanceOf(address(this)));

        // Transfer the ETH to the rewards pool
        uint256 ethAmount = address(this).balance;
        payable(rewardsPool).transfer(ethAmount);

        emit Withdrawn(ethAmount);
    }

    /**
     * @dev Sets the rewards pool address.
     * @param _rewardsPool The address of the rewards pool.
     */
    function setRewardsPool(address _rewardsPool) external onlyOwner {
        rewardsPool = _rewardsPool;
        isExcludedFromTax[_rewardsPool] = true;
        emit SetRewardsPool(_rewardsPool);
    }

    /**
     * @dev Sets the Uniswap router and WETH addresses.
     * @param _weth The address of the WETH token.
     * @param _uniswapRouter The address of the Uniswap router.
     */
    function setUniswap(address _weth, address _uniswapRouter) external onlyOwner {
        weth = IWETH(_weth);
        uniswapV2Router = IUniswapV2Router(_uniswapRouter);
        allowance[address(this)][_uniswapRouter] = type(uint256).max;
        emit SetUniswap(_weth, _uniswapRouter);
    }

    /**
     * @dev Sets an address as taxable destination or not. Basically for uniswap addresses.
     * @param _address The address to be set.
     * @param isTaxable A boolean that indicates if the address should trigger a tax when transferred to or from.
     */
    function setTaxable(address _address, bool isTaxable) external onlyOwner {
        taxableAddresses[_address] = isTaxable;
        emit SetTaxable(_address, isTaxable);
    }

    /**
     * @dev Excludes an account from tax.
     * @param _account The account to be excluded from tax.
     * @param isExcluded A boolean that indicates if the account should be excluded from being taxed
     */
    function setExcludedFromTax(address _account, bool isExcluded) external onlyOwner {
        isExcludedFromTax[_account] = isExcluded;
        emit SetExcludedFromTax(_account, isExcluded);
    }

    receive() external payable {}
}