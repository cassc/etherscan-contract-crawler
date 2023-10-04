//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IWEbdEXStrategiesV3 {
    function erc20Transf(
        address coin,
        address to,
        uint256 amount
    ) external returns (bool);

    function lpMint(
        address to,
        address coin,
        uint256 amount
    ) external returns (address);

    function lpBurnFrom(address to, address coin, uint256 amount) external;

    function updateCoinBalanceAndGasBalance(
        address to,
        address strategyToken,
        address coin,
        int256 amount,
        int256 gas
    ) external;
}

interface IWEbdEXNetworkPoolV3 {
    function addBalance(
        address to,
        address coin,
        uint256 amount,
        address lpToken
    ) external;
}

contract WEbdEXPaymentsV3 is Ownable {
    struct PayFees {
        address wallet;
        address af1;
        address af2;
        address af3;
        address af4;
        address af5;
        address af6;
        uint256 amountAf1;
        uint256 amountAf2;
        uint256 amountAf3;
        uint256 amountAf4;
        uint256 amountAf5;
        uint256 amountAf6;
        uint256 amountBot;
        uint256 amountSeller;
        address coin;
    }

    event PayFee(address indexed wallet, address indexed coin, uint256 amount);

    event OpenPosition(
        address indexed wallet,
        address indexed coin,
        address indexed strategyToken,
        string output,
        int256 profit,
        int256 gas,
        string[] coins,
        uint256 timeStamp
    );

    function openPosition(
        address strategyToken,
        address to,
        int256 amount,
        string[] memory coins,
        int256 gas,
        address coin,
        IWEbdEXStrategiesV3 webDexStrategiesV3
    ) public onlyOwner {
        bool isMint = amount > 0;

        if (isMint) {
            webDexStrategiesV3.lpMint(to, coin, uint256(amount));
        } else {
            webDexStrategiesV3.lpBurnFrom(to, coin, uint256(-1 * amount));
        }

        webDexStrategiesV3.updateCoinBalanceAndGasBalance(
            to,
            strategyToken,
            coin,
            amount,
            gas
        );

        emit OpenPosition(
            to,
            coin,
            strategyToken,
            isMint ? "win" : "loss",
            amount,
            gas,
            coins,
            block.timestamp
        );
    }

    function payFees(
        PayFees[] memory payments,
        address botWallet,
        address botSeller,
        IWEbdEXStrategiesV3 webDexStrategiesV3,
        IWEbdEXNetworkPoolV3 webDexNetworkPoolV3
    ) public onlyOwner {
        for (uint256 i = 0; i < payments.length; i++) {
            _payFee(
                payments[i].coin,
                payments[i].amountAf1,
                payments[i].af1,
                webDexStrategiesV3,
                webDexNetworkPoolV3
            );
            _payFee(
                payments[i].coin,
                payments[i].amountAf2,
                payments[i].af2,
                webDexStrategiesV3,
                webDexNetworkPoolV3
            );
            _payFee(
                payments[i].coin,
                payments[i].amountAf3,
                payments[i].af3,
                webDexStrategiesV3,
                webDexNetworkPoolV3
            );
            _payFee(
                payments[i].coin,
                payments[i].amountAf4,
                payments[i].af4,
                webDexStrategiesV3,
                webDexNetworkPoolV3
            );
            _payFee(
                payments[i].coin,
                payments[i].amountAf5,
                payments[i].af5,
                webDexStrategiesV3,
                webDexNetworkPoolV3
            );
            _payFee(
                payments[i].coin,
                payments[i].amountAf6,
                payments[i].af6,
                webDexStrategiesV3,
                webDexNetworkPoolV3
            );
            _payFee(
                payments[i].coin,
                payments[i].amountBot,
                botWallet,
                webDexStrategiesV3,
                webDexNetworkPoolV3
            );
            _payFee(
                payments[i].coin,
                payments[i].amountSeller,
                botSeller,
                webDexStrategiesV3,
                webDexNetworkPoolV3
            );
        }
    }

    function _payFee(
        address coin,
        uint256 amount,
        address to,
        IWEbdEXStrategiesV3 webDexStrategiesV3,
        IWEbdEXNetworkPoolV3 webDexNetworkPoolV3
    ) internal {
        if (to != address(0) && amount > 0) {
            webDexStrategiesV3.erc20Transf(
                coin,
                address(webDexNetworkPoolV3),
                amount
            );
            address lpToken = webDexStrategiesV3.lpMint(to, coin, amount);
            webDexNetworkPoolV3.addBalance(to, coin, amount, lpToken);

            emit PayFee(to, coin, amount);
        }
    }
}