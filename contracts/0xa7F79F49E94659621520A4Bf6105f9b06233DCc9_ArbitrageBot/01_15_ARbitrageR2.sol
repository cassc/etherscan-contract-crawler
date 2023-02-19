// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IUniswapV2Router02.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

contract ArbitrageBot is FlashLoanSimpleReceiverBase, AccessControl {
    address[] path;

    address[3] Trade1;
    address[3] Trade2;
    address[3] Trade3;

    bytes32 public constant Executer_ROLE = keccak256("Executer_ROLE");
    bytes32 public constant Admin_ROLE = keccak256("Admin_ROLE");

    constructor(address _addressProvider)
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
    {
        _grantRole(
            DEFAULT_ADMIN_ROLE,
            0x5cB07F302F70D54c4C5e9E5FdE0BC480097Cc631
        );
        _grantRole(Executer_ROLE, 0x307750F53616563a84ea843D3E256997a3215441);
        _grantRole(Admin_ROLE, 0x5cB07F302F70D54c4C5e9E5FdE0BC480097Cc631);
    }

    function Checktrade(uint256 a, uint256 b) internal pure {
        require(a >= b, "Unable to Earn profit from the transaction");
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        uint256 AquiredToken = TradeFunction(Trade1, Trade2, Trade3, amount);
        Checktrade(AquiredToken, amount);
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);
        return true;
    }

    function TradeFlashloan(
        address asset,
        uint256 _amount,
        address[3] memory _trade1,
        address[3] memory _trade2,
        address[3] memory _trade3
    ) public onlyRole(Executer_ROLE) {
        address receiverAddress = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;
        Trade1 = _trade1;
        Trade2 = _trade2;
        Trade3 = _trade3;
        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            _amount,
            params,
            referralCode
        );
    }

    function TradeOwnCollateral(
        address[3] memory _trade1,
        address[3] memory _trade2,
        address[3] memory _trade3,
        uint256 amount
    ) public onlyRole(Executer_ROLE) {
        TradeFunction(_trade1, _trade2, _trade3, amount);
    }

    function TradeFunction(
        address[3] memory trade1,
        address[3] memory trade2,
        address[3] memory trade3,
        uint256 amount
    ) internal returns (uint256) {
        address WETH = IUniswapV2Router01(trade1[0]).WETH();
        if (trade3[0] == address(0)) {
            if (trade1[1] == WETH) {
                require(
                    amount > 0 && address(this).balance >= amount,
                    "insufficient funds for the transaction"
                );

                //trade1
                uint256 Blanance_before = IERC20(trade1[2]).balanceOf(
                    address(this)
                );
                swapETHtoToken(trade1[0], trade1[2], amount);
                uint256 Trade_AO = IERC20(trade1[2]).balanceOf(address(this)) -
                    Blanance_before;
                //trade2
                IERC20(trade2[1]).approve(
                    trade2[0],
                    IERC20(trade2[1]).balanceOf(address(this))
                );
                uint256 Blanance_before2 = address(this).balance;
                swapTokenToEth(trade2[0], trade2[1], Trade_AO);

                uint256 Trade_AO2 = address(this).balance - Blanance_before2;

                Checktrade(Trade_AO2, (amount));
                return Trade_AO2;
            } else if (trade1[2] == WETH) {
                require(
                    amount > 0 &&
                        IERC20(trade1[1]).balanceOf(address(this)) >= amount,
                    "insufficient funds for the transaction"
                );
                //trade1
                IERC20(trade1[1]).approve(
                    trade1[0],
                    IERC20(trade1[1]).balanceOf(address(this))
                );
                uint256 Balance_before = address(this).balance;
                swapTokenToEth(trade1[0], trade1[1], amount);
                uint256 Trade_AO = address(this).balance - Balance_before;

                //trade2
                uint256 Balance_before2 = IERC20(trade2[2]).balanceOf(
                    address(this)
                );
                swapETHtoToken(trade2[0], trade2[2], Trade_AO);
                uint256 Trade_AO2 = IERC20(trade2[2]).balanceOf(address(this)) -
                    Balance_before2;
                Checktrade(Trade_AO2, (amount));
                return Trade_AO2;
            } else {
                require(
                    amount > 0 &&
                        IERC20(trade1[1]).balanceOf(address(this)) >= amount,
                    "insufficient funds for the transaction"
                );
                //trade1
                IERC20(trade1[1]).approve(
                    trade1[0],
                    IERC20(trade1[1]).balanceOf(address(this))
                );
                uint256 Balance_before = IERC20(trade1[2]).balanceOf(
                    address(this)
                );
                swapTokenForToken(trade1[0], trade1[1], trade1[2], amount);
                uint256 Trade_AO = IERC20(trade1[2]).balanceOf(address(this)) -
                    Balance_before;
                //trade2
                IERC20(trade2[1]).approve(
                    trade2[0],
                    IERC20(trade2[1]).balanceOf(address(this))
                );
                uint256 Balance_before2 = IERC20(trade2[2]).balanceOf(
                    address(this)
                );
                swapTokenForToken(trade2[0], trade2[1], trade2[2], Trade_AO);
                uint256 Trade_AO2 = IERC20(trade2[2]).balanceOf(address(this)) -
                    Balance_before2;
                Checktrade(Trade_AO2, (amount));
                return Trade_AO2;
            }
        } else {
            if (trade1[1] == WETH && trade2[1] != WETH && trade3[1] != WETH) {
                require(
                    amount > 0 && address(this).balance >= amount,
                    "insufficient funds for the transaction"
                );
                //trade1
                uint256 Balance_before = IERC20(trade1[2]).balanceOf(
                    address(this)
                );
                swapETHtoToken(trade1[0], trade1[2], amount);
                uint256 Trade_AO = IERC20(trade1[2]).balanceOf(address(this)) -
                    Balance_before;
                //trade2
                IERC20(trade2[1]).approve(
                    trade2[0],
                    IERC20(trade2[1]).balanceOf(address(this))
                );
                uint256 Balance_before2 = IERC20(trade2[2]).balanceOf(
                    address(this)
                );
                swapTokenForToken(trade2[0], trade2[1], trade2[2], Trade_AO);
                uint256 Trade_AO2 = IERC20(trade2[2]).balanceOf(address(this)) -
                    Balance_before2;

                //trade3
                IERC20(trade3[1]).approve(
                    trade3[0],
                    IERC20(trade3[1]).balanceOf(address(this))
                );
                uint256 Balance_before3 = address(this).balance;
                swapTokenToEth(trade3[0], trade3[1], Trade_AO2);
                uint256 Trade_AO3 = address(this).balance - Balance_before3;
                Checktrade(Trade_AO3, (amount));
                return Trade_AO3;
            } else if (
                trade1[1] != WETH && trade2[1] == WETH && trade3[1] != WETH
            ) {
                require(
                    amount > 0 &&
                        IERC20(trade1[1]).balanceOf(address(this)) >= amount,
                    "insufficient funds for the transaction"
                );
                //trade1
                IERC20(trade1[1]).approve(
                    trade1[0],
                    IERC20(trade1[1]).balanceOf(address(this))
                );
                uint256 Balance_before = address(this).balance;
                swapTokenToEth(trade1[0], trade1[1], amount);
                uint256 Trade_AO = address(this).balance - Balance_before;
                //trade2
                uint256 Balance_before2 = IERC20(trade2[2]).balanceOf(
                    address(this)
                );
                swapETHtoToken(trade2[0], trade2[2], Trade_AO);
                uint256 Trade_AO2 = IERC20(trade2[2]).balanceOf(address(this)) -
                    Balance_before2;
                //trade3
                IERC20(trade3[1]).approve(
                    trade3[0],
                    IERC20(trade3[1]).balanceOf(address(this))
                );
                uint256 Balance_before3 = IERC20(trade3[2]).balanceOf(
                    address(this)
                );
                swapTokenForToken(trade3[0], trade3[1], trade3[2], Trade_AO2);
                uint256 Trade_AO3 = IERC20(trade3[2]).balanceOf(address(this)) -
                    Balance_before3;
                Checktrade(Trade_AO3, (amount));
                return Trade_AO3;
            } else if (
                trade1[1] != WETH && trade2[1] != WETH && trade3[1] == WETH
            ) {
                require(
                    amount > 0 &&
                        IERC20(trade1[1]).balanceOf(address(this)) >= amount,
                    "insufficient funds for the transaction"
                );
                //trade1
                IERC20(trade1[1]).approve(
                    trade1[0],
                    IERC20(trade1[1]).balanceOf(address(this))
                );
                uint256 Balance_before = IERC20(trade1[2]).balanceOf(
                    address(this)
                );
                swapTokenForToken(trade1[0], trade1[1], trade1[2], amount);
                uint256 Trade_AO = IERC20(trade1[2]).balanceOf(address(this)) -
                    Balance_before;
                //trade2
                IERC20(trade2[1]).approve(
                    trade2[0],
                    IERC20(trade2[1]).balanceOf(address(this))
                );
                uint256 Balance_before2 = address(this).balance;
                swapTokenToEth(trade2[0], trade2[1], Trade_AO);
                uint256 Trade_AO2 = address(this).balance - Balance_before2;
                //trade3
                uint256 Balance_before3 = IERC20(trade3[2]).balanceOf(
                    address(this)
                );
                swapETHtoToken(trade3[0], trade3[2], Trade_AO2);
                uint256 Trade_AO3 = IERC20(trade3[2]).balanceOf(address(this)) -
                    Balance_before3;
                Checktrade(Trade_AO3, (amount));
                return Trade_AO3;
            } else {
                require(
                    amount > 0 &&
                        IERC20(trade1[1]).balanceOf(address(this)) >= amount,
                    "insufficient funds for the transaction"
                );
                //trade1
                IERC20(trade1[1]).approve(
                    trade1[0],
                    IERC20(trade1[1]).balanceOf(address(this))
                );
                uint256 Balance_before = IERC20(trade1[2]).balanceOf(
                    address(this)
                );
                swapTokenForToken(trade1[0], trade1[1], trade1[2], amount);
                uint256 Trade_AO = IERC20(trade1[2]).balanceOf(address(this)) -
                    Balance_before;
                //trade2
                IERC20(trade2[1]).approve(
                    trade2[0],
                    IERC20(trade2[1]).balanceOf(address(this))
                );
                uint256 Balance_before2 = IERC20(trade2[2]).balanceOf(
                    address(this)
                );
                swapTokenForToken(trade2[0], trade2[1], trade2[2], Trade_AO);
                uint256 Trade_AO2 = IERC20(trade2[2]).balanceOf(address(this)) -
                    Balance_before2;
                //trade3
                IERC20(trade3[1]).approve(
                    trade3[0],
                    IERC20(trade3[1]).balanceOf(address(this))
                );
                uint256 Balance_before3 = IERC20(trade3[2]).balanceOf(
                    address(this)
                );
                swapTokenForToken(trade3[0], trade3[1], trade3[2], Trade_AO2);
                uint256 Trade_AO3 = IERC20(trade3[2]).balanceOf(address(this)) -
                    Balance_before3;
                Checktrade(Trade_AO3, (amount));
                return Trade_AO3;
            }
        }
    }

    function swapTokenForToken(
        address router,
        address tokenA,
        address tokenB,
        uint256 amount
    ) internal {
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        IUniswapV2Router02(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp + 300 seconds
            );
    }

    function swapETHtoToken(
        address router,
        address token,
        uint256 amount
    ) internal {
        path = new address[](2);
        path[0] = IUniswapV2Router01(router).WETH();
        path[1] = token;

        IUniswapV2Router02(router)
            .swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp + 300 seconds
        );
    }

    function swapTokenToEth(
        address router,
        address token,
        uint256 amount
    ) internal {
        path = new address[](2);
        path[0] = token;
        path[1] = IUniswapV2Router01(router).WETH();

        IUniswapV2Router02(router)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp + 300 seconds
            );
    }

    function WithdrawTokens(address _tokenAddress, uint256 amount)
        external
        onlyRole(Admin_ROLE)
    {
        IERC20(_tokenAddress).transfer(msg.sender, amount);
    }

    function WithdrawContractFunds(uint256 amount)
        external
        onlyRole(Admin_ROLE)
    {
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}
}