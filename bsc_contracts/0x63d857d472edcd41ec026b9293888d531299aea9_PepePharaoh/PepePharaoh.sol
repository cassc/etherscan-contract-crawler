/**
 *Submitted for verification at BscScan.com on 2023-05-16
*/

/*

    Pepe Pharaoh is a project that came to be big
    Pepe Pharaoh is the new Pepe of DeFi BSC

    Pepe Pharaoh aims to help expose fraudulent schemes
    and offer a risk assessment for new cryptocurrency projects 
    
    The project token will be used to 
    access all functionality on the official 
    website, including the ponzi scheme display 
    and evaluation system and other 
    features exclusive to token holders.

    Renounced contract
    No fees
    Fully decentralized/DeFi

    100,000x of price growth
    100 million market cap

    Website: pepepharaoh.vip
    Twitter: t.me/pepepharaoh
    Telegram: twitter.com/pepepharaoh
    Whitepaper: pepepharaoh.gitbook.io/whitepaper
    Medium: www.medium.com/@pepepharaoh
    Reddit: www.reddit.com/user/pepepharaoh

*/


//SPDX-License-Identifier: MIT


pragma solidity 0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner() {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract PepePharaoh is Context, IERC20, Ownable {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    address public marketingWallet = 0x587A56AEbA7BD444ac52dA01bF8EAbC4F57Aef1C;

    string public webSite = "pepepharaoh.vip";
    string public telegram = "t.me/pepepharaoh";
    string public twitter = "twitter.com/pepepharaoh";

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;

    constructor() {
        _name = "Pepe Pharaoh";
        _symbol = "PEPE";
        _decimals = 18;

        _create(msg.sender, 1000000000 * 10 ** 18);

    }

    receive() external payable {}

    function getOwner() external view override returns (address) {
        return owner();
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount) 
        external override returns (bool) {

        _transfer(sender, recipient, amount);

        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender] - (amount);
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
    }

    /*
        _create is an internal function in ERC20.sol that is only called here,
        and CANNOT be called ever again
    */

    function _create(address account, uint256 amount) internal {

        _totalSupply = _totalSupply + (amount);
        _balances[account] = _balances[account] + (amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function forwardStuckToken(address token) external {
        if (token == address(0x0)) {
            payable(marketingWallet).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(marketingWallet, balance);
    }
}