// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "iface.sol";
import "SafeERC20.sol";
import "Initializable.sol";
import "OwnableUpgradeable.sol";
import "PausableUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";


contract RockXRedeem is IRockXRedeem, Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    mapping(address=>uint256) private balances;
    uint256 private totalBalance;

    /**
     * @dev initialization
     */
    function initialize() initializer public {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    // some convenient method to help show their claimable in wallet
    function name() external pure returns (string memory) { return "RockX Claimable ETH"; }
    function symbol() external pure returns (string memory) { return "redeemETH"; }
    function decimals() external pure returns (uint8) { return 18; }
    function totalSupply() external view returns (uint256) { return totalBalance; }
    function balanceOf(address account) external view returns(uint256) { return balances[account]; }

    function transfer(address to, uint256 amount) public nonReentrant returns (bool success) {
        // check
        require(balances[msg.sender] >= amount, "INSUFFICIENT_BALANCE");

        // modify
        balances[msg.sender] -= amount;
        totalBalance -= amount;
        payable(to).sendValue(amount);

        // log
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev pay debts from rockx staking contract
     */
    function pay(address account) external override payable {
        balances[account] += msg.value;
        totalBalance += msg.value;

        // log
        emit Paied(account, msg.value);
    }

    /**
     * @dev balance of claimable debts
     */
    event Paied(address account, uint256 amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}