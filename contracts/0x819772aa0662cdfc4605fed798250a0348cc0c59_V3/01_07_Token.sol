// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10; 

import {IERC20} from "IERC20.sol"; 
import {ERC20} from "ERC20.sol";
import {Ownable} from "Ownable.sol";
import {SafeMath} from "SafeMath.sol"; 


contract V3 is ERC20, Ownable {
	using SafeMath for uint256;

	address public uniswapV3Router01;
	address public uniswapV3Router02;
	address public uniswapUniRouter;
	address public devWallet;

	uint256 public maxTransactionAmount;
	uint256 public maxWallet;

	bool public limitsInEffect = true;
	bool public tradingActive = false;
	bool public tradingActiveCheck = false;
    
	mapping(address => bool) public isExcludedMaxTransactionAmount;

	constructor() ERC20("VeeThree", "V3") {
		
		uniswapV3Router01 = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
		uniswapV3Router02 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
		uniswapUniRouter = 0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B;
		uint256 totalSupply = 3_333_333_333 * 1e18;
		maxTransactionAmount = 69_696_969 * 1e18; 
		maxWallet = 69_696_969 * 1e18; 
		devWallet = address(msg.sender); 

		excludeFromMaxTransaction(address(uniswapV3Router01), true);
		excludeFromMaxTransaction(address(uniswapV3Router02), true);
		excludeFromMaxTransaction(address(uniswapUniRouter), true);
		excludeFromMaxTransaction(owner(), true);
		excludeFromMaxTransaction(address(this), true);
		excludeFromMaxTransaction(address(0xdead), true);
		_mint(msg.sender, totalSupply);
	}

	receive() external payable {}

	function enableTrading(bool onoff) external onlyOwner {
		require(tradingActiveCheck == false, 'Called already');
		if (onoff == true) {
			tradingActive = onoff;
			tradingActiveCheck == true;
		}
	}

	function removeLimits() external onlyOwner returns (bool) {
		limitsInEffect = false;
		return true;
	}

	function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance > 0, "Empty Balance");
        payable(devWallet).transfer(amount);
    }

    function withdrawToken(uint256 amount, address token) external onlyOwner {
        require(
            IERC20(token).balanceOf(address(this)) > 0,
            "Empty token balance"
        );
        IERC20(token).transfer(devWallet, amount);
    }

	function excludeFromMaxTransaction(address excluded, bool isEx)
		public
		onlyOwner
	{
		isExcludedMaxTransactionAmount[excluded] = isEx;
	}

	function _excludeFromMaxTransaction(address excluded, bool isEx)
		private
	{
		isExcludedMaxTransactionAmount[excluded] = isEx;
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	) internal override {

		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
		}

		if (limitsInEffect) {
            
			if (
				from != owner() &&
				to != owner() &&
				to != address(0) &&
				to != address(0xdead)
			) {

				if (!tradingActive) {
					require(
						isExcludedMaxTransactionAmount[from],
						"Trading is not active."
					);
				}

				require(
					amount <= maxTransactionAmount,
					"Buy transfer amount exceeds the maxTransactionAmount."
				);
				require(
					amount + balanceOf(to) <= maxWallet,
					"Max wallet exceeded"
				);
			}
		}
		
		super._transfer(from, to, amount);
	}

}