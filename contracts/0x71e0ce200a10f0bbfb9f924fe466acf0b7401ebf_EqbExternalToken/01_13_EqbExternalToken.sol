// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./Interfaces/IEqbExternalToken.sol";

contract EqbExternalToken is
    IEqbExternalToken,
    ERC20Upgradeable,
    OwnableUpgradeable
{
    address public operator;

    // --- Events ---
    event OperatorUpdated(address _operator);

    modifier onlyOperator() {
        require(msg.sender == operator, "!auth");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _operator
    ) public initializer {
        __Ownable_init();

        __ERC20_init_unchained(_name, _symbol);

        operator = _operator;

        emit OperatorUpdated(_operator);
    }

    function mint(address _to, uint256 _amount) external override onlyOperator {
        _mint(_to, _amount);
    }
}