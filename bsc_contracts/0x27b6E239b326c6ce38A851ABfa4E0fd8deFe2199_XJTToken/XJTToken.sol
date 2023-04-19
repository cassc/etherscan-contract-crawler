/**
 *Submitted for verification at BscScan.com on 2023-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function decimals() external view returns (uint256);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenDistributor {
    constructor(address token) {
        IERC20(token).approve(msg.sender, uint256(~uint256(0)));
    }
}

contract XJTToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name="XJT Token"; 
    string private _symbol="XJT";
    uint256 private _decimals=18;

    uint256 private _tTotal=680000 * 10**18;

    uint256 private _lpFee=300;
    uint256 private _oneFee=100;
    uint256 private _twoFee=60;
    uint256 private _threeFee=40;
    TokenDistributor public _rewardTokenDistributor;
    
    uint256 private currentIndex;

    bool private inSwap;
    address public _mainPair;
    address public fundAddress;
    mapping(address => address) public inviter;
    ISwapRouter public _swapRouter;

    uint256 private constant MAX = ~uint256(0);
    address currency = 0x55d398326f99059fF775485246999027B3197955;
    mapping(address => bool) excludeHolder;

    
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        ISwapRouter swapRouter = ISwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;
        address swapPair = ISwapFactory(swapRouter.factory())
        .createPair(address(this), currency);
        _mainPair = swapPair;

        excludeHolder[address(0)] = true;
        excludeHolder[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;

        _distributionTime=1681743000;

        _rewardTokenDistributor = new TokenDistributor(currency);

        fundAddress=msg.sender;
        _balances[msg.sender] = _tTotal;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    bool openFee;

    function setOpenFee(bool _openFee) public onlyOwner{
        openFee=_openFee;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");

        if(openFee){
            _basicTransfer(from,to,amount);
            return;
        }

        if(balanceOf(to)==0 && inviter[to]==address(0) && from != _mainPair && to != _mainPair &&from != address(this) && to != address(this)){
            inviter[to]=from;
        }

        address upAddr=to;
        if(_mainPair==to){
            upAddr=from;
        }

        if((_mainPair==from || _mainPair==to) && from!=address(this)){
            uint256 lpFee= (amount*_lpFee)/10000;
            _basicTransfer(from,address(this),lpFee);

            uint256 oneFee= (amount*_oneFee)/10000;
            upAddr=inviter[upAddr];
            if (upAddr!=address(0)){
                _basicTransfer(from,upAddr,oneFee);
            }else{
                _basicTransfer(from,fundAddress,oneFee);
            }

            uint256 twoFee= (amount*_twoFee)/10000;
            upAddr=inviter[upAddr];
            if (upAddr!=address(0)){
                _basicTransfer(from,upAddr,twoFee);
            }else{
                _basicTransfer(from,fundAddress,twoFee);
            }

            uint256 threeFee= (amount*_threeFee)/10000;
            upAddr=inviter[upAddr];
            if (upAddr!=address(0)){
                _basicTransfer(from,upAddr,threeFee);
            }else{
                _basicTransfer(from,fundAddress,threeFee);
            }
            amount=amount-lpFee-oneFee-twoFee-threeFee;
        }
        _basicTransfer(from,to,amount);
        if (from != address(this)) {
            if (to==_mainPair){
                addHolder(from);
            }
            processLp(500000);
        }
    }
    
    
    event Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 value
    );

    function swapTokenForFund(uint256 tokenAmount)
        private
        lockTheSwap
    {
        address[] memory path = new address[](2);
        path[0]=address(this);
        path[1]=currency;
        try
            _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(_rewardTokenDistributor),
                block.timestamp
            )
        {} catch {
            emit Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount
            );
        }
    }

    address[] public holders;
    mapping(address => uint256) holderIndex;
    function addHolder(address adr) private {
        uint256 size;
        assembly {
            size := extcodesize(adr)
        }
        if (size > 0) {
            return;
        }
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    uint256 private _distributionTime;


    function processLp(uint256 gas) private {
        if (block.timestamp<=_distributionTime){
            return ;
        }
        uint256 day = (block.timestamp-_distributionTime)/600; //86400;
        if (day==0){
            return;
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        if ( !inSwap && contractTokenBalance>0){
            swapTokenForFund(contractTokenBalance);
        }
        _distributionTime+=600*day; //86400

        IERC20 lp = IERC20(_mainPair);
        uint lpTokenTotal=lp.totalSupply();
        if (lpTokenTotal==0){
            return;
        }

        IERC20 usdt = IERC20(currency);

        uint256 balance;
        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = holders.length;
        
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        balance = usdt.balanceOf(address(_rewardTokenDistributor));
        if (balance==0){
            return;
        }
        usdt.transferFrom(
            address(_rewardTokenDistributor),
            address(this),
            balance
        );

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            tokenBalance = lp.balanceOf(shareHolder);
            if (tokenBalance > 0 && !excludeHolder[shareHolder]) {
                amount = (balance * tokenBalance) / lpTokenTotal;
                if (amount > 0 && usdt.balanceOf(address(this)) > amount) {
                    usdt.transfer(shareHolder, amount);
                }
            }
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
}