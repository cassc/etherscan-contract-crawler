// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract INKPurchase is Ownable {
	using SafeERC20 for IERC20;

	address public immutable usdc;
	address public treasuryWallet;
	uint256 public minAmount;
	ISwapRouter public uniswapRouter;
	mapping(address => uint256) public purchasedAmount;

	event Purchased(address buyer, uint256 amount);

	constructor(
		address _treasuryWallet,
		address _usdc,
		uint256 _minAmount
	) {
		treasuryWallet = _treasuryWallet;
		uniswapRouter = ISwapRouter(
			0xE592427A0AEce92De3Edee1F18E0157C05861564
		);
		usdc = _usdc;
		minAmount = _minAmount;
	}

	// External methods

	function purchaseForUSDC(uint256 _amount) external {
		IERC20(usdc).safeTransferFrom(msg.sender, treasuryWallet, _amount);
		_purchase(_amount);
	}

	function purchaseForETH(bytes memory path) external payable {
		ISwapRouter.ExactInputParams memory params = ISwapRouter
			.ExactInputParams({
				path: path,
				recipient: treasuryWallet,
				deadline: block.timestamp + 15,
				amountIn: msg.value,
				amountOutMinimum: 0
			});

		uint256 usdcAmount = uniswapRouter.exactInput{ value: msg.value }(
			params
		);
		_purchase(usdcAmount);
	}

	function purchaseForToken(
		address _tokenIn,
		uint256 _amount,
		bytes memory path
	) external {
		IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amount);
		IERC20(_tokenIn).safeApprove(address(uniswapRouter), _amount);

		ISwapRouter.ExactInputParams memory params = ISwapRouter
			.ExactInputParams({
				path: path,
				recipient: treasuryWallet,
				deadline: block.timestamp + 15,
				amountIn: _amount,
				amountOutMinimum: 0
			});

		uint256 usdcAmount = uniswapRouter.exactInput(params);
		_purchase(usdcAmount);
	}

	function withdrawFunds(address _to) external onlyOwner {
		require(_to != address(0), "Purchase: recipient is the zero address");
		IERC20(usdc).safeTransfer(_to, IERC20(usdc).balanceOf(address(this)));
	}

	function withdrawAsset(address _token, address _to) external payable onlyOwner {
		if (_token == address(0)) {
			require(address(this).balance > 0, "Purchase: no balance");
			payable(_to).transfer(address(this).balance);
		} else {
			IERC20(_token).safeTransfer(
				_to,
				IERC20(_token).balanceOf(address(this))
			);
		}
	}

	function changeTreasuryWallet(address _treasuryWallet)
		external
		onlyOwner
	{
		require(
			_treasuryWallet != address(0),
			"Purchase: treasury wallet is the zero address"
		);
		treasuryWallet = _treasuryWallet;
	}

	function setMinimalAmount(uint256 _minAmount) external onlyOwner {
		require(_minAmount > 0, "Purchase: minimal amount is zero");
		minAmount = _minAmount;
	}

	// Internal methods

	function _purchase(uint256 _amount) internal {
		require(
			_amount >= minAmount,
			"Purchase: amount must be at least minimum amount"
		);

		purchasedAmount[msg.sender] += _amount;
		emit Purchased(msg.sender, _amount);
	}
}