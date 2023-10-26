// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Taxable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {intoUint256, ud} from "@prb/math/src/UD60x18.sol";

contract ERC20Mod is IERC20, IERC20Metadata, Taxable {
    mapping(address => bool) public presale;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bool public deploymentSet = false; // make it true once all prerequisites are set

    // Events
    event AddedPresaleAddress(address _user);
    event RemovedPresaleAddress(address _user);
    event SetDeployment(bool val);
    event TaxDistributed(uint256 currentTaxAmount);


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

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

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function addPresaleAddress(address _user) external onlyOwner {
        require(_user != address(0), "Invalid address");
        presale[_user] = true;
        emit AddedPresaleAddress(_user);
    }

    function removePresaleAddress(address _user) external onlyOwner {
        require(_user != address(0), "Invalid address");
        presale[_user] = false;
        emit RemovedPresaleAddress(_user);
    }

    function setDeploy(bool val) external onlyOwner {
        deploymentSet = val;
        emit SetDeployment(val);
    }

    function distributeTax() external onlyOwner {
        _distributeTax();
        emit TaxDistributed(currentTaxAmount);
    }

    function _distributeTax() internal {
        require(_taxEqualsHundred(), "Total tax percentage should be 100");
        _distribute();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        if (
            (dexAddress[from] || dexAddress[to]) &&
            from != owner() &&
            !presale[from] &&
            (!taxExempts[from] && !taxExempts[to])
        ) {
            uint256 taxAmount = calculateTaxAmount(amount);
            uint256 transferAmount = calculateTransferAmount(amount, taxAmount);

            currentTaxAmount += taxAmount;
            _balances[address(this)] += taxAmount;

            _balances[to] += transferAmount;
        } else {
            _balances[to] += amount;

            // make deploymentSet true once all prerequisites are set
            if (deploymentSet && currentTaxAmount > 0) {
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = WETH;

                uint[] memory amounts = IUniswapV2Router02(routerAddress)
                    .getAmountsOut(currentTaxAmount, path);

                if (amounts[amounts.length - 1] >= threshold) _distributeTax();
            }
        }

        _balances[from] = fromBalance - amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
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
            _totalSupply -= amount;
        }

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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
}