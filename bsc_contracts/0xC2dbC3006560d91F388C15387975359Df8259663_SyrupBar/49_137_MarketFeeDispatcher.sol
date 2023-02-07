// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IMarketFeeManager.sol";
import "../interfaces/IWETH.sol";
import "../token/VBabyToken.sol";

contract MarketFeeDispatcher is Ownable, Initializable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint constant public PERCENT_RATIO = 1e6;

    IMarketFeeManager public manager;
    mapping(address => bool) public callers;
    address public receiver;
    uint public percent;
    IWETH public WETH;

    function initialize(address _manager, IWETH _WETH, address _receiver, uint _percent) external initializer onlyOwner {
        WETH = _WETH;
        manager = IMarketFeeManager(_manager);
        receiver = _receiver;
        percent = _percent;
        callers[_manager] = true;
    }

    function addCaller(address _caller) external onlyOwner {
        callers[_caller] = true;
    }

    function delCaller(address _caller) external onlyOwner {
        delete callers[_caller];
    }

    modifier onlyOwnerOrCaller() {
        require(msg.sender == owner() || callers[msg.sender], "illegal operator");
        _;
    }

    function getBalance(IERC20 _token) internal returns(uint) {
        if (address(_token) == address(WETH)) {
            uint balance = _token.balanceOf(address(this));
            WETH.withdraw(balance);
            return address(this).balance;
        } else {
            return _token.balanceOf(address(this));
        }
         
    }

    function transfer(IERC20 _token, address _to, uint _amount) internal {
        if (address(_token) == address(WETH)) {
            _to.call{value:_amount}(new bytes(0));
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }

    function dispatch(IERC20[] memory tokens) external onlyOwnerOrCaller {
        for (uint i = 0; i < tokens.length; i ++) {
            IERC20 token = tokens[i];
            uint balance = getBalance(token);
            uint dispatchAmount = balance.mul(percent).div(PERCENT_RATIO);
            uint remainAmount = balance.sub(dispatchAmount);
            if (dispatchAmount > 0) {
                transfer(token, receiver, dispatchAmount);
            }
            if (remainAmount > 0) {
                transfer(token, address(manager), remainAmount);
            }
        }
    }

    function withdraw(IERC20[] memory tokens) external onlyOwnerOrCaller {
        for (uint i = 0; i < tokens.length; i ++) {
            IERC20 token = tokens[i];
            uint balance = getBalance(token);
            if (balance > 0) {
                transfer(token, address(manager), balance);
            }
        }
    }

    function setPercent(uint _percent) external onlyOwnerOrCaller {
        require(_percent <= PERCENT_RATIO, "illegal _percent value");
        percent = _percent;
    }

    receive () external payable {}
}