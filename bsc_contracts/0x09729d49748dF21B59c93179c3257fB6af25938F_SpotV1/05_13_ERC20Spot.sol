pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../RDN/RDNOwnable.sol";


contract ERC20Spot is IERC20, RDNOwnable {

    mapping(uint => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    uint private _totalSupply;
    string private _name;
    string private _symbol;

    function initERC20Spot(address _registry, uint _ownerId) internal {
        _symbol = 'SPOT0';
        _name = "SPOTv0 Share Token";

        initRDNOwnable(_registry, _ownerId);

    }


    function balanceOf(address _account) public view returns (uint) {
        uint userId = IRDNRegistry(registry).getUserIdByAddress(_account);
        return _balances[userId];
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function transfer(address to, uint amount) external returns (bool) {
        return false;
    }

    function approve(address spender, uint amount) external returns (bool) {
        return false;
    }

    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool) {
        return false;
    }

    function _mint(uint userId, uint amount) internal {
        address account = IRDNRegistry(registry).getUserAddress(userId);
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[userId] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(uint userId, uint amount) internal {
        address account = IRDNRegistry(registry).getUserAddress(userId);
        require(account != address(0), "ERC20: burn from zero address");

        uint accountBalance = _balances[userId];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[userId] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }
}