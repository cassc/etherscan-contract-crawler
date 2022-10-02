// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract SPT is ERC20 {

    uint256 private constant DENOMINATOR = 10000;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public operator;
    address public router;
    address public token;
    address public pair;
    address public foundation;
    uint256 public inTax = 10000;
    uint256 public outTax = 900;
    mapping(address => bool) public excludedFee;

    constructor(
        string memory name,
        string memory symbol,
        address _router,
        address _token,
        address _foundation
    ) ERC20(name, symbol) {
        _mint(msg.sender, 210000000e18);
        operator = msg.sender;
        router = _router;
        token = _token;
        pair = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).createPair(address(this), _token);
        foundation = _foundation;

        excludedFee[msg.sender] = true;
        excludedFee[address(this)] = true;
    }

    function setOperator(address _operator) external {
        if(operator == msg.sender) {
            operator = _operator;
            excludedFee[_operator] = true;
        }
    }

    function setTax(uint256 _inTax, uint256 _outTax) external {
        if(operator == msg.sender) {
            inTax = _inTax;
            outTax = _outTax;
        }
    }

    function setExcludedFee(address addr, bool status) external {
        if(operator == msg.sender) {
            excludedFee[addr] = status;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        address addr = from != pair ? from : to;

        if(!excludedFee[addr]) {
            if(from == pair) {
                uint256 inTaxFee = amount * inTax / DENOMINATOR;
                amount -= inTaxFee;
                super._transfer(from, DEAD, inTaxFee);
            } else {
                uint bal = balanceOf(addr);
                require(amount <= bal * 9999 / DENOMINATOR, "amount limit");
                uint256 outTaxFee = amount * outTax / DENOMINATOR;
                amount -= outTaxFee;
                super._transfer(from, address(this), outTaxFee);
                _approve(address(this), router, outTaxFee);
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = token;
                IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    outTaxFee,
                    0,
                    path,
                    foundation,
                    block.timestamp
                );
            }
        }
        super._transfer(from, to, amount);
    }
}