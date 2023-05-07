// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract WillToken is ERC20, ERC20Burnable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    //Error message for when the maximum balance is reached
    error MAXIMUM_BALANCE_REACHED();

    //initial supply is 69 billion tokens
    uint256 public constant INITIAL_SUPPLY = 69_000_000_000 ether;

    //maximum holder balance is 1% of initial supply
    uint256 public constant MAX_HOLDER_BALANCE = INITIAL_SUPPLY / 100;

    //A list of addresses that are excluded from the maximum balance check
    EnumerableSet.AddressSet private _excludedFromMaxBalance;

    constructor(
        //The address that will receive the initial supply of tokens
        address initialSupplyReciever
    ) ERC20("WILL", "WILL") {
        //Grant the admin role to the deployer
        _setupRole(DEFAULT_ADMIN_ROLE, initialSupplyReciever);
        //Add the initial supply receiver to the list of addresses excluded from the maximum balance check
        _excludedFromMaxBalance.add(initialSupplyReciever);
        //Mint the initial supply to the initial supply receiver
        _mint(initialSupplyReciever, INITIAL_SUPPLY);
    }

    /**
     * @dev Returns the list of addresses that are excluded from the maximum balance check.
     */
    function getExcludedFromMaxBalance() public view returns(address[] memory excluded) {
        excluded = _excludedFromMaxBalance.values();
    }

    /**
     * @dev Set or unsets a list of addresses to be excluded from the maximum balance check.
     */
    function setExcludedFromMaxBalance(
        address[] calldata excludedFromMaxBalance,
        bool addOrRemove
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 len = excludedFromMaxBalance.length;
        for (uint256 i = 0; i < len; i++) {
            if (addOrRemove) {
                _excludedFromMaxBalance.add(excludedFromMaxBalance[i]);
            } else {
                _excludedFromMaxBalance.remove(excludedFromMaxBalance[i]);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        //Check if the maximum balance will be exceeded after sending the amount
        if (to != address(0) && !_excludedFromMaxBalance.contains(to)) {
            _checkMaxBalance(to, amount);
        }
    }

    /**
     * @dev Checks if the maximum balance will be exceeded after receiving the amount.
     */
    function _checkMaxBalance(address to, uint256 amount) internal view {
        if (balanceOf(to) + amount > MAX_HOLDER_BALANCE) {
            revert MAXIMUM_BALANCE_REACHED();
        }
    }

}