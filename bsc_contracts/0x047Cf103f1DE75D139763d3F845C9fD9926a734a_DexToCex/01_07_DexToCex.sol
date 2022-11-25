// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UniswapInterface.sol";

contract DexToCex is Ownable {
    using SafeMath for uint256;

	address public BIBContract;
	address public BUSDContract;
	address public router;
    address public receiver;
    address public trader;

	constructor(
        address _bib,
        address _busd,
		address _router,
        address _receiver,
        address _trader
    ) {
        BIBContract = _bib;
		BUSDContract = _busd;
		router = _router;
        receiver = _receiver;
        trader = _trader;
    }
    event ReceiveToken(address indexed user, uint256 amount);
	event BuyTrade(uint256 busd, uint256 bib);
	event SellTrade(uint256 bib, uint256 busd);
    event ReceiptEther(uint256 amount);

    modifier onlyTrader() {
        require(msg.sender == trader, "Only callable by trader");
        _;
    }

	function getAmountOutMin(address[] memory pairs, uint256 _amount) public view returns (uint256) {
		uint256[] memory amountOutMins = IUniswapV2Router01(router).getAmountsOut(_amount, pairs);
		return amountOutMins[pairs.length -1];
	}

	function swap(address[] memory pairs, uint256 amountOut, uint256 amountInMin) public onlyTrader {
		IERC20(pairs[0]).approve(router, amountOut);
		uint256[] memory result = IUniswapV2Router01(router).swapExactTokensForTokens(amountOut, amountInMin, pairs, address(this), block.timestamp);
		if (pairs[0] == BIBContract) {
			emit SellTrade(result[0], result[1]);
		} else if (pairs[0] == BUSDContract) {
			emit BuyTrade(result[0], result[1]);
		}
	}

    function setReceiver(address _receiver) external onlyOwner {
        require(address(0) != _receiver, "INVLID_ADDR");
        receiver = _receiver;
    }

    function setTrader(address _trader) external onlyOwner {
        require(address(0) != _trader, "INVLID_ADDR");
        trader = _trader;
    }
    
    function receiveTokens(address[] memory tokens) external {
        for(uint256 i=0; i<tokens.length;i++) {
			address tokenAddress = tokens[i];
			uint256 newTokens = IERC20(tokenAddress).balanceOf(address(this));
			IERC20(tokenAddress).transfer(receiver, newTokens);
			emit ReceiveToken(receiver, newTokens);
		}
    }

    function receiveEther() external {
		address payable _receiver = payable(receiver);
        _receiver.transfer(address(this).balance);
    }

    receive() external payable {
        emit ReceiptEther(msg.value);
    }
}