/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "./ManageableUpgradeable.sol";

contract Token is
    Initializable,
    IERC20Upgradeable,
    OwnableUpgradeable,
    ManageableUpgradeable
{
    uint256 public override totalSupply;
    uint256 public maxSupply;

    string public name;
    uint8 public decimals;
    string public symbol;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => bool) public isBlacklisted;

    function initialize(
        uint256 _initialAmount,
        uint256 _maxAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public initializer {
        __Ownable_init();
        balances[_msgSender()] = _initialAmount;
        totalSupply = _initialAmount;
        maxSupply = _maxAmount;
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;

        emit Transfer(address(0), _msgSender(), _initialAmount);
        emit OwnershipTransferred(address(0), _msgSender());
    }

    function _transfer(address _from, address _to, uint256 _value) private {
        require(
            _from != address(0),
            "TRANSFER: Transfer from the dead address"
        );
        require(_to != address(0), "TRANSFER: Transfer to the dead address");
        require(_value >= 0, "TRANSFER: Invalid amount");
        require(isBlacklisted[_from] == false, "TRANSFER: isBlacklisted");
        require(balances[_from] >= _value, "TRANSFER: Insufficient balance");
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        _transfer(_msgSender(), _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        _spendAllowance(_from, _msgSender(), _value);
        _transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(
        address _owner
    ) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(
        address _spender,
        uint256 _value
    ) public override returns (bool success) {
        _approve(_msgSender(), _spender, _value);
        return true;
    }

    function _approve(
        address _sender,
        address _spender,
        uint256 _value
    ) private returns (bool success) {
        allowances[_sender][_spender] = _value;
        emit Approval(_sender, _spender, _value);
        return true;
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

    function allowance(
        address _owner,
        address _spender
    ) public view override returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    function mint(
        address _to,
        uint256 _value
    ) public onlyManager returns (bool success) {
        require(_to != address(0), "MINT: Transfer to the dead address");
        require(_value > 0, "MINT: Invalid amount");
        require(isBlacklisted[_to] == false, "TRANSFER: isBlacklisted");
        _mint(_to, _value);
        return true;
    }

    function _mint(address _to, uint256 _value) internal {
        totalSupply += _value;
        require(totalSupply <= maxSupply, "MINT: Max supply reached");
        unchecked {
            balances[_to] += _value;
        }
        emit Transfer(address(0), _to, _value);
    }

    function burn(uint256 _value) public {
        _burn(_msgSender(), _value);
    }

    function burnFrom(address _to, uint256 _value) public {
        _spendAllowance(_to, _msgSender(), _value);
        _burn(_to, _value);
    }

    function _burn(address _to, uint256 _value) internal {
        require(_to != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balances[_to];
        require(accountBalance >= _value, "ERC20: burn amount exceeds balance");
        unchecked {
            balances[_to] = accountBalance - _value;
            totalSupply -= _value;
        }

        emit Transfer(_to, address(0), _value);
    }

    function setIsBlacklisted(address user, bool value) public onlyOwner {
        isBlacklisted[user] = value;
    }

    receive() external payable {}

    fallback() external payable {}
}