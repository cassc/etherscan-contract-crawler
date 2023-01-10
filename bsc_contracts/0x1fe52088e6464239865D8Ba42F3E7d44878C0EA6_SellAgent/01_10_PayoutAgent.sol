//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/INovationRouter02.sol";

interface ISellessSwap {
    function buy(address _token, uint _amountOutMin) external payable;
    function sell(address _token, uint _amountIn, uint _amountOutMin) external;
}

contract SellAgent is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public token;
    INovationRouter02 novRouter = INovationRouter02(0x0Fa0544003C3Ad35806d22774ee64B7F6b56589b);
    ISellessSwap sellessSwap = ISellessSwap(0x2085B84912531B126f1C92cd70A71381713f0795);

    constructor(address _token) {
        token = IERC20(_token);
        token.approve(address(sellessSwap), type(uint).max);
    }
    
    function sellToken(uint _amount) external returns (uint) {
        uint before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = token.balanceOf(address(this)) - before;
        before = address(this).balance;
        sellessSwap.sell(address(token), _amount, 0);
        uint amount = address(this).balance - before;
        payable(msg.sender).call{value: amount}("");
        return amount;
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }
}

contract PayoutAgent is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    INovationRouter02 pcsRouter = INovationRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    INovationRouter02 novRouter = INovationRouter02(0x0Fa0544003C3Ad35806d22774ee64B7F6b56589b);
    ISellessSwap sellessSwap = ISellessSwap(0x2085B84912531B126f1C92cd70A71381713f0795);
    
    IERC20 public payoutToken;
    IERC20 public token;
    IERC20 public constant wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    SellAgent public sellAgent;

    constructor(address _token, address _payout) {
        payoutToken = IERC20(_payout);
        token = IERC20(_token);
        token.approve(address(pcsRouter), type(uint).max);

        sellAgent = new SellAgent(_payout);
        payoutToken.approve(address(sellAgent), type(uint).max);
    }

    function payout(address _to, uint _amount, bool _sellback) external nonReentrant {
        if (address(token) == address(payoutToken)) {
            token.safeTransferFrom(msg.sender, _to, _amount);    
            return;
        }

        uint before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = token.balanceOf(address(this)) - before;

        if (address(payoutToken) == address(wbnb)) {
            _swapForBNB(_to, _amount);
            return;
        }
        uint bnbAmount = _swapForBNB(address(this), _amount);
        if (!_sellback) {
            _swapForToken(_to, bnbAmount);
            return;
        }
        before = payoutToken.balanceOf(address(this));
        _swapForToken(address(this), bnbAmount);
        _amount = payoutToken.balanceOf(address(this)) - before;

        // Sell-back with tax
        // _amount = _sellPayoutToken(_amount);
        _amount = sellAgent.sellToken(_amount);
        _buyToken(_to, _amount);
    }

    function _swapForBNB(address _to, uint _amount) internal returns (uint) {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(wbnb);

        uint before = address(this).balance;
        pcsRouter.swapExactTokensForETH(
            _amount, 
            0, 
            path, 
            _to, 
            block.timestamp
        );
        return address(this).balance - before;
    }

    function _swapForToken(address _to, uint _amount) internal returns (uint) {
        address[] memory path = new address[](2);
        path[0] = address(wbnb);
        path[1] = address(payoutToken);

        uint[] memory amounts = novRouter.swapExactETHForTokens{value: _amount}(
            0, 
            path, 
            _to, 
            block.timestamp
        );
        return amounts[1];
    }

    function _sellPayoutToken(uint _amount) internal returns (uint) {
        uint before = address(this).balance;
        sellessSwap.sell(address(payoutToken), _amount, 0);
        return address(this).balance - before;
    }

    function _buyToken(address _to, uint _amount) internal returns (uint) {
        address[] memory path = new address[](2);
        path[0] = address(wbnb);
        path[1] = address(token);

        uint[] memory amounts = pcsRouter.swapExactETHForTokens{value: _amount}(
            0, 
            path, 
            _to, 
            block.timestamp
        );
        return amounts[1];
    }

    function setPayoutToken(address _token) external onlyOwner {
        payoutToken = IERC20(_token);
    }

    receive() external payable {}
}