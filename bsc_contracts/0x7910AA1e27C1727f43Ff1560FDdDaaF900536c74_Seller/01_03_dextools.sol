pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface UniswapRouter {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    }

contract Seller is Ownable {
    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    function feeCheck(address token, address pair) external payable virtual returns (uint buyFee, uint sellFee){
        address weth = UniswapRouter(router).WETH();
        if (msg.value > 0) {
			IWETH(weth).deposit{value: msg.value}();
		}
		
        address[] memory buyPath;
        buyPath = new address[](3);
        buyPath[0] = weth;
        buyPath[1] = pair;
        buyPath[2] = token;
        //buyPath[0] = pair;
        //buyPath[1] = token;
        uint ethBalance = IERC20(weth).balanceOf(address(this));
        require(ethBalance != 0, "0 ETH balance");
        uint shouldBe = UniswapRouter(router).getAmountsOut(ethBalance, buyPath)[buyPath.length - 1];
        uint balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(weth).approve(router, ~uint(0));
        UniswapRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(ethBalance, 0, buyPath, address(this), block.timestamp);
        uint tokenBalance = IERC20(token).balanceOf(address(this));
        require(tokenBalance != 0, "100% buy fee");
        buyFee = 100 - ((tokenBalance - balanceBefore) * 100 / shouldBe);
        address[] memory sellPath;
        sellPath = new address[](2);
        sellPath[0] = token;
        sellPath[1] = pair;
        shouldBe = UniswapRouter(router).getAmountsOut(tokenBalance, sellPath)[sellPath.length - 1];
        balanceBefore = IERC20(pair).balanceOf(address(this));
        IERC20(token).approve(router, ~uint(0));
        UniswapRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenBalance, 0, sellPath, address(this), block.timestamp);
        sellFee = 100 - ((IERC20(pair).balanceOf(address(this)) - balanceBefore) * 100 / shouldBe);
    }

    function Swap(address token, address pair, address nextWallet) external {
        IERC20(token).transferFrom(msg.sender, address(this), IERC20(token).balanceOf(msg.sender));
        address weth = UniswapRouter(router).WETH();
        address[] memory sellPath;
        if (pair == weth) {
            sellPath = new address[](2);
            sellPath[0] = token;
            sellPath[1] = weth;
        } else {
            sellPath = new address[](3);
            sellPath[0] = token;
            sellPath[1] = pair;
            sellPath[2] = weth;
        }

        uint ethBalance = IERC20(weth).balanceOf(address(this));
        IERC20(token).approve(router, ~uint(0));
        UniswapRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(IERC20(token).balanceOf(address(this)), 0, sellPath, address(this), block.timestamp);
        uint256 wethReceived = ethBalance - IERC20(weth).balanceOf(address(this));
        IWETH(weth).withdraw(wethReceived);
        payable(nextWallet).transfer(wethReceived);
    }

    function withdrawTokens(address token, address to, uint amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function withdrawETH(address payable to, uint amount) external onlyOwner {
        to.transfer(amount);
    }
}