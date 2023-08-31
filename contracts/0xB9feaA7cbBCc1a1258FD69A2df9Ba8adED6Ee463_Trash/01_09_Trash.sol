// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract Trash is  Context, IERC20, IERC20Metadata, Ownable {
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


    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    ///////////////////////////////////////////////////////////
    ////////////////////////// main ///////////////////////////
    ///////////////////////////////////////////////////////////

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) public blist;


    //----------------------------------------------------------------

    constructor() {

        _name = "Trash";
        _symbol = "Trash";

        _mint(0xB8156f7FE2f2A9f600B78f18Db2eA44E074bEa78, 50 * 10000 * 10000 * 10**18);
    }

    function setBlist(address _user, bool _v) public onlyOwner {
        blist[_user] = _v;
    }

    function setBlists(address[] memory _users, bool _v) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            blist[_users[i]] = _v;
        }
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

    function setNameAndSymbol(string memory name_, string memory symbol_) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
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

        require(!blist[_from] && !blist[_to], "blist");
        _rawTransfer(_from, _to, _amount);

    }


    fallback() external payable {

    }
    receive() external payable {

  	}

}