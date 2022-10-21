// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./Controllable.sol";

contract Mintable is ERC20Upgradeable, Controllable {
    event Mint(
        address indexed minter,
        address indexed to,
        uint256 indexed amount
    );

    /**
     * @dev Allow the Governance role to mint tokens for a account
     */
    function mint(address receiver, uint256 amount)
        external
        virtual
        onlyGovernance
        returns (bool)
    {
        _mint(receiver, amount);
        emit Mint(_msgSender(), receiver, amount);
        return true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}