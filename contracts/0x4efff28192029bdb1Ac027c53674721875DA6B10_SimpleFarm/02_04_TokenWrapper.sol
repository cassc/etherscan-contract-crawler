// SPDX-License-Identifier: -- BCOM --

pragma solidity =0.8.19;

import "./SafeERC20.sol";

contract TokenWrapper is SafeERC20 {

    string public constant name = "VerseFarm";
    string public constant symbol = "VFARM";

    uint8 public constant decimals = 18;

    uint256 _totalStaked;
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    address constant ZERO_ADDRESS = address(0x0);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns total amount of staked tokens
     */
    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalStaked;
    }

    /**
     * @dev Returns staked amount by wallet address
     */
    function balanceOf(
        address _walletAddress
    )
        external
        view
        returns (uint256)
    {
        return _balances[_walletAddress];
    }

    /**
     * @dev Increases staked amount by wallet address
     */
    function _stake(
        uint256 _amount,
        address _address
    )
        internal
    {
        _totalStaked =
        _totalStaked + _amount;

        unchecked {
            _balances[_address] =
            _balances[_address] + _amount;
        }

        emit Transfer(
            ZERO_ADDRESS,
            _address,
            _amount
        );
    }

    /**
     * @dev Decreases total staked amount
     */
    function _withdraw(
        uint256 _amount,
        address _address
    )
        internal
    {
        unchecked {
            _totalStaked =
            _totalStaked - _amount;
        }

        _balances[_address] =
        _balances[_address] - _amount;

        emit Transfer(
            _address,
            ZERO_ADDRESS,
            _amount
        );
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

    /**
     * @dev Grants permission for receipt tokens transfer on owner's behalf
     */
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

    /**
     * @dev Checks value for receipt tokens transfer on owner's behalf
     */
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

    /**
     * @dev Allowance update for receipt tokens transfer on owner's behalf
     */
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

    /**
     * @dev Increases value for receipt tokens transfer on owner's behalf
     */
    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _allowances[msg.sender][_spender] + _addedValue
        );

        return true;
    }

    /**
     * @dev Decreases value for receipt tokens transfer on owner's behalf
     */
    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    )
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            _spender,
            _allowances[msg.sender][_spender] - _subtractedValue
        );

        return true;
    }
}