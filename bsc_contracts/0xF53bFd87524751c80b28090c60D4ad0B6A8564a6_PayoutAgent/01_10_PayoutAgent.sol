//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/INovationRouter02.sol";

contract PayoutAgent is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    INovationRouter02 pcsRouter = INovationRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    INovationRouter02 novRouter = INovationRouter02(0x0Fa0544003C3Ad35806d22774ee64B7F6b56589b);
    
    IERC20 public payoutToken;
    IERC20 public token;
    IERC20 public constant wbnb = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    constructor(address _token, address _payout) {
        payoutToken = IERC20(_payout);
        token = IERC20(_token);
        token.approve(address(pcsRouter), type(uint).max);
    }

    function payout(address _to, uint _amount) external nonReentrant {
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
        _swapForToken(_to, bnbAmount);
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

    function setPayoutToken(address _token) external onlyOwner {
        payoutToken = IERC20(_token);
    }

    receive() external payable {}
}