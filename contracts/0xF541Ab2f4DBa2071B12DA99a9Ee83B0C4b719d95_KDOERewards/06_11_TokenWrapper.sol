// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IgKDOE.sol";

contract TokenWrapper {
    uint256 public totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _gKDOEstakers;

    IERC20 public stakedToken;
    IGKDOE public gKDOE;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    string private constant _TransferErrorMessage = "staked token transfer failed";

    function stakeFor(address account, uint256 amount) internal{
        IERC20 st = stakedToken;
        if (st == IERC20(address(0))) {
            //eth
            unchecked {
                totalSupply += msg.value;
                _balances[account] += msg.value;
            }
        } else {
            require(msg.value == 0, "non-zero eth");
            require(amount > 0, "Cannot stake 0");
            require(
                st.transferFrom(msg.sender, address(this), amount),
                _TransferErrorMessage
            );
            unchecked {
                totalSupply += amount;
                _balances[account] += amount;
            }
        }
        emit Staked(account, amount);
    }

    function stakeForgKDOE(address account, uint256 amount) internal {
        require(amount > 0, "Cannot stake 0");

        require(
            gKDOE.depositForStaking(account, amount),
            _TransferErrorMessage
        );
		
        unchecked {
            totalSupply += amount;
            _balances[account] += amount;
            _gKDOEstakers[account] = true;
        }
		
        emit Staked(account, amount);
    }

    function withdrawForgKDOE(address account, uint256 amount) internal {
        require(_gKDOEstakers[account] == true, "Make have staked for gKDOE");
        require(amount <= _balances[account], "withdraw: balance is lower");

        require(
            gKDOE.withdrawFromStaking(account, uint256(amount)),
            "gKDOE not swapped back!"
        );

        unchecked {
            _balances[account] -= amount;
            totalSupply = totalSupply - amount;
        }

        require(
            stakedToken.transfer(account, amount),
            _TransferErrorMessage
        );
		
		if(_balances[account] == 0)
		{
		    _gKDOEstakers[account] == false;
		}
		
        emit Withdrawn(account, amount);
    }

    function withdraw(address account, uint256 amount) internal virtual {
        require(
            _gKDOEstakers[account] == false,
            "Cannot unstake when staked for gKDOE"
        );

        require(amount <= _balances[account], "withdraw: balance is lower");
        unchecked {
            _balances[account] -= amount;
            totalSupply = totalSupply - amount;
        }
        IERC20 st = stakedToken;
        if (st == IERC20(address(0))) {
            //eth
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "eth transfer failure");
        } else {
            require(
                stakedToken.transfer(msg.sender, amount),
                _TransferErrorMessage
            );
        }
        emit Withdrawn(msg.sender, amount);
    }
}