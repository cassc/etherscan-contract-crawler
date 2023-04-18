// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "./ERC20v2.sol";
// import "hardhat/console.sol";

interface ICharity {

    function isCharity() external view returns (bool);

}

interface IPancakeRouter {

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (
        uint256[] memory amounts
    );

}

/*
生命从来不曾离开过孤独而独立存在。无论是我们出生、我们成长、我们相爱还是我们成功失败，直到最后的最后，孤独犹如影子一样存在于生命一隅。
*/
contract Hello is ERC20 {

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = address(0x0);

    uint256 private _totalShares;
    address private _taxHolder;

    constructor(uint256[] memory drops) ERC20("HelloV12", "HEL12") {
        for (uint256 i = 0; i < drops.length; i++) {
            address user = address(uint160(drops[i] >> 96));
            uint256 amt = uint256(uint96(drops[i])) * 1e18;
            _mint(user, amt);
        }
        _totalShares = _totalSupply;
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 shares = _balances[account];
        return _totalSupply * shares / _totalShares;
    }

    function sharesOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        _transfer0(from, to, amount, false);
    }

    function _transfer0(address from, address to, uint256 amount, bool charitable) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // _beforeTokenTransfer(from, to, amount);

        uint256 fromShares = _balances[from];
        uint256 amtShares = _totalShares * amount / _totalSupply;
        require(fromShares >= amtShares, "ERC20: transfer amount exceeds balance");

        _balances[from] -= amtShares;
        uint256 receivedAmount = amount;
        uint256 receivedShares = amtShares;

        bool taxFree = charitable || allEOA(from, to) || from == _taxHolder;
        if (!taxFree) {
            if (_taxHolder == ZERO) {
                _taxHolder = address(new TaxHolder(address(this)));
            }

            // send 1% of the transfer amount to DEAD
            uint256 toDeadAmount = amount    / 100;
            uint256 toDeadShares = amtShares / 100;
            receivedAmount  -= toDeadAmount;
            receivedShares  -= toDeadShares;
            _balances[DEAD] += toDeadShares;
            emit Transfer(from, DEAD, toDeadAmount);

            // send 0.5% of the transfer amount to others
            uint256 toAllAmount = amount    * 5 / 1000;
            uint256 toAllShares = amtShares * 5 / 1000;
            receivedAmount -= toAllAmount;
            receivedShares -= toAllShares;
            _totalShares   -= toAllShares;
            emit Transfer(from, ZERO, toAllAmount);

            // keep 0.5% of the transfer amount for pool
            uint256 toPoolAmount = amount    * 5 / 1000;
            uint256 toPoolShares = amtShares * 5 / 1000;
            receivedAmount  -= toPoolAmount;
            receivedShares  -= toPoolShares;
            _balances[_taxHolder] += toPoolShares;
            emit Transfer(from, _taxHolder, toPoolAmount);
        }

        _balances[to] += receivedShares;
        emit Transfer(from, to, receivedAmount);

        if (taxFree && from != _taxHolder && _taxHolder != ZERO) {
            TaxHolder(_taxHolder).addToPool();
        }

        // _afterTokenTransfer(from, to, amount);
    }

    function transferToCharity(address from, uint256 amount) public {
        address spender = _msgSender();
        require(ICharity(spender).isCharity(), 'msg sender is not charity');
        _spendAllowance(from, spender, amount);
        _transfer0(from, spender, amount, true);
    }
    function transferFromCharity(address to, uint256 amount) public {
        address owner = _msgSender();
        require(ICharity(owner).isCharity(), 'msg sender is not charity');
        _transfer0(owner, to, amount, true);
    }

    function allEOA(address a, address b) private view returns (bool) {
        return !Address.isContract(a) && !Address.isContract(b);
    }

}

contract TaxHolder {

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    // https://docs.pancakeswap.finance/code/smart-contracts/pancakeswap-exchange/v2/router-v2
    address private constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    // testnet
    // address private constant PANCAKE_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    // address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    address private immutable TOKEN_ADDR;

    constructor(address tokenAddr) {
        TOKEN_ADDR = tokenAddr;
    }

    function addToPool() public {
        uint256 tokenAmt = ERC20(TOKEN_ADDR).balanceOf(address(this));
        if (tokenAmt == 0) {
            return;
        } 

        // swap HEL for WBNB
        ERC20(TOKEN_ADDR).approve(PANCAKE_ROUTER, tokenAmt * 2);
        address[] memory path = new address[](2);
        (path[0], path[1]) = (TOKEN_ADDR, WBNB);
        uint256[] memory swapResult = IPancakeRouter(PANCAKE_ROUTER).swapExactTokensForTokens(
            tokenAmt / 2, 0, path, address(this), type(uint256).max);

        // add liquidity
        ERC20(WBNB).approve(PANCAKE_ROUTER, swapResult[1]);
        IPancakeRouter(PANCAKE_ROUTER).addLiquidity(
            TOKEN_ADDR, WBNB, tokenAmt / 2, swapResult[1], 0, 0, DEAD, type(uint256).max);
    }

}

// TODO: is ERC20
contract Charity is ICharity {

    address immutable public TOKEN_ADDR;

    constructor(address tokenAddr) {
        TOKEN_ADDR = tokenAddr;
    }

    function isCharity() external override pure returns (bool) {
        return true;
    }

    function deposit(uint256 amount) public {
        // TODO
        Hello(TOKEN_ADDR).transferToCharity(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        // TODO
        Hello(TOKEN_ADDR).transferFromCharity(msg.sender, amount);
    }

}