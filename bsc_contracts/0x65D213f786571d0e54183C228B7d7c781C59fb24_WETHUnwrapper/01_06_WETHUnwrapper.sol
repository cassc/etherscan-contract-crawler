pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IWETH.sol";
import "../interfaces/IWETHUnwrapper.sol";

import "hardhat/console.sol";

contract WETHUnwrapper is IWETHUnwrapper {
	IWETH public weth;

	constructor(IWETH _weth) {
		weth = _weth;
	}

	function withdraw(uint256 amount, address to) external override {
		weth.withdraw(amount);

		(bool success, ) = payable(to).call{value: amount}("");
		require(success, "WU: transfer failed");
	}

	receive() external payable {}
}