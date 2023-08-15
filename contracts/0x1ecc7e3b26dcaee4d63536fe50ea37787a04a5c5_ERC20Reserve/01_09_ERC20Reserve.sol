// SPDX-License-Identifier: gpl-3.0

pragma solidity 0.7.5;

import './IReserve.sol';

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

/**
 * @title ERC20Reserve
 * @dev A simple holder of tokens
 * @author Ethichub
 */
contract ERC20Reserve is IReserve, AccessControl {
    bytes32 public constant TRANSFER_ROLE = keccak256('TRANSFER_ROLE');
    bytes32 public constant RESCUE_ROLE = keccak256('RESCUE_ROLE');

    using SafeERC20 for IERC20;
    IERC20 public token;

    constructor(IERC20 _token) {
        token = _token;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TRANSFER_ROLE, msg.sender);
        _setupRole(RESCUE_ROLE, msg.sender);
    }

    function balance() external view override returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transfer(address payable _to, uint256 _value) external override returns (bool) {
        require(hasRole(TRANSFER_ROLE, msg.sender), 'ERC20Reserve: Caller is not a transferrer');

        token.safeTransfer(_to, _value);

        emit Transfer(_to, _value);

        return true;
    }

    /**
    @dev WARNING: Thoroughly research the token to be rescued, it could be malicious code.
     */
    function rescueFunds(
        address _tokenToRescue,
        address _to,
        uint256 _amount
    ) external override {
        require(
            address(token) != _tokenToRescue,
            'ERC20Reserve: Cannot claim token held by the contract'
        );
        require(hasRole(RESCUE_ROLE, msg.sender), 'ERC20Reserve: Caller is not a rescuer');

        IERC20(_tokenToRescue).safeTransfer(_to, _amount);

        emit RescueFunds(_tokenToRescue, _to, _amount);
    }
}