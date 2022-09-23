// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/uniswapv2.sol";


contract UbxtSeller is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) public whiteList;

    address public constant ubxt = 0xBbEB90cFb6FAFa1F69AA130B7341089AbeEF5811;
    address public constant busd = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public constant pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // mainnet v2

    uint256 public constant pancakeswapSlippage = 10;

    event FundTransfer(address, uint256);
    event Received(address, uint256);
    event DepositUbxt(address, uint256);
    event WithdrawUbxt(address, uint256);
    event WithdrawBusd(address, uint256);
    event Sell(uint256);
    event WhiteListAdded(address);
    event WhiteListRemoved(address);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    constructor()
    {
        whiteList[msg.sender] = true;
    }

    function depositUbxt(uint256 amount) external onlyOwner {
        
        IERC20(ubxt).safeTransferFrom(msg.sender, address(this), amount);
        emit DepositUbxt(msg.sender, amount);
    }

    function withdrawUbxt(uint256 amount) external onlyOwner {
        require (IERC20(ubxt).balanceOf(address(this)) >= amount, "not enough amount to withdraw");
        
        IERC20(ubxt).safeTransfer(msg.sender, amount);
        emit WithdrawUbxt(msg.sender, amount);
    }

    function withdrawBusd(uint256 amount) external onlyOwner {
        require (IERC20(busd).balanceOf(address(this)) >= amount, "not enough amount to withdraw");
        
        IERC20(busd).safeTransfer(msg.sender, amount);
        emit WithdrawBusd(msg.sender, amount);
    }

    function sellUbxt(uint256 amount) external {
        require(whiteList[msg.sender], "Not whitelisted");
        require (IERC20(ubxt).balanceOf(address(this)) >= 0, "not enough amount to withdraw");

        _swapPancakeswap(ubxt, busd, amount);
        emit Sell(amount);
    }

    function addToWhiteList(address _address) external onlyOwner {
        require(_address != address(0),"white list address zero");
        whiteList[_address] = true;
        emit WhiteListAdded(_address);
    }

    function removeFromWhiteList(address _address) external onlyOwner {
        require(_address != address(0),"white list address zero");
        whiteList[_address] = false;
        emit WhiteListRemoved(_address);
    }

    function _swapPancakeswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_from != address(0) && _to != address(0), "from or to zero address");

        if (_from == _to) {
            return;
        }

        // Swap with uniswap
        assert(IERC20(_from).approve(pancakeRouter, 0));
        assert(IERC20(_from).approve(pancakeRouter, _amount));

        address[] memory path;

        path = new address[](2);
        path[0] = _from;
        path[1] = _to;

        uint256[] memory amounts = UniswapRouterV2(pancakeRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp + 60
        );

        require(amounts[0] > 0, "amounts[0] zero  amount");
    }
}