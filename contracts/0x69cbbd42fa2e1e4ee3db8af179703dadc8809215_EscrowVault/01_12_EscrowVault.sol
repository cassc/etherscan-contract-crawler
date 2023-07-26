pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

/*
An escrow vault for repayments 
*/

// Contracts
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

// Interfaces
import "./interfaces/IEscrowVault.sol";

contract EscrowVault is Initializable, ContextUpgradeable, IEscrowVault {
    using SafeERC20 for ERC20;

    //account => token => balance
    mapping(address => mapping(address => uint256)) public balances;

    constructor() {}

    function initialize() external initializer {}

    /**
     * @notice Deposit tokens on behalf of another account
     * @param account The id for the loan to set.
     * @param token The address of the new active lender.
     */
    function deposit(address account, address token, uint256 amount)
        public
        override
    {
        uint256 balanceBefore = ERC20(token).balanceOf(address(this));
        ERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
        uint256 balanceAfter = ERC20(token).balanceOf(address(this));

        balances[account][token] += balanceAfter - balanceBefore; //used for fee-on-transfer tokens
    }

    function withdraw(address token, uint256 amount) external {
        address account = _msgSender();

        balances[account][token] -= amount;
        ERC20(token).safeTransfer(account, amount);
    }
}