// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IGenesis.sol";

interface ISwap {
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

contract MintingHelper {

    address constant WBNB = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address constant BUSD = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    IGenesis constant Genesis = IGenesis(0x17eF9b8E91b403a03F63471693Ac711b1A13df56);
    ISwap constant Pancakeswap = ISwap(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    constructor() {
        IERC20Upgradeable(BUSD).approve(address(Genesis), type(uint256).max);
    }

    function mintWithNative(
		uint256 amount,
		IGenesis.Referral calldata referral
	) external payable {
        uint256 totalSupply = Genesis.totalSupply();
        uint256 paymentAmount = Genesis.totalMintingFee(totalSupply, amount);

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = BUSD;

        Pancakeswap.swapETHForExactTokens{ value: msg.value }(paymentAmount, path, address(this), block.timestamp);

        Genesis.mint(BUSD, amount, msg.sender, referral);

        address(msg.sender).call{ value: address(this).balance }("");
    }
}