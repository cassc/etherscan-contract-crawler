// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./interfaces/IERC20.sol";
import "./utils/Ownable.sol";
import "./interfaces/IEMEFactory.sol";
import "./math/SafeMath.sol";
import "./SwapRouter.sol";

interface IMosPool {
    function donate(uint256 value) external;
}

contract MosToken is IERC20, Ownable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => bool) public minner;
    address public mosPair;
    address public constant hole = 0x000000000000000000000000000000000000dEaD;
    IMosPool public mosPool;
    address public pairReceiver;
    SwapRouter public _router;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    constructor(
        address _pairReceiver,
        IEMEFactory _swapFactory,
        address _usdt
    ) {
        name = "mos";
        symbol = "mos";
        decimals = 18;
        totalSupply = 100000000e18;
        balanceOf[_msgSender()] = 100000000e18;

        pairReceiver = _pairReceiver;
        mosPair = _swapFactory.createPair(address(this), _usdt);
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function updateRouter(address _rou) public onlyOwner {
        _router = SwapRouter(_rou);
        allowance[address(this)][address(_router)] = type(uint256).max;
        emit Approval(address(this), address(_router), type(uint256).max);
    }

    function setMosPool(IMosPool _mosPool) external onlyOwner {
        mosPool = _mosPool;
        allowance[address(this)][address(mosPool)] = type(uint256).max;
        emit Approval(address(this), address(mosPool), type(uint256).max);
    }

    function setMinner(address _minner, bool enable) external onlyOwner {
        minner[_minner] = enable;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0), "zero address");
        require(balanceOf[from] >= amount, "balance not enough");
        balanceOf[from] = balanceOf[from].sub(amount);
        if (
            to == mosPair && !minner[from] && !minner[to] && !inSwapAndLiquify
        ) {
            amount = updateFee(from, amount);
        }
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function updateFee(
        address from,
        uint256 amount
    ) private lockTheSwap returns (uint256) {
        uint256 value = amount;
        if (totalSupply > 100000 * 10 ** decimals) {
            uint256 _black = value.div(100);
            if (totalSupply.sub(_black) < 100000 * 10 ** decimals) {
                _black = totalSupply.sub(100000 * 10 ** decimals);
            }

            amount = amount.sub(_black);
            totalSupply = totalSupply.sub(_black);
            balanceOf[hole] = balanceOf[hole].add(_black);
            emit Transfer(from, hole, _black);
        }

        if (swapAndLiquifyEnabled) {
            //add liquidity
            amount = amount.sub((value * 1) / 100);
            balanceOf[address(this)] += (value * 1) / 100;
            _router.swapAndLiquifyToken((value * 1) / 100);
        }

        amount = amount.sub((value * 1) / 100);
        balanceOf[address(this)] += (value * 1) / 100;
        emit Transfer(from, address(this), (value * 1) / 100);

        mosPool.donate(value / 100);
        return amount;
    }

    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        require(allowance[from][msg.sender] >= amount, "allowance not enough");

        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);

        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        require(spender != address(0), "zero address");

        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }
}