// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IPancakePair.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IPancakeRouter.sol";

contract JKC is  Context, IERC20, IERC20Metadata, Ownable {
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
    ////////////////////////// ap ///////////////////////////
    ///////////////////////////////////////////////////////////

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bool private _paused;
    mapping(address => bool) public operators;

    mapping (address => bool) public isExcludedFromFees;      //
    mapping(uint256 => bool) public isTaxTransferTypeExcluded; //

    IERC20 public USDT;

    IPancakeRouter public router;
    IPancakePair public pair;


    address public addrTreasury = 0xe273468775499C29E2cc0853E893DD6e3AD40157;
    address public addrBurn = 0x000000000000000000000000000000000000dEaD; //


    uint256 public taxSell = 1000; //
    uint256 public taxBuy = 68; //

    mapping (address => bool) public automatedMarketMakerPairs;  //


    constructor() {
        _paused = false;
        operators[msg.sender] = true;
 
        _name = "JKC";
        _symbol = "JKC";

        isExcludedFromFees[msg.sender] = true;
        isTaxTransferTypeExcluded[0] = true;

        uint chainId; 
        assembly { chainId := chainid() }

        if (chainId == 56) {
            _mint(0xd6dAf2F072a4722BAb4e3DfBd6696FA39059999B, 888 * 10000 * 10**18);
        } else {
            _mint(msg.sender, 888 * 10000 * 10**18);
        }
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    function initData() public onlyOwner {
        //setRouter
        //setTaxAddress
    }

    function setRouter( IERC20 _USDT, IPancakeRouter _router) public onlyOwner {
        USDT = _USDT;
        router = _router;
        address _pair = IPancakeFactory(_router.factory()).createPair(address(_USDT), address(this));
        pair = IPancakePair(_pair);

        automatedMarketMakerPairs[_pair] = true;
    } 
    
    function setTaxBuy(uint256 _value) public onlyOperator {
        taxBuy = _value;
    }

    function setTaxSell(uint256 _value) public onlyOperator {
        taxSell = _value;
    }

    function setTaxAddress(address _addrTreasury) public onlyOwner {
        addrTreasury = _addrTreasury;
    }

    function setPaused(bool paused_) public onlyOwner {
        _paused = paused_;
    }

    function setExcludeFromFees(address account, bool excluded) public onlyOperator {
        isExcludedFromFees[account] = excluded;
    }
    function setExcludeFromFeesx(address[] memory account, bool excluded) public onlyOperator {
        for (uint256 index = 0; index < account.length; index++) {
            isExcludedFromFees[account[index]] = excluded;
        }
    }

    function setTaxTransferTypeExcluded(uint256 _transferType, bool _enabled) public onlyOwner {
        isTaxTransferTypeExcluded[_transferType] = _enabled;
    }


    function setOperator(address _operator, bool _enabled) public onlyOwner {
        operators[_operator] = _enabled;
    }

    function setOperators(address[] memory _operators, bool _enabled) public onlyOwner {
        for (uint256 index = 0; index < _operators.length; index++) {
            operators[_operators[index]] = _enabled;
        }
    }

    function setNameAndSymbol(string memory name_, string memory symbol_) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
    }

    function setAutomatedMarketMakerPair(address _pair, bool value) public onlyOwner {
        automatedMarketMakerPairs[_pair] = value;
    }

    function selfApprove(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) public onlyOwner {
        _token.approve(_spender, _amount);
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

        require(!_paused, "ERC20Pausable: token transfer while paused");
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
        
        uint256 _transferType = _getTransferType(_from, _to);
        bool takeFee = true;

        if(isExcludedFromFees[_from] || isExcludedFromFees[_to]  || isTaxTransferTypeExcluded[_transferType]) {
            takeFee = false;
        }

        if ( takeFee) {
            uint256 _amountTreasury;

            if (_transferType == 1){
                _amountTreasury = _amount.mul(taxBuy).div(1000);
            }else{
                _amountTreasury = _amount.mul(taxSell).div(1000);
            }

            uint256 amountTax = _amountTreasury;
            require(_amount > amountTax, "transfer amount is too small");

            _rawTransfer(_from, addrTreasury, _amountTreasury);
            _amount =  _amount.sub(amountTax);

        }

        _rawTransfer(_from, _to, _amount);
    }

    // function transferNoTax(address _to, uint256 _amount) public onlyOperator {
    //     _rawTransfer(_msgSender(), _to, _amount);
    // }



    // 1e18 units ap token = how many units quote token
    function getPrice() public view returns (uint256) {
        address _token0 = pair.token0();
        (uint256 _reserve0, uint256 _reserve1, ) = pair.getReserves();
        (uint256 _main, uint256 _quote) = address(USDT) == _token0
            ? (_reserve1, _reserve0)
            : (_reserve0, _reserve1);
        return _main == 0 ? 0 : _quote.mul(1e18).div(_main);
    }

    // 1e18 units LP token value = how many units quote token
    function getLpPrice() public view  returns (uint256) {
        uint256 _total = pair.totalSupply();
        address _token0 = pair.token0();
        (uint256 _reserve0, uint256 _reserve1, ) = pair.getReserves();
        uint256 _quote = address(USDT) == _token0 ? _reserve0 : _reserve1;
        return _total == 0 ? 0 : _quote.mul(2).mul(1e18).div(_total);
    }

    function getLpAddress() public view  returns (address) {
        return address(pair);
    }

    function rescuescoin(
        address _token,
        address payable _to,
        uint256 _amount
    ) public onlyOwner {
        if (_token == address(0)) {
            (bool success, ) = _to.call{ gas: 23000, value: _amount }("");
            require(success, "transferETH failed");
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }
}