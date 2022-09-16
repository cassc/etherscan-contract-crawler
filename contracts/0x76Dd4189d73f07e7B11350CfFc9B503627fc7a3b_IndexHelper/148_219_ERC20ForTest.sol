// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20ForTest is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        address _initialAccount,
        uint256 _initialBalance
    ) ERC20(_name, _symbol) {
        _mint(_initialAccount, _initialBalance);
    }

    function mint(address _account, uint256 _amount) public {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public {
        _burn(_account, _amount);
    }

    function transferInternal(
        address _from,
        address _to,
        uint256 _value
    ) public {
        _transfer(_from, _to, _value);
    }

    function approveInternal(
        address _owner,
        address _spender,
        uint256 _value
    ) public {
        _approve(_owner, _spender, _value);
    }

    function deposit(uint256 _amount) external payable {
        // Function added for compatibility with WETH
    }
}