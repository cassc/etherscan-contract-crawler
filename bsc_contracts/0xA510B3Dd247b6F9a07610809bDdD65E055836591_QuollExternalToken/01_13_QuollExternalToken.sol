// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./Interfaces/IQuollExternalToken.sol";

contract QuollExternalToken is
    IQuollExternalToken,
    ERC20Upgradeable,
    OwnableUpgradeable
{
    address public operator;

    // --- Events ---
    event OperatorUpdated(address _operator);

    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        __Ownable_init();

        __ERC20_init_unchained(_name, _symbol);

        emit OperatorUpdated(msg.sender);
    }

    function setOperator(address _operator) external onlyOwner {
        require(operator == address(0), "already set!");
        operator = _operator;

        emit OperatorUpdated(_operator);
    }

    function mint(address _to, uint256 _amount) external override {
        require(msg.sender == operator, "!authorized");

        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external override {
        require(msg.sender == operator, "!authorized");

        _burn(_from, _amount);
    }
}