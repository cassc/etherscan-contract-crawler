// test
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "contracts/libraries/Operator.sol";

contract Bond is ERC20Burnable, Operator {
    /**
     * @notice Constructs the Bond ERC-20 contract.
     */
    constructor(address _treasury) ERC20("Droplit Bond", "DBOND") {
    _transferOperator(_treasury);
    }

    /**
     * @notice Operator mints bonds to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of bonds to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public override onlyOperator {
        super.burnFrom(account, amount);
    }
}