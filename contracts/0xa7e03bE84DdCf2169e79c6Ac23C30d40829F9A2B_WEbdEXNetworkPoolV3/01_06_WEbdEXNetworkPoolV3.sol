//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IWEbdEXStrategiesV3 {
    function lpBurnFrom(address to, address coin, uint256 amount) external;
}

contract WEbdEXNetworkPoolV3 is Ownable {
    address public webDexPaymentsV3;

    mapping(address => mapping(address => LPToken)) internal balances;

    struct LPToken {
        address coin;
        uint256 balance;
    }

    event Withdraw(
        address indexed wallet,
        address indexed coin,
        address indexed webDexStrategiesV3,
        uint256 amount
    );

    constructor(address webDexPaymentsV3_) {
        webDexPaymentsV3 = webDexPaymentsV3_;
    }

    modifier onlyWebDexPayments() {
        require(msg.sender == webDexPaymentsV3, "You must the WebDexPayments");

        _;
    }

    function addBalance(
        address to,
        address coin,
        uint256 amount,
        address lpToken
    ) external onlyWebDexPayments {
        uint256 currentBalance = balances[to][lpToken].balance;
        balances[to][lpToken] = LPToken(coin, currentBalance + amount);
    }

    function withdraw(
        address lpToken,
        uint256 amount,
        IWEbdEXStrategiesV3 webDexStrategiesV3
    ) public {
        require(
            amount <= balances[msg.sender][lpToken].balance,
            "The amount must be less than or equal to the balance"
        );

        webDexStrategiesV3.lpBurnFrom(
            msg.sender,
            balances[msg.sender][lpToken].coin,
            amount
        );
        ERC20(balances[msg.sender][lpToken].coin).transfer(msg.sender, amount);

        uint256 currentBalance = balances[msg.sender][lpToken].balance;
        balances[msg.sender][lpToken] = LPToken(
            balances[msg.sender][lpToken].coin,
            currentBalance - amount
        );

        emit Withdraw(
            msg.sender,
            balances[msg.sender][lpToken].coin,
            address(webDexStrategiesV3),
            amount
        );
    }

    function getBalance(address lpToken) public view returns (uint256) {
        return _getBalance(msg.sender, lpToken);
    }

    function getBalanceByWallet(
        address to,
        address lpToken
    ) public view onlyOwner returns (uint256) {
        return _getBalance(to, lpToken);
    }

    function _getBalance(
        address to,
        address lpToken
    ) internal view returns (uint256) {
        return balances[to][lpToken].balance;
    }
}