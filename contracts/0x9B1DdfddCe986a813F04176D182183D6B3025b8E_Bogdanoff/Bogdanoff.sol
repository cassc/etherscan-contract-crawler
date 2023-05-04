/**
 *Submitted for verification at Etherscan.io on 2023-05-03
*/

// SPDX-License-Identifier: Unlicensed

// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡤⠴⠒⠐⠦⢤⡀⠀⠀⠀⠀⠀⠀⠀⠈
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠎⠁⠀⠀⠀⠀⠀⠀⠙⢦⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⢀⡤⠖⠚⠋⠙⣳⠃⠀⠀⢀⣀⠀⠀⠀⠀⠀⠀⠹⡄⠀⠀⠀⠀⠀
// ⠀⠀⣰⠋⠀⠀⠀⠀⢀⡧⠒⣋⡭⠥⠤⢭⣑⠂⠀⠀⠀⠀⠹⣄⡀⠀⠀⠀
// ⠀⢠⣇⣀⣠⣤⣀⣰⣏⡴⠋⠁⠀⠀⠀⠀⠈⠙⣆⠀⡀⠀⠀⠀⠉⢦⡀⠀
// ⣰⢋⣡⠤⠖⠒⠒⢦⣏⠀⢀⣀⣤⣤⡶⢶⡖⢒⡾⠝⠁⠀⠀⠀⠀⠀⢳⠀
// ⢹⣏⠀⢀⣀⣀⣤⣼⡥⠖⠉⠀⠻⠿⠷⢞⡡⢊⠄⢀⣀⣀⡀⠀⠀⠀⠘⡇
// ⢮⠕⠋⠹⣿⣧⣼⢣⠟⡦⠤⡤⠤⠴⣚⡩⢖⣡⠖⠉⠀⠀⠙⡆⠀⠀⢸⡁
// ⠘⡦⣄⣀⣈⣩⢥⠏⠀⠈⠙⠛⠉⢉⡠⠖⠋⠀⢀⡠⠊⠀⢠⠇⠀⢠⠏⡷
// ⠀⢹⣳⠖⠒⠒⠋⢀⣀⣀⠤⠔⠚⠉⠀⣀⡤⠚⠉⠀⣠⠴⠃⠀⡰⢋⡞⠀
// ⠀⠘⡏⠉⠉⠉⠉⠉⠀⢀⣀⡠⠤⠒⠋⠁⢀⡠⠔⠋⠁⠀⣠⠞⣡⢊⡤⠊
// ⠀⠀⠙⣖⠒⠒⠒⠉⠉⠉⠀⢀⣀⠤⠖⠋⠁⠀⠀⠀⣠⠞⣡⠞⠁⡼⠀⠀
// ⠀⠀⠀⠈⢧⠤⠔⠒⠒⠊⠉⠁⠀⠀⢀⣀⣤⣤⣔⣊⡥⠚⢁⣀⡠⠃⠀⠀
// ⠀⠀⠀⠀⠈⠛⠒⢶⠶⠶⠶⠶⠟⠛⠉⠀⠀⠀⣠⠞⠓⠋⠉⢰⠃⠀⠀⠀

pragma solidity ^0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

    function transferOwnership(address newOwner) public virtual onlyOwner {

        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

 contract Bogdanoff is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances; 
    string private constant _name = unicode"Bogdanoff";
    string private constant _symbol = unicode"BOG";
    uint8 private constant _decimals = 18;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private  _totalSupply = 420_69_69_69 * 10**_decimals;

    constructor() {

        _balances[_msgSender()] += _totalSupply;


        emit Transfer(address(0), _msgSender(), _totalSupply);
        
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()]- amount
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

    }
}