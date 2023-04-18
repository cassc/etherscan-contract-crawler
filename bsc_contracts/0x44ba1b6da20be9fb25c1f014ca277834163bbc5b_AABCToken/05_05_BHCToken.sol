// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

interface IUniswapV2Router {
    function factory() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// AABCToken
contract AABCToken is IERC20, Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint8 private _decimals = 18;

    uint256 private _tTotal = 9999 ether;

    string private _name = "AABC Token";
    string private _symbol = "AABC";

    // uint256 public constant _destroyLimit = 6999 ether;
    uint256 public constant _addPriceTokenAmount = 0.01 ether;

    bool public isTradeOpen;
    // pair's token is Token0
    bool public immutable pairTokenIsToken0;

    address public immutable creator;
    address public immutable pinkLockAddr;
    address public immutable uniswapV2Pair;
    address public immutable pinkDivideReceive;

    // blackHole & usdt
    address public constant blackHole = address(0xdead);
    address public constant usdtAddr = 0x55d398326f99059fF775485246999027B3197955;
    //
    IUniswapV2Router public constant uniswapV2Router = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    EnumerableSet.AddressSet lpHolders;

    struct LPInteraction {
        uint256 index;
        uint256 period;
        uint256 lastDivideTime;
        uint256 canDivideAmount;
        uint256 divideLimit;
    }

    LPInteraction private lpInteraction;

    struct LpAwardCondition {
        uint lpHoldAmount;
        uint balHoldAmount;
    }

    LpAwardCondition public lpAwardCondition;

    struct InteractionInfo {
        uint period;
        uint lastDivideTime;
        uint canDivideAmount;
        uint lpHolderCount;
        uint divideLimit;
    }

    constructor () {
        // At least hold 0.1 Token & LP hold 0.1 Token
        lpAwardCondition = LpAwardCondition(0.1 ether, 0.1 ether);

        address _addrThis = address(this);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(_addrThis, usdtAddr);

        bool _pairTokenIsToken0;
        // Judge pair's token0 is token
        if (IUniswapV2Pair(uniswapV2Pair).token0() == _addrThis) {
            _pairTokenIsToken0 = true;
        }

        pairTokenIsToken0 = _pairTokenIsToken0;

        lpInteraction.lastDivideTime = block.timestamp;
        lpInteraction.period = 30 minutes;
        lpInteraction.divideLimit = 100;

        // pinkLockAddr
        pinkLockAddr = 0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE;
        pinkDivideReceive = 0x1ecDFdF20586D7F7ADfe3b4749533cdd503B6281;

        creator = _msgSender();

        _balances[creator] = _tTotal;

        emit Transfer(address(0), creator, _tTotal);
    }

    function setLpAwardCondition(uint lpHoldAmount, uint balHoldAmount) external onlyOwner {
        lpAwardCondition.lpHoldAmount = lpHoldAmount;
        lpAwardCondition.balHoldAmount = balHoldAmount;
    }

    function getInteractionInfo() external view returns (InteractionInfo memory lpI) {
        lpI.period = lpInteraction.period;
        lpI.lastDivideTime = lpInteraction.lastDivideTime;
        lpI.canDivideAmount = lpInteraction.canDivideAmount;
        lpI.lpHolderCount = lpHolders.length();
        lpI.divideLimit = lpInteraction.divideLimit;
    }

    // addrIsInLpHolders
    function addrIsInLpHolders(address owner) external view returns (bool) {
        return lpHolders.contains(owner);
    }

    function getLpHolders(uint256 startIndex, uint256 endIndex) external view returns (address[] memory) {
        // creator can see
        require(creator == msg.sender, "Caller is not the creator");
        // counts
        uint256 counts = lpHolders.length();
        //
        if (endIndex > counts) {
            endIndex = counts;
        }
        address[] memory addrList = new address[](endIndex-startIndex);
        // get all lpHolders
        for (uint256 i = startIndex; i < endIndex ; i++) {
            addrList[i] = lpHolders.at(i);
        }
        // addrList
        return addrList;
    }

    function setTradeOpen(bool _isOpen) external onlyOwner {
        isTradeOpen = _isOpen;
    }

    function setInteraction(uint _period, uint _divideLimit) external onlyOwner {
        lpInteraction.period = _period;
        lpInteraction.divideLimit = _divideLimit;
    }

    function checkSetLpShare(address _addr) external {
        require(creator == msg.sender, "Caller is not the creator");
        setLpShare(_addr);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _doDividend(address sender, address recipient, uint256 tAmount) private {
        _balances[sender] -= tAmount;
        _balances[recipient] += tAmount;
        emit Transfer(sender, recipient, tAmount);
    }

    // _isLiquidity
    function _isLiquidity(address from, address to) internal view returns (bool isAdd, bool isRemove) {
        // Token Address
        address pairAddr = uniswapV2Pair;
        // getReserves
        (uint r0, uint256 r1,) = IUniswapV2Pair(pairAddr).getReserves();
        // Get pair usdt amount
        uint256 pairUsdtBal = IERC20(usdtAddr).balanceOf(pairAddr);
        // judge token is token0
        if (pairTokenIsToken0) {
            // AddLiquidity
            if (pairAddr == to && pairUsdtBal > r1) {
                isAdd = pairUsdtBal - r1 > _addPriceTokenAmount;
            }
            // Remove Liquidity
            if (pairAddr == from && pairUsdtBal <= r1) {
                isRemove = true;
            }
        } else {
            // AddLiquidity
            if (pairAddr == to && pairUsdtBal > r0) {
                isAdd = pairUsdtBal - r0 > _addPriceTokenAmount;
            }
            // Remove Liquidity
            if (pairAddr == from && pairUsdtBal < r0) {
                isRemove = true;
            }
        }
    }

    // handle transfer with fee
    function _handleTakeFee(address from, uint256 totalFee) private {
        // this contract address
        address _addrThis = address(this);
        // 0.5% to blackHole
        uint256 toBlackHole;
        // Is Touched DestroyLimit
        if (balanceOf(blackHole) < 6999 ether) {
            // toBlackHoleAmount
            toBlackHole = totalFee * 25 / 100;

            _balances[blackHole] += toBlackHole;
            emit Transfer(from, blackHole, toBlackHole);
        }
        // 1.5% to lp divide
        uint256 toLpDividend = totalFee - toBlackHole;
        // increase canDivideAmount
        lpInteraction.canDivideAmount += toLpDividend;

        _balances[_addrThis] += toLpDividend;

        emit Transfer(from, _addrThis, toLpDividend);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // fromBalance
        uint256 fromBalance = _balances[from];
        // User Balance should be greater than amount
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        // decrease user's balance
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        // Is Swap Token
        if (uniswapV2Pair == from || uniswapV2Pair == to) {
            // _takeFee
            bool _takeFee;
            // _isLiquidity
            (bool isAddLp, bool isRemoveLp) = _isLiquidity(from, to);
            // Trade is Buy 0r remove liquidity
            if (uniswapV2Pair == from) {
                // Isn't remove liquidity
                if (!isRemoveLp) {
                    _takeFee = true;
                }
                setLpShare(to);
            } else {
                // only tradeOpen Or addLp Or removeLp
                require(isTradeOpen || isAddLp || isRemoveLp, "Trade is not open");
                // Isn't add liquidity
                if (!isAddLp) {
                    _takeFee = true;
                }
                setLpShare(from);
            }
            // _takeFee 2%
            if (_takeFee) {
                // totalFee 2% ==> 1.5 -> lpShare && 0.5 -> blackHole
                uint256 totalFee = amount * 20 / 1000;
                // receive amount = transfer amount - totalFee
                amount -= totalFee;
                // _handleTakeFee
                _handleTakeFee(from, totalFee);
            }
            // Save gas
            LPInteraction memory _lpInteract = lpInteraction;
            // LpDividend
            if (block.timestamp > _lpInteract.lastDivideTime + _lpInteract.period
            && _lpInteract.canDivideAmount > 0.001 ether && balanceOf(address(this)) >= _lpInteract.canDivideAmount ) {
                // divide time
                lpInteraction.lastDivideTime = block.timestamp;
                // do divide
                processLpDividend(_lpInteract);
            }
        }
        // Transfer or liquidity
        _balances[to] += amount;
        // Transfer event
        emit Transfer(from, to, amount);
    }

    function processLpDividend(LPInteraction memory _lpInteract) private {
        // Get Lp hold Count
        uint256 shareholderCount = lpHolders.length();

        if (shareholderCount == 0) return;

        // dividend 80% --> remain 20%
        uint256 canDivideAmount = _lpInteract.canDivideAmount * 80 / 100;
        uint256 remainAmount = _lpInteract.canDivideAmount - canDivideAmount;

        IUniswapV2Pair lpToken = IUniswapV2Pair(uniswapV2Pair);
        // surplusAmount
        uint256 surplusAmount = canDivideAmount;
        // iterations
        uint256 iterations = 0;
        uint256 currentIndex = _lpInteract.index;

        uint256 divideLimit = _lpInteract.divideLimit;
        uint256 ts = lpToken.totalSupply();

        address _addrThis = address(this);
        address _pinkLockAddr = pinkLockAddr;

        while (iterations < divideLimit && iterations < shareholderCount) {
            // greaterOrEqual than totalHolderCount
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            address shareholder = lpHolders.at(currentIndex);

            uint256 amount = canDivideAmount * lpToken.balanceOf(shareholder) / ts;

            if (balanceOf(_addrThis) < amount || surplusAmount < amount) {
                break;
            }

            if (shareholder == _pinkLockAddr) {
                shareholder = pinkDivideReceive;
            }

            if (amount >= 0.001 ether) {
                surplusAmount -= amount;
                _doDividend(_addrThis, shareholder, amount);
            }

            iterations++;
            currentIndex++;
        }
        lpInteraction.index = currentIndex;
        lpInteraction.canDivideAmount = surplusAmount + remainAmount;
    }

    // setLpShare
    function setLpShare(address owner) private {

        if (lpHolders.contains(owner)) {
            // User has Removed lp
            if (!checkLpAwardCondition(owner)) {
                lpHolders.remove(owner);
            }
            return;
        }
        // User is not in lpHolder
        if (checkLpAwardCondition(owner)) {
            lpHolders.add(owner);
        }
    }

    function checkLpAwardCondition(address owner) internal view returns (bool){
        // LpAwardCondition
        LpAwardCondition memory _lpCondition = lpAwardCondition;
        // uniswapV2PairERC20
        IUniswapV2Pair lpToken = IUniswapV2Pair(uniswapV2Pair);
        // token > 0.1 ether && lp > 0.1 ether
        uint256 lpAmount = lpToken.balanceOf(owner);
        // user should hold enough lp
        if (lpAmount == 0) {
            return false;
        }
        // user should hold enough token
        if (balanceOf(owner) < _lpCondition.balHoldAmount) {
            return false;
        }
        // lp total supply
        uint256 supply = lpToken.totalSupply();

        if (supply == 0) {
            return false;
        }
        // getReserves
        (uint256 r0,uint256 r1,) = lpToken.getReserves();
        // judge lp holder price
        if (pairTokenIsToken0) {
            return lpAmount * r0 / supply >= lpAwardCondition.lpHoldAmount;
        } else {
            return lpAmount * r1 / supply >= lpAwardCondition.lpHoldAmount;
        }
    }

    // receive() external payable {}

}