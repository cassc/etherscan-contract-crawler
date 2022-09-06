// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

import "./interfaces/dydx/DydxFlashloanBase.sol";
import "./interfaces/dydx/ICallee.sol";
import "./interfaces/IWETH.sol";

contract BuyerV2 is ICallee, DydxFlashloanBase {
    address public constant SEAPORT =
        0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address public constant OPENSEA_CONDUIT =
        0x1E0049783F008A0085193E00003D00cd54003c71;
    address private constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;
    IWETH weth;

    // JUST FOR TESTING - ITS OKAY TO REMOVE ALL OF THESE VARS
    address public seller;
    bytes openseaTransactionData;

    event Log(string message, uint256 val);

    struct MyCustomData {
        address token;
        uint256 repayAmount;
        uint256 amount;
    }

    constructor(IWETH weth_) {
        weth = weth_;
        weth.approve(OPENSEA_CONDUIT, 10e10 ether);
    }

    function initiateFlashLoan(
        address seller_,
        bytes calldata openseaTransactionData_,
        uint256 _amount
    ) external {
        ISoloMargin solo = ISoloMargin(SOLO);
        seller = seller_;
        openseaTransactionData = openseaTransactionData_;

        // Get marketId from token address
        /*
    0	WETH
    1	SAI
    2	USDC
    3	DAI
    */
        uint256 marketId = _getMarketIdFromTokenAddress(SOLO, address(weth));

        // Calculate repay amount (_amount + (2 wei))
        uint256 repayAmount = _getRepaymentAmountInternal(_amount);
        weth.approve(SOLO, repayAmount);

        /*
    1. Withdraw
    2. Call callFunction()
    3. Deposit back
    */

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);

        operations[0] = _getWithdrawAction(marketId, _amount);
        operations[1] = _getCallAction(
            abi.encode(
                MyCustomData({
                    token: address(weth),
                    repayAmount: repayAmount,
                    amount: _amount
                })
            )
        );
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);
    }

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public override {
        require(msg.sender == SOLO, "!solo");
        require(sender == address(this), "!this contract");

        MyCustomData memory mcd = abi.decode(data, (MyCustomData));
        uint256 repayAmount = mcd.repayAmount;
        uint256 amount = mcd.amount;

        uint256 openseaFees = (amount * 250) / 10000;
        uint256 bal = IERC20(mcd.token).balanceOf(address(this));
        require(bal + openseaFees >= repayAmount, "bal < repay");

        // More code here...
        (bool success, ) = SEAPORT.call(openseaTransactionData);
        require(success, "opensea transaction failed");

        // after buying the nft from opensea get the amount from the seller using pre approved manner
        weth.transferFrom(seller, address(this), amount - openseaFees);
    }
}