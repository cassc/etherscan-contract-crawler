// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Emission.sol";
import "./PhutureERC20.sol";
import "./interfaces/IePHTR.sol";
import "./interfaces/IEmission.sol";

contract ePHTR is IePHTR, PhutureERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint constant INITIAL_QUANTITY = 10000;

    address private immutable token;
    uint private lastBalance;

    address public emission;

    constructor(address _token, uint _distributedPerBlock) {
        token = _token; 
        name = "Enhanced PHTR";
        symbol = "ePHTR";

        Emission _emission = new Emission(_token, address(this), _distributedPerBlock);
        _emission.transferOwnership(msg.sender);
        emission = address(_emission);  
    }   

    function withdrawableAmount(uint _value) external view override returns (uint) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            return 0;
        }
        uint balance = IERC20(token).balanceOf(address(this)) + IEmission(emission).withdrawable();
        return _value * balance / _totalSupply;
    }

    function mint(address _recipient) external override nonReentrant {
        uint balance = IERC20(token).balanceOf(address(this));
        IEmission(emission).withdraw();
        uint amount = balance - lastBalance;
        uint value;
        uint _totalSupply = totalSupply;
        if (_totalSupply != 0) {
            value = amount * _totalSupply / lastBalance;
        } else {
            value = amount - INITIAL_QUANTITY;
            _mint(address(0), INITIAL_QUANTITY);
        }
        require(value > 0, 'ePHTR: INSUFFICIENT_AMOUNT');
        _mint(_recipient, value);
        _update(IERC20(token).balanceOf(address(this)));
    }

    function burn(address _recipient) external override nonReentrant {
        IEmission(emission).withdraw();
        uint balance = IERC20(token).balanceOf(address(this));
        uint value = balanceOf[address(this)];
        uint amount = value * balance / totalSupply;
        require(amount > 0, 'ePHTR: INSUFFICIENT_VALUE_BURNED');
        IERC20(token).safeTransfer(_recipient, amount);
        _burn(address(this), value);
        _update(IERC20(token).balanceOf(address(this)));
    }

    function sync() external override nonReentrant {
        _update(IERC20(token).balanceOf(address(this)));
    }

    function _update(uint _newBalance) private {
        lastBalance = _newBalance;
    }
}