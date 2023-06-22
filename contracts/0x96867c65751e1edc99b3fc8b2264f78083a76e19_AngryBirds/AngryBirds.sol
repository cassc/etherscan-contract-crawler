/**
 *Submitted for verification at Etherscan.io on 2023-06-19
*/

// Website: https://www.angrybird.pro 
// Twitter: https://twitter.com/AngrybirdETH  
// Telegram: https://t.me/Angrybird_ETH

// ___  
//      ,-"" _ ""-. 
//    ,' _ ""  `  \ 
//   / ,        `. \
//  / /           \ \
// / /             \ \
// \_\           /_/
//   `""--...--""`

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}

contract AngryBirds is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isExcluded;
    mapping(address => bool) public ammPairs;
    mapping (uint256 => uint256) public tradingCount;
   
    uint8 private _decimals = 18;
    uint256 private _tTotal;
    uint256 public supply = 1000000000000000 * (10 ** 18);

    string private _name = "AngryBirds";
    string private _symbol = "AGBIRD";

    address public router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public initPoolAddress = 0x57B9790846b1067ae4e37e277B3384A62Bc81d1D;

    uint256 launchedBlock;
    bool openTransaction;
    uint256 private firstBlock = 1;
    uint256 private secondBlock = 4;

    uint256 tradingCountLimit = 7;
    
    constructor () {
        _tOwned[initPoolAddress] = supply;
        _tTotal = supply;

        isExcluded[address(msg.sender)] = true;
        isExcluded[initPoolAddress] = true;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);

        address ethPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        ammPairs[ethPair] = true;

        emit Transfer(address(0), initPoolAddress, _tTotal);
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
        return _tOwned[account];
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "AngryBirds: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "AngryBirds: decreased allowance below zero"));
        return true;
    }

    receive() external payable {}

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "AngryBirds: approve from the zero address");
        require(spender != address(0), "AngryBirds: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "AngryBirds: transfer from the zero address");
        require(amount > 0, "AngryBirds: transfer amount must be greater than zero");

        uint256 fee;

        if(isExcluded[from] || isExcluded[to]){
            return _tokenTransfer(from,to,amount,fee); 
        }

        require(openTransaction,"AngryBirds: Not open");

        uint256 currentBlock = block.number;

        if (ammPairs[from]) {
            if (currentBlock - launchedBlock < firstBlock + 1) {
                fee = amount.mul(95).div(100);
            } else if (currentBlock - launchedBlock < secondBlock + 1) {
                tradingCount[currentBlock] = tradingCount[currentBlock] + 1;
                if (tradingCount[currentBlock] > tradingCountLimit) {
                    fee = amount.mul(95).div(100);
                }
            }
        }

        _tokenTransfer(from,to,amount,fee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, uint256 fee) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount.sub(fee));
        emit Transfer(sender, recipient, tAmount.sub(fee));
        
        if (fee > 0) {
            _tOwned[address(this)] = _tOwned[address(this)].add(fee);
            emit Transfer(sender, address(this), fee);
        }
    }

    function setOpenTransaction() external onlyOwner {
        require(openTransaction == false, "AngryBirds: Already opened");
        openTransaction = true;
        launchedBlock = block.number;
    }

    function muliSetExclude(address[] calldata users, bool _isExclude) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            isExcluded[users[i]] = _isExclude;
        }
    }

}