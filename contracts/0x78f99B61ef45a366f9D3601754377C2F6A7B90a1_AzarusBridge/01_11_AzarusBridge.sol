// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract AzarusBridge is Pausable, AccessControl {
    IERC20 public azarusToken;
    bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
    address public azarusBridgeSafe;

    // declare an event
    event Deposit(
        address indexed _from,
        address indexed _to,
        uint256 _value,
        address indexed _safe
    );

    constructor(address token, address safe) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        azarusToken = IERC20(token);
        azarusBridgeSafe = safe;
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function deposit(address to, uint256 amount) public whenNotPaused {
        // amount should be > 0
        require(amount > 0, 'amount should be > 0');
        // transfer AZA to this contract for staking
        azarusToken.transferFrom(msg.sender, azarusBridgeSafe, amount);
        // emit an event
        emit Deposit(msg.sender, to, amount, azarusBridgeSafe);
    }
}