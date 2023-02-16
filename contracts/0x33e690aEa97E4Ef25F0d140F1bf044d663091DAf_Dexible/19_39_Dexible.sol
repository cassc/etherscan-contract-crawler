//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./interfaces/IDexible.sol";
import "./baseContracts/DexibleView.sol";
import "./baseContracts/SwapHandler.sol";
import "./baseContracts/ConfigBase.sol";

contract Dexible is DexibleView, ConfigBase, SwapHandler, IDexible {

    event ReceivedFunds(address from, uint amount);
    event WithdrewETH(address indexed admin, uint amount);

    /*
    constructor(DexibleStorage.DexibleConfig memory config) {
        configure(config);
    }
    */
    function initialize(DexibleStorage.DexibleConfig calldata config) public {
        configure(config);
    }

    receive() external payable {
       emit ReceivedFunds(msg.sender, msg.value);
    }

    function swap(SwapTypes.SwapRequest calldata request) external onlyRelay notPaused {
        //compute how much gas we have at the outset, plus some gas for loading contract, etc.
        uint startGas = gasleft();
        SwapMeta memory details = SwapMeta({
            feeIsInput: false,
            isSelfSwap: false,
            startGas: startGas,
            preSwapVault: address(DexibleStorage.load().communityVault),
            bpsAmount: 0,
            gasAmount: 0,
            nativeGasAmount: 0,
            toProtocol: 0,
            toRevshare: 0,
            outToTrader: 0,
            preDXBLBalance: 0,
            outAmount: 0,
            inputAmountDue: 0
        });

        bool success = false;
        //execute the swap but catch any problem
        try this.fill{
            gas: gasleft() - 80_000
        }(request, details) returns (SwapMeta memory sd) {
            details = sd;
            success = true;
        } catch {
            console.log("Swap failed");
            success = false;
        }

        postFill(request, details, success);
    }

    function selfSwap(SwapTypes.SelfSwap calldata request) external notPaused {
        //we create a swap request that has no affiliate attached and thus no
        //automatic discount.
        SwapTypes.SwapRequest memory swapReq = SwapTypes.SwapRequest({
            executionRequest: ExecutionTypes.ExecutionRequest({
                fee: ExecutionTypes.FeeDetails({
                    feeToken: request.feeToken,
                    affiliate: address(0),
                    affiliatePortion: 0
                }),
                requester: msg.sender
            }),
            tokenIn: request.tokenIn,
            tokenOut: request.tokenOut,
            routes: request.routes
        });
        SwapMeta memory details = SwapMeta({
            feeIsInput: false,
            isSelfSwap: true,
            startGas: 0,
            preSwapVault: address(DexibleStorage.load().communityVault),
            bpsAmount: 0,
            gasAmount: 0,
            nativeGasAmount: 0,
            toProtocol: 0,
            toRevshare: 0,
            outToTrader: 0,
            preDXBLBalance: 0,
            outAmount: 0,
            inputAmountDue: 0
        });
        details = this.fill(swapReq, details);
        postFill(swapReq, details, true);
    }

    function withdraw(uint amount) public onlyAdmin {
        address payable rec = payable(msg.sender);
        require(rec.send(amount), "Transfer failed");
        emit WithdrewETH(msg.sender, amount);
    }
}