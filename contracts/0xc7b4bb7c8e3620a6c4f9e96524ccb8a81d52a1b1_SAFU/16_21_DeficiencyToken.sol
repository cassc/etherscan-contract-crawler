// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import {IERC20} from "IERC20.sol";
import {SafeMath} from "SafeMath.sol";
import {SafeERC20} from "SafeERC20.sol";

import {ERC20} from "UpgradeableERC20.sol";
import {ILoanToken2} from "ILoanToken2.sol";
import {IDeficiencyToken} from "IDeficiencyToken.sol";

/**
 *
 */
contract DeficiencyToken is IDeficiencyToken, ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ILoanToken2 public override loan;

    /**
     * @dev Create Deficiency
     * @param _loan Defaulted loans address
     * @param _amount Amount of underlying pool token's that are owed to the pool
     */
    constructor(ILoanToken2 _loan, uint256 _amount) public {
        ERC20.__ERC20_initialize("TrueFi Deficiency Token", "DEF");

        loan = _loan;
        _mint(address(_loan.pool()), _amount);
    }

    function burnFrom(address account, uint256 amount) external override {
        _approve(
            account,
            _msgSender(),
            allowance(account, _msgSender()).sub(amount, "DeficiencyToken: Burn amount exceeds allowance")
        );
        _burn(account, amount);
    }

    function version() external override pure returns (uint8) {
        return 0;
    }
}