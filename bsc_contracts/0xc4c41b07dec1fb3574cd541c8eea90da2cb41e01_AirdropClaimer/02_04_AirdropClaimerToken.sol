// SPDX-License-Identifier: WISE

import "./Events.sol";

pragma solidity ^0.8.17;

contract AirdropClaimerToken is Events {

    string _name;
    string _symbol;

    uint8 _decimals;
    uint256 _totalSupply;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address constant ZERO_ADDRESS = address(0);

    function name()
        external
        view
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        external
        view
        returns (string memory)
    {
        return _symbol;
    }

    function decimals()
        external
        view
        returns (uint8)
    {
        return _decimals;
    }

    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(
        address _account
    )
        external
        view
        returns (uint256)
    {
        return _balances[_account];
    }

    function transfer(
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool)
    {
        _transfer(
            msg.sender,
            _recipient,
            _amount
        );

        return true;
    }

    function allowance(
        address _owner,
        address _spender
    )
        external
        view
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    function approve(
        address _spender,
        uint256 _amount
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _amount
        );

        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        external
        returns (bool)
    {
        if (_allowances[_sender][msg.sender] != type(uint256).max) {
            _allowances[_sender][msg.sender] -= _amount;
        }

        _transfer(
            _sender,
            _recipient,
            _amount
        );

        return true;
    }

    /**
     * @dev Updates balances during transfer
     */
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    )
        internal
    {
        _balances[_sender] =
        _balances[_sender] - _amount;

        unchecked {
            _balances[_recipient] =
            _balances[_recipient] + _amount;
        }

        emit Transfer(
            _sender,
            _recipient,
            _amount
        );
    }

    function _mint(
        address _user,
        uint256 _amount
    )
        internal
    {
        _totalSupply =
        _totalSupply + _amount;

        unchecked {
            _balances[_user] =
            _balances[_user] + _amount;
        }

        emit Transfer(
            ZERO_ADDRESS,
            _user,
            _amount
        );
    }

    function _burn(
        address _account,
        uint256 _amount
    )
        internal
    {
        _balances[_account] =
        _balances[_account] - _amount;

        unchecked {
            _totalSupply =
            _totalSupply - _amount;
        }

        emit Transfer(
            _account,
            ZERO_ADDRESS,
            _amount
        );
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    )
        internal
    {
        _allowances[_owner][_spender] = _amount;

        emit Approval(
            _owner,
            _spender,
            _amount
        );
    }
}
