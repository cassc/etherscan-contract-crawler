// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

/// @title sdToken
/// @author StakeDAO
/// @notice A token that represents the Token deposited by a user into the Depositor
/// @dev Minting & Burning was modified to be used by the operator
contract sdToken is ERC20 {
    address public operator;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        operator = msg.sender;
    }

    /// @notice Set a new operator that can mint and burn sdToken
    /// @param _operator new operator address
    function setOperator(address _operator) external {
        require(msg.sender == operator, "!authorized");
        operator = _operator;
    }

    /// @notice mint new sdToken, callable only by the operator
    /// @param _to recipient to mint for
    /// @param _amount amount to mint
    function mint(address _to, uint256 _amount) external {
        require(msg.sender == operator, "!authorized");
        _mint(_to, _amount);
    }

    /// @notice burn sdToken, callable only by the operator
    /// @param _from sdToken holder
    /// @param _amount amount to burn
    function burn(address _from, uint256 _amount) external {
        require(msg.sender == operator, "!authorized");
        _burn(_from, _amount);
    }
}