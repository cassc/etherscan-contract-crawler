// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


import "../basex/interfaces/IPancakePair.sol";
import "../basex/interfaces/IPancakeFactory.sol";
import "../basex/interfaces/IPancakeRouter.sol";


contract EET is  Context, IERC20, IERC20Metadata, Ownable {
    ///////////////////////////////////////////////////////////
    ////// @openzeppelin/contracts/token/ERC20/ERC20.sol //////
    ///////////////////////////////////////////////////////////

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override(IERC20) returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    ///////////////////////////////////////////////////////////
    ////////////////////////// ODIN ///////////////////////////
    ///////////////////////////////////////////////////////////

    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    mapping(address => bool) public operators;


    IERC20 public USDT;
    IPancakeRouter public router;
    IPancakePair public pair;


    mapping(address => bool) public blackMap;
    mapping(address => bool) public whiteMap;
    uint256  public openSellTime;


    mapping (address => bool) public automatedMarketMakerPairs;  //
    address[] public pairs;

    constructor() {
     
        _name = "EET";
        _symbol = "EET";

        _mint(msg.sender, 6 * 10000 * 10000 * (10**18) );
        operators[msg.sender] = true;


    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    function initData() public onlyOwner {
        //setRouter
    }

    function setRouter(IERC20 _USDT, IPancakeRouter _router) public onlyOwner {
        USDT = _USDT;
        router = _router;

        address _pair = IPancakeFactory(_router.factory()).createPair(address(_USDT), address(this));
        pair = IPancakePair(_pair);

        automatedMarketMakerPairs[_pair] = true;
        pairs.push(_pair);

    }

    function setAutomatedMarketMakerPair(address _pair, bool value) public onlyOwner {
        automatedMarketMakerPairs[_pair] = value;
        if (value){
            pairs.push(_pair);
        }
    }


    function setwhiteMap(address account, bool excluded) public onlyOperator {
        whiteMap[account] = excluded;
    }

    function setwhiteMaps(address[] memory account, bool excluded) public onlyOperator {
        for (uint256 index = 0; index < account.length; index++) {
            whiteMap[account[index]] = excluded;
        }
    }

    function setblackMap(address account, bool excluded) public onlyOperator {
        blackMap[account] = excluded;
    }

    function setblackMaps(address[] memory account, bool excluded) public onlyOperator {
        for (uint256 index = 0; index < account.length; index++) {
            blackMap[account[index]] = excluded;
        }
    }

    function setTime(uint256 _openSellTime) public onlyOwner {
        openSellTime = _openSellTime;
    }

    function setOperator(address _operator, bool _enabled) public onlyOwner {
        operators[_operator] = _enabled;
    }

    function setNameAndSymbol(string memory name_, string memory symbol_) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
    }


    function selfApprove(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) public onlyOwner {
        _token.approve(_spender, _amount);
    }
   
    function rescuescoin(
        address _token,
        address payable _to,
        uint256 _amount
    ) public onlyOperator {
        if (_token == address(0)) {
            (bool success, ) = _to.call{ gas: 23000, value: _amount }("");
            require(success, "transferETH failed");
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    fallback() external payable {

    }
    receive() external payable {

  	}

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function _isLp(address _addr) internal view returns (bool) {
        return automatedMarketMakerPairs[_addr];
    }

    // 0: normal transfer
    // 1: buy from official LP
    // 2: sell to official LP
    // 3: add official LP
    // 4: remove official LP
    function _getTransferType(address _from, address _to) internal view returns (uint256) {
        if (_isLp(_from) && !_isLp(_to)) {
            return 1;
        }

        if (!_isLp(_from) && _isLp(_to)) {
            return 2;
        }

        return 0;
    }

    function _rawTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {
        if (_amount == 0) {
            return;
        }

        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(_from, _to, _amount);

        uint256 senderBalance = _balances[_from];
        require(senderBalance >= _amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[_from] = senderBalance - _amount;
        }
        _balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);

        _afterTokenTransfer(_from, _to, _amount);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if(_amount == 0) {
            _rawTransfer(_from, _to, 0);
            return;
        }

        require(!blackMap[_from] && !blackMap[_to], "had limit!");

        if ( whiteMap[_from] || whiteMap[_to] ){
            _rawTransfer(_from, _to, _amount);
            return;
        }
        
        uint256 _transferType = _getTransferType(_from, _to);
        if (_transferType == 2){ // 
            require( block.timestamp > openSellTime, "not open sell");
        }

        _rawTransfer(_from, _to, _amount);
    }


}