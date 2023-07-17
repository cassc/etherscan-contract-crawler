// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../lib/Strings.sol';
import './ExternalStorable.sol';
import '../interfaces/storages/ITokenStorage.sol';
import '../interfaces/IERC20.sol';

contract Token is ExternalStorable, IERC20 {
    using Strings for string;
    
    bytes32 private constant TOTAL = 'Total';
    bytes32 private constant BALANCE = 'Balance';

    string internal _name;
    string internal _symbol;

    constructor(string memory __name,string memory __symbol,bytes32 contractName) {
        setContractName(contractName);
        _name = __name;
        _symbol = __symbol;
    }

    function Storage() internal view returns (ITokenStorage) {
        return ITokenStorage(getStorage());
    }

    function name() external override view returns (string memory) {
        return _name;
    }

    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override pure returns (uint8) {
        return 18;
    }

    function totalSupply() public override view returns (uint256) {
        return Storage().getUint(TOTAL, address(0));
    }

    function balanceOf(address account) public override view returns (uint256) {
        return Storage().getUint(BALANCE, account);
    }

    function allowance(address owner, address spender) external override view returns (uint256) {
        return Storage().getAllowance(owner, spender);
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 delta = Storage().getAllowance(sender, msg.sender) - amount;
        _approve(sender, msg.sender, delta);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        Storage().setAllowance(owner, spender, amount);
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        Storage().decrementUint(BALANCE, sender, amount);
        Storage().incrementUint(BALANCE, recipient, amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        Storage().incrementUint(BALANCE, account, amount);
        Storage().incrementUint(TOTAL, address(0), amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        Storage().decrementUint(BALANCE, account, amount);
        Storage().decrementUint(TOTAL, address(0), amount);
        emit Transfer(account, address(0), amount);
    }
}